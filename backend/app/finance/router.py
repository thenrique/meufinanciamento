from datetime import datetime, timezone, date
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from pydantic import BaseModel, field_validator
from loguru import logger
from app.auth.dependencies import get_current_user
from app.database import get_supabase
from app.finance.engine import CaixaModel, calculate_loan_with_history
from app.finance.bcb_service import get_current_rates
from app.finance.models.payment import PaymentCreate, PaymentUpdate, PaymentRecord, PaymentType
from app.finance.models.simulation import LoanWithPaymentHistory
from app.finance.validators.payment_validator import (
    validate_payment_date,
    validate_payment_amount,
    validate_unique_payment_date,
    validate_user_loan_ownership,
)
from app.analytics.events import log_event

router = APIRouter(tags=["finance"])


class LoanCreate(BaseModel):
    name: str
    total_amount: float
    outstanding_balance: float
    interest_rate_year: float
    term_months: int
    insurance_monthly: float = 0.0

    @field_validator("total_amount", "outstanding_balance", "insurance_monthly")
    @classmethod
    def must_be_positive(cls, v: float) -> float:
        if v < 0:
            raise ValueError("Valor não pode ser negativo")
        return v

    @field_validator("total_amount")
    @classmethod
    def total_amount_positive(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("Valor total deve ser maior que zero")
        return v

    @field_validator("interest_rate_year")
    @classmethod
    def validate_rate(cls, v: float) -> float:
        if not (0.1 <= v <= 30):
            raise ValueError("Taxa de juros deve estar entre 0,1% e 30% ao ano")
        return v

    @field_validator("term_months")
    @classmethod
    def validate_term(cls, v: int) -> int:
        if not (12 <= v <= 420):
            raise ValueError("Prazo deve estar entre 12 e 420 meses")
        return v

    def model_post_init(self, __context) -> None:
        if self.outstanding_balance > self.total_amount:
            raise ValueError("Saldo devedor não pode ser maior que o valor total")


class LoanUpdate(BaseModel):
    name: Optional[str] = None
    outstanding_balance: Optional[float] = None
    interest_rate_year: Optional[float] = None
    term_months: Optional[int] = None
    insurance_monthly: Optional[float] = None


class SimulationRequest(BaseModel):
    loan_id: str
    extra_monthly: float = 0.0
    extra_one_time: float = 0.0

    @field_validator("extra_monthly", "extra_one_time")
    @classmethod
    def must_not_be_negative(cls, v: float) -> float:
        if v < 0:
            raise ValueError("Aporte não pode ser negativo")
        return v


@router.get("/loans")
async def list_loans(user_id: str = Depends(get_current_user)) -> list:
    """Lista todos os financiamentos do usuário autenticado."""
    supabase = get_supabase()
    try:
        resp = supabase.table("loans").select("*").eq("user_id", user_id).execute()
        return resp.data or []
    except Exception as exc:
        logger.error(f"Erro ao listar loans do usuário {user_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro interno")


@router.post("/loans", status_code=status.HTTP_201_CREATED)
async def create_loan(
    payload: LoanCreate,
    user_id: str = Depends(get_current_user),
) -> dict:
    """Cria um novo financiamento."""
    supabase = get_supabase()
    try:
        data = payload.model_dump()
        data["user_id"] = user_id
        data["created_at"] = datetime.now(timezone.utc).isoformat()
        resp = supabase.table("loans").insert(data).execute()
        loan = resp.data[0]
        await log_event(supabase, user_id, "loan_created", {"loan_id": loan["id"]})
        return loan
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao criar loan para {user_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro interno")


@router.put("/loans/{loan_id}")
async def update_loan(
    loan_id: str,
    payload: LoanUpdate,
    user_id: str = Depends(get_current_user),
) -> dict:
    """Atualiza um financiamento existente."""
    supabase = get_supabase()
    try:
        existing = supabase.table("loans").select("id").eq("id", loan_id).eq("user_id", user_id).execute()
        if not existing.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Financiamento não encontrado")

        updates = {k: v for k, v in payload.model_dump().items() if v is not None}
        if not updates:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nenhum campo para atualizar")

        resp = supabase.table("loans").update(updates).eq("id", loan_id).execute()
        return resp.data[0]
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao atualizar loan {loan_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro interno")


@router.delete("/loans/{loan_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_loan(
    loan_id: str,
    user_id: str = Depends(get_current_user),
) -> None:
    """Remove um financiamento."""
    supabase = get_supabase()
    try:
        existing = supabase.table("loans").select("id").eq("id", loan_id).eq("user_id", user_id).execute()
        if not existing.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Financiamento não encontrado")
        supabase.table("loans").delete().eq("id", loan_id).execute()
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao remover loan {loan_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro interno")


@router.post("/simulate")
async def simulate(
    payload: SimulationRequest,
    user_id: str = Depends(get_current_user),
) -> dict:
    """
    Simula amortização com aportes extras e compara com o cenário atual.
    Salva resultado em simulations_history.
    """
    supabase = get_supabase()
    try:
        loan_resp = supabase.table("loans").select("*").eq("id", payload.loan_id).eq("user_id", user_id).single().execute()
        if not loan_resp.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Financiamento não encontrado")

        loan = loan_resp.data
        model = CaixaModel()
        result = await model.compare_scenarios(
            balance=loan["outstanding_balance"],
            annual_rate=loan["interest_rate_year"],
            months=loan["term_months"],
            insurance_monthly=loan.get("insurance_monthly", 0.0),
            extra_monthly=payload.extra_monthly,
            extra_one_time=payload.extra_one_time,
        )

        history = {
            "user_id": user_id,
            "loan_id": payload.loan_id,
            "extra_monthly": payload.extra_monthly,
            "extra_one_time": payload.extra_one_time,
            "resumo": result["resumo"],
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        supabase.table("simulations_history").insert(history).execute()
        await log_event(supabase, user_id, "simulation_run", {"loan_id": payload.loan_id})

        return result
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro na simulação para loan {payload.loan_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro interno")


@router.get("/rates/current")
async def current_rates() -> dict:
    """Retorna TR mensal e Selic anual atuais."""
    try:
        return await get_current_rates()
    except Exception as exc:
        logger.error(f"Erro ao buscar taxas atuais: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro ao buscar taxas")


@router.post("/loans/{loan_id}/payments", status_code=status.HTTP_201_CREATED)
async def create_payment(
    loan_id: str,
    payload: PaymentCreate,
    user_id: str = Depends(get_current_user),
) -> PaymentRecord:
    """Cria um novo pagamento para um financiamento."""
    supabase = get_supabase()
    try:
        loan = await validate_user_loan_ownership(user_id, loan_id, supabase)
        
        validate_payment_date(payload.payment_date, date.fromisoformat(loan.get("created_at", "2020-01-01")[:10]))
        validate_payment_amount(payload.amount_paid, loan["outstanding_balance"])
        
        existing_payments_resp = supabase.table("payments").select("*").eq("loan_id", loan_id).execute()
        existing_payments = [PaymentRecord(**p) for p in existing_payments_resp.data] if existing_payments_resp.data else []
        validate_unique_payment_date(loan_id, payload.payment_date, existing_payments)
        
        data = payload.model_dump()
        data["user_id"] = user_id
        data["created_at"] = datetime.now(timezone.utc).isoformat()
        
        resp = supabase.table("payments").insert(data).execute()
        payment = resp.data[0]
        
        logger.info(f"Pagamento criado: payment_id={payment['id']}, loan_id={loan_id}, user_id={user_id}")
        await log_event(supabase, user_id, "payment_created", {"payment_id": payment["id"], "loan_id": loan_id})
        
        return PaymentRecord(**payment)
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao criar pagamento para loan {loan_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro ao criar pagamento")


@router.get("/loans/{loan_id}/payments")
async def list_payments(
    loan_id: str,
    user_id: str = Depends(get_current_user),
    start_date: Optional[date] = Query(None, description="Data inicial de filtro (YYYY-MM-DD)"),
    end_date: Optional[date] = Query(None, description="Data final de filtro (YYYY-MM-DD)"),
) -> list[PaymentRecord]:
    """Lista todos os pagamentos de um financiamento do usuário autenticado."""
    supabase = get_supabase()
    try:
        await validate_user_loan_ownership(user_id, loan_id, supabase)
        
        resp = supabase.table("payments").select("*").eq("loan_id", loan_id).order("payment_date").execute()
        
        payments = [PaymentRecord(**p) for p in resp.data] if resp.data else []
        
        if start_date:
            payments = [p for p in payments if p.payment_date >= start_date]
        if end_date:
            payments = [p for p in payments if p.payment_date <= end_date]
        
        logger.info(f"Listados {len(payments)} pagamentos do financiamento {loan_id} para usuário {user_id}")
        return payments
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao listar pagamentos do loan {loan_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro ao listar pagamentos")


@router.put("/loans/{loan_id}/payments/{payment_id}")
async def update_payment(
    loan_id: str,
    payment_id: str,
    payload: PaymentUpdate,
    user_id: str = Depends(get_current_user),
) -> PaymentRecord:
    """Atualiza um pagamento existente."""
    supabase = get_supabase()
    try:
        loan = await validate_user_loan_ownership(user_id, loan_id, supabase)
        
        existing_resp = supabase.table("payments").select("*").eq("id", payment_id).eq("loan_id", loan_id).single().execute()
        if not existing_resp.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pagamento não encontrado")
        
        existing_payment = existing_resp.data
        
        updates = {k: v for k, v in payload.model_dump().items() if v is not None}
        if not updates:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nenhum campo para atualizar")
        
        if "payment_date" in updates:
            validate_payment_date(updates["payment_date"], date.fromisoformat(loan.get("created_at", "2020-01-01")[:10]))
            
            existing_payments_resp = supabase.table("payments").select("*").eq("loan_id", loan_id).execute()
            existing_payments = [PaymentRecord(**p) for p in existing_payments_resp.data] if existing_payments_resp.data else []
            existing_payments = [p for p in existing_payments if p.id != payment_id]
            validate_unique_payment_date(loan_id, updates["payment_date"], existing_payments)
        
        if "amount_paid" in updates:
            validate_payment_amount(updates["amount_paid"], loan["outstanding_balance"])
        
        resp = supabase.table("payments").update(updates).eq("id", payment_id).execute()
        payment = resp.data[0]
        
        logger.info(f"Pagamento atualizado: payment_id={payment_id}, loan_id={loan_id}, user_id={user_id}")
        await log_event(supabase, user_id, "payment_updated", {"payment_id": payment_id, "loan_id": loan_id})
        
        return PaymentRecord(**payment)
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao atualizar pagamento {payment_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro ao atualizar pagamento")


@router.delete("/loans/{loan_id}/payments/{payment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_payment(
    loan_id: str,
    payment_id: str,
    user_id: str = Depends(get_current_user),
) -> None:
    """Remove um pagamento registrado."""
    supabase = get_supabase()
    try:
        await validate_user_loan_ownership(user_id, loan_id, supabase)
        
        existing = supabase.table("payments").select("id").eq("id", payment_id).eq("loan_id", loan_id).execute()
        if not existing.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pagamento não encontrado")
        
        supabase.table("payments").delete().eq("id", payment_id).execute()
        
        logger.info(f"Pagamento deletado: payment_id={payment_id}, loan_id={loan_id}, user_id={user_id}")
        await log_event(supabase, user_id, "payment_deleted", {"payment_id": payment_id, "loan_id": loan_id})
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao remover pagamento {payment_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro ao remover pagamento")


@router.get("/loans/{loan_id}/history", response_model=LoanWithPaymentHistory)
async def get_loan_history(
    loan_id: str,
    user_id: str = Depends(get_current_user),
    include_future: bool = Query(False, description="Incluir meses futuros estimados"),
    group_by_month: bool = Query(False, description="Agrupar dados mensais"),
) -> LoanWithPaymentHistory:
    """
    Retorna o histórico completo do empréstimo com comparação estimado x realizado.
    
    Integra a função calculate_loan_with_history para gerar:
    - Cenário estimado (amortização contratada original)
    - Cenário realizado (com pagamentos aplicados)
    - Resumo comparativo (meses adiantados, juros economizados, etc)
    
    Query params:
    - include_future: incluir meses projetados futuros (padrão: false)
    - group_by_month: agregar dados mensais (padrão: false)
    """
    supabase = get_supabase()
    try:
        # Step 1: Verify user owns the loan
        loan_resp = supabase.table("loans").select("*").eq("id", loan_id).eq("user_id", user_id).single().execute()
        if not loan_resp.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Financiamento não encontrado")
        
        loan = loan_resp.data
        
        # Step 2: Fetch all payment records for this loan (sorted by date)
        payments_resp = supabase.table("payment_records").select("*").eq("loan_id", loan_id).order("payment_date").execute()
        payment_data = payments_resp.data or []
        
        # Convert payment data to PaymentRecord objects
        payment_records = []
        for p in payment_data:
            # Handle date parsing if it comes as string
            if isinstance(p.get("payment_date"), str):
                p["payment_date"] = date.fromisoformat(p["payment_date"])
            if isinstance(p.get("created_at"), str):
                # Parse ISO format datetime
                if "T" in p["created_at"]:
                    p["created_at"] = datetime.fromisoformat(p["created_at"])
                else:
                    p["created_at"] = datetime.combine(
                        date.fromisoformat(p["created_at"]),
                        datetime.min.time(),
                        tzinfo=timezone.utc
                    )
            payment_records.append(PaymentRecord(**p))
        
        logger.info(f"Fetched {len(payment_records)} payment records for loan {loan_id}")
        
        # Step 3: Call calculate_loan_with_history to get calculated, actual, and comparison
        result = await calculate_loan_with_history(loan, payment_records)
        
        # Step 4: Handle optional parameters
        if not include_future:
            # Filter to only include historical data (up to today)
            today = date.today()
            result.calculated_history = [m for m in result.calculated_history if m.date <= today]
            result.actual_history = [m for m in result.actual_history if m.date <= today]
        
        if group_by_month:
            # Data is already grouped by month in the calculation engine
            pass
        
        logger.info(f"Successfully generated history for loan {loan_id} with {len(result.actual_history)} months")
        await log_event(
            supabase, 
            user_id, 
            "loan_history_requested", 
            {"loan_id": loan_id, "months": len(result.actual_history)}
        )
        
        return result
        
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao buscar histórico do loan {loan_id}: {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail="Erro ao buscar histórico do empréstimo"
        )

