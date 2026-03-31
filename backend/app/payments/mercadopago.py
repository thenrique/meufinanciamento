import hashlib
import hmac
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Request, status
from loguru import logger
from app.auth.dependencies import get_current_user
from app.database import get_supabase
from app.config import get_settings
from app.analytics.events import log_event

router = APIRouter(prefix="/payment", tags=["payments"])


async def _create_mp_preference(user_id: str, user_email: str) -> dict:
    """Cria preferência de pagamento no Mercado Pago."""
    import mercadopago
    settings = get_settings()
    sdk = mercadopago.SDK(settings.MP_ACCESS_TOKEN)

    preference_data = {
        "items": [
            {
                "id": "relatorio_premium",
                "title": "Relatório Premium Amortizador Pro",
                "description": "Acesso vitalício ao relatório PDF completo com análise de amortização",
                "quantity": 1,
                "currency_id": "BRL",
                "unit_price": 19.90,
            }
        ],
        "payer": {"email": user_email},
        "external_reference": user_id,
        "back_urls": {
            "success": "https://amortizadorpro.com.br/pagamento/sucesso",
            "failure": "https://amortizadorpro.com.br/pagamento/falha",
            "pending": "https://amortizadorpro.com.br/pagamento/pendente",
        },
        "auto_return": "approved",
        "notification_url": "https://api.amortizadorpro.com.br/payment/webhook",
        "statement_descriptor": "AMORTIZADORPRO",
    }

    result = sdk.preference().create(preference_data)
    if result["status"] != 201:
        raise RuntimeError(f"Erro ao criar preferência MP: {result}")

    return {
        "preference_id": result["response"]["id"],
        "init_point": result["response"]["init_point"],
        "sandbox_init_point": result["response"].get("sandbox_init_point"),
    }


def _validate_mp_signature(body: bytes, signature_header: str, secret: str) -> bool:
    """Valida assinatura HMAC-SHA256 do webhook do Mercado Pago."""
    try:
        mac = hmac.new(secret.encode("utf-8"), body, hashlib.sha256)
        expected = mac.hexdigest()
        return hmac.compare_digest(expected, signature_header)
    except Exception:
        return False


@router.post("/create")
async def create_payment(user_id: str = Depends(get_current_user)) -> dict:
    """Cria preferência de pagamento Mercado Pago e retorna URL de checkout."""
    supabase = get_supabase()
    try:
        profile_resp = supabase.table("profiles").select("email, is_premium").eq("id", user_id).single().execute()
        if not profile_resp.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Perfil não encontrado")

        profile = profile_resp.data
        if profile.get("is_premium"):
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Usuário já possui acesso premium")

        user_email = profile.get("email", "cliente@amortizadorpro.com.br")
        preference = await _create_mp_preference(user_id, user_email)

        supabase.table("transactions").insert({
            "user_id": user_id,
            "preference_id": preference["preference_id"],
            "amount": 19.90,
            "status": "pending",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }).execute()

        await log_event(supabase, user_id, "checkout_started", {"preference_id": preference["preference_id"]})
        return preference

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao criar pagamento para {user_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro ao criar pagamento")


@router.post("/webhook", status_code=status.HTTP_200_OK)
async def payment_webhook(request: Request) -> dict:
    """
    Recebe notificações do Mercado Pago.
    Valida assinatura e atualiza status da transação e perfil do usuário.
    """
    settings = get_settings()
    supabase = get_supabase()

    body = await request.body()
    signature = request.headers.get("x-signature", "")

    if settings.MP_WEBHOOK_SECRET and not _validate_mp_signature(body, signature, settings.MP_WEBHOOK_SECRET):
        logger.warning(f"Assinatura inválida no webhook MP: {signature[:20]}...")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Assinatura inválida")

    try:
        payload = await request.json()
        event_type = payload.get("type")
        logger.info(f"Webhook MP recebido: type={event_type}")

        if event_type != "payment":
            return {"status": "ignored"}

        import mercadopago
        sdk = mercadopago.SDK(settings.MP_ACCESS_TOKEN)
        payment_id = payload.get("data", {}).get("id")
        if not payment_id:
            return {"status": "ignored"}

        payment_info = sdk.payment().get(payment_id)
        if payment_info["status"] != 200:
            logger.warning(f"Falha ao buscar pagamento {payment_id} no MP")
            return {"status": "error"}

        payment = payment_info["response"]
        mp_status = payment.get("status")
        user_id = payment.get("external_reference")
        preference_id = payment.get("preference_id")

        logger.info(f"Pagamento {payment_id}: status={mp_status}, user={user_id}")

        supabase.table("transactions").update({
            "status": mp_status,
            "mp_payment_id": str(payment_id),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }).eq("preference_id", preference_id).execute()

        if mp_status == "approved" and user_id:
            supabase.table("profiles").update({
                "is_premium": True,
                "premium_since": datetime.now(timezone.utc).isoformat(),
            }).eq("id", user_id).execute()

            await log_event(supabase, user_id, "payment_confirmed", {
                "payment_id": str(payment_id),
                "amount": payment.get("transaction_amount"),
            })
            logger.info(f"Usuário {user_id} promovido a premium")

        return {"status": "processed"}

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao processar webhook MP: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro interno")
