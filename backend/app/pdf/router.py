from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from pydantic import BaseModel
from loguru import logger
from app.auth.dependencies import get_current_user
from app.database import get_supabase
from app.finance.engine import CaixaModel
from app.pdf.generator import generate_report_pdf
from app.analytics.events import log_event

router = APIRouter(prefix="/pdf", tags=["pdf"])


class ReportRequest(BaseModel):
    loan_id: str
    extra_monthly: float = 0.0
    extra_one_time: float = 0.0


@router.post("/report")
async def generate_report(
    payload: ReportRequest,
    user_id: str = Depends(get_current_user),
) -> Response:
    """
    Gera relatório PDF de amortização. Exclusivo para usuários premium.
    Retorna o PDF como download direto.
    """
    supabase = get_supabase()
    try:
        profile_resp = (
            supabase.table("profiles")
            .select("is_premium, full_name, email")
            .eq("id", user_id)
            .single()
            .execute()
        )
        if not profile_resp.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Perfil não encontrado")

        profile = profile_resp.data
        if not profile.get("is_premium"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Recurso exclusivo para usuários premium. Acesse /payment/create para assinar.",
            )

        loan_resp = (
            supabase.table("loans")
            .select("*")
            .eq("id", payload.loan_id)
            .eq("user_id", user_id)
            .single()
            .execute()
        )
        if not loan_resp.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Financiamento não encontrado")

        loan = loan_resp.data
        model = CaixaModel()
        simulation_result = await model.compare_scenarios(
            balance=loan["outstanding_balance"],
            annual_rate=loan["interest_rate_year"],
            months=loan["term_months"],
            insurance_monthly=loan.get("insurance_monthly", 0.0),
            extra_monthly=payload.extra_monthly,
            extra_one_time=payload.extra_one_time,
        )

        user_name = profile.get("full_name") or profile.get("email", "Cliente")
        pdf_bytes = generate_report_pdf(user_name, loan, simulation_result)

        await log_event(supabase, user_id, "pdf_downloaded", {"loan_id": payload.loan_id})

        filename = f"relatorio_amortizacao_{loan.get('name', 'financiamento').replace(' ', '_')}.pdf"
        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={"Content-Disposition": f'attachment; filename="{filename}"'},
        )

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao gerar PDF para {user_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro ao gerar relatório")
