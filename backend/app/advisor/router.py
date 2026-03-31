from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from loguru import logger
from app.auth.dependencies import get_current_user
from app.database import get_supabase
from app.finance.bcb_service import get_current_rates
from app.advisor.engine import (
    amortizar_vs_investir,
    alerta_tr,
    fgts_optimizer,
    prioridade_loans,
    meta_quitacao,
    Insight,
)
from app.advisor.dispatcher import dispatch_insights

router = APIRouter(prefix="/advisor", tags=["advisor"])


@router.get("/insights")
async def get_insights(user_id: str = Depends(get_current_user)) -> list:
    """
    Retorna insights do usuário: combina cache do scheduler com cálculo em tempo real.
    """
    supabase = get_supabase()
    try:
        now = datetime.now(timezone.utc)
        month_key = now.strftime("%Y-%m")

        cached_resp = (
            supabase.table("advisor_insights")
            .select("*")
            .eq("user_id", user_id)
            .eq("month_key", month_key)
            .eq("dismissed", False)
            .execute()
        )

        if cached_resp.data:
            return cached_resp.data

        loans_resp = supabase.table("loans").select("*").eq("user_id", user_id).execute()
        loans = loans_resp.data or []
        if not loans:
            return []

        rates = await get_current_rates()
        tr = rates["tr_mensal"]
        selic = rates["selic_anual"]

        insights: list[Insight] = []

        for loan in loans:
            try:
                insights.append(amortizar_vs_investir(loan, tr, selic))
            except Exception as exc:
                logger.warning(f"Erro em amortizar_vs_investir: {exc}")

        try:
            tr_historico_resp = (
                supabase.table("rates_cache")
                .select("value, updated_at")
                .eq("key", "TR")
                .order("updated_at", desc=True)
                .limit(4)
                .execute()
            )
            tr_historico = [float(r["value"]) for r in (tr_historico_resp.data or [])]
            tr_historico.reverse()
            for loan in loans:
                alert = alerta_tr(loan, tr_historico)
                if alert:
                    insights.append(alert)
        except Exception as exc:
            logger.warning(f"Erro em alerta_tr: {exc}")

        try:
            profile_resp = (
                supabase.table("profiles")
                .select("fgts_last_use, salario_estimado")
                .eq("id", user_id)
                .single()
                .execute()
            )
            if profile_resp.data:
                from datetime import date
                fgts_raw = profile_resp.data.get("fgts_last_use")
                fgts_date = date.fromisoformat(fgts_raw) if fgts_raw else None
                salario = float(profile_resp.data.get("salario_estimado") or 0)
                for loan in loans:
                    hint = fgts_optimizer(loan, fgts_date, salario)
                    if hint:
                        insights.append(hint)
        except Exception as exc:
            logger.warning(f"Erro em fgts_optimizer: {exc}")

        try:
            prio = prioridade_loans(loans)
            if prio:
                insights.append(prio)
        except Exception as exc:
            logger.warning(f"Erro em prioridade_loans: {exc}")

        cards = await dispatch_insights(insights, len(loans))
        return cards

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao calcular insights para {user_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro interno")


@router.post("/dismiss/{insight_id}", status_code=status.HTTP_204_NO_CONTENT)
async def dismiss_insight(
    insight_id: str,
    user_id: str = Depends(get_current_user),
) -> None:
    """Marca um insight como dispensado pelo usuário."""
    supabase = get_supabase()
    try:
        existing = (
            supabase.table("advisor_insights")
            .select("id")
            .eq("id", insight_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not existing.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Insight não encontrado")

        supabase.table("advisor_insights").update({"dismissed": True}).eq("id", insight_id).execute()
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao dispensar insight {insight_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro interno")
