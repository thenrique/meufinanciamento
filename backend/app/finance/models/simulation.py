"""Simulation and comparison models for "Estimado x Realizado" feature."""
from datetime import date as dateType, datetime, timezone
from typing import List, Optional
from pydantic import BaseModel, Field
from .payment import PaymentRecord


class CalculatedMonthEntry(BaseModel):
    """
    Entrada de mês calculado para simulação de amortização.

    Fields:
        month: Número do mês na amortização (começando em 1)
        date: Data do mês (primeiro dia)
        payment_planned: Valor da parcela planejada em R$
        amortization: Amortização (redução do saldo devedor) em R$
        interest: Juros do período em R$
        insurance: Seguro mensal em R$
        outstanding_balance: Saldo devedor após este mês em R$
    """

    month: int = Field(..., ge=1, description="Número do mês (começando em 1)")
    date: dateType = Field(..., description="Data do mês (primeiro dia)")
    payment_planned: float = Field(
        ..., ge=0, description="Valor da parcela planejada em R$"
    )
    amortization: float = Field(..., ge=0, description="Amortização em R$")
    interest: float = Field(..., ge=0, description="Juros do período em R$")
    insurance: float = Field(..., ge=0, description="Seguro mensal em R$")
    outstanding_balance: float = Field(
        ..., ge=0, description="Saldo devedor após este mês em R$"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "month": 1,
                "date": "2024-01-01",
                "payment_planned": 1500.50,
                "amortization": 1000.00,
                "interest": 500.50,
                "insurance": 0.00,
                "outstanding_balance": 49000.00,
            }
        }


class ActualMonthEntry(CalculatedMonthEntry):
    """
    Entrada de mês com dados reais comparado com planejado.

    Estende CalculatedMonthEntry com campos de valores reais e comparação:
        payment_actual: Valor do pagamento realizado em R$
        payments: Lista de registros de pagamentos realizados neste mês
        deviation: Desvio entre planejado e realizado em R$
    """

    payment_actual: Optional[float] = Field(
        None, ge=0, description="Valor do pagamento realizado em R$"
    )
    payments: List[PaymentRecord] = Field(
        default_factory=list, description="Lista de pagamentos realizados neste mês"
    )
    deviation: Optional[float] = Field(
        None, description="Desvio entre planejado e realizado em R$"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "month": 1,
                "date": "2024-01-01",
                "payment_planned": 1500.50,
                "payment_actual": 1650.00,
                "amortization": 1000.00,
                "interest": 500.50,
                "insurance": 0.00,
                "outstanding_balance": 49000.00,
                "payments": [
                    {
                        "id": "pay_123abc",
                        "loan_id": "loan_456def",
                        "payment_date": "2024-01-15",
                        "amount_paid": 1650.00,
                        "payment_type": "normal",
                        "notes": "Pagamento com aporte extra",
                        "created_at": "2024-01-15T10:30:00+00:00",
                    }
                ],
                "deviation": 149.50,
            }
        }


class ComparisonSummary(BaseModel):
    """
    Resumo comparativo entre cenário planejado e realizado.

    Fields:
        total_payment_planned: Total de pagamentos planejados em R$
        total_payment_actual: Total de pagamentos realizados em R$
        total_interest_planned: Total de juros planejados em R$
        total_interest_actual: Total de juros reais em R$
        total_interest_saved: Economia de juros (negativo = custo adicional)
        total_insurance: Total de seguro pago em R$
        months_planned: Quantidade de meses planejados
        months_actual: Quantidade de meses com pagamentos reais
        months_ahead: Meses à frente (negativo = atraso)
        payoff_date_planned: Data planejada de quitação
        payoff_date_actual: Data realizada de quitação
        days_ahead: Dias à frente da programação (negativo = atraso)
        total_deviation: Desvio total entre planejado e realizado em R$
    """

    total_payment_planned: float = Field(
        ..., description="Total de pagamentos planejados em R$"
    )
    total_payment_actual: float = Field(
        ..., description="Total de pagamentos realizados em R$"
    )
    total_interest_planned: float = Field(
        ..., description="Total de juros planejados em R$"
    )
    total_interest_actual: float = Field(..., description="Total de juros reais em R$")
    total_interest_saved: float = Field(
        ..., description="Economia de juros (negativo = custo adicional) em R$"
    )
    total_insurance: float = Field(..., description="Total de seguro pago em R$")
    months_planned: int = Field(..., ge=0, description="Quantidade de meses planejados")
    months_actual: int = Field(
        ..., ge=0, description="Quantidade de meses com pagamentos reais"
    )
    months_ahead: int = Field(
        ..., description="Meses à frente (negativo = atraso)"
    )
    payoff_date_planned: Optional[dateType] = Field(
        None, description="Data planejada de quitação"
    )
    payoff_date_actual: Optional[dateType] = Field(None, description="Data realizada de quitação")
    days_ahead: int = Field(
        ..., description="Dias à frente da programação (negativo = atraso)"
    )
    total_deviation: float = Field(
        ..., description="Desvio total entre planejado e realizado em R$"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "total_payment_planned": 180000.00,
                "total_payment_actual": 175000.00,
                "total_interest_planned": 50000.00,
                "total_interest_actual": 48000.00,
                "total_interest_saved": 2000.00,
                "total_insurance": 0.00,
                "months_planned": 120,
                "months_actual": 115,
                "months_ahead": 5,
                "payoff_date_planned": "2034-12-01",
                "payoff_date_actual": "2034-07-01",
                "days_ahead": 153,
                "total_deviation": 5000.00,
            }
        }


class LoanWithPaymentHistory(BaseModel):
    """
    Dados completos de um financiamento com histórico de pagamentos e comparações.

    Fields:
        loan_id: ID do financiamento
        loan_name: Nome/descrição do financiamento
        calculated_history: Histórico de meses calculados (planejado)
        actual_history: Histórico de meses reais com pagamentos
        summary: Resumo comparativo entre planejado e realizado
    """

    loan_id: str = Field(..., description="ID do financiamento")
    loan_name: str = Field(..., description="Nome/descrição do financiamento")
    calculated_history: List[CalculatedMonthEntry] = Field(
        ..., description="Histórico de meses calculados (planejado)"
    )
    actual_history: List[ActualMonthEntry] = Field(
        ..., description="Histórico de meses reais com pagamentos"
    )
    summary: ComparisonSummary = Field(
        ..., description="Resumo comparativo entre planejado e realizado"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "loan_id": "loan_456def",
                "loan_name": "Casa - Meu Financiamento",
                "calculated_history": [
                    {
                        "month": 1,
                        "date": "2024-01-01",
                        "payment_planned": 1500.50,
                        "amortization": 1000.00,
                        "interest": 500.50,
                        "insurance": 0.00,
                        "outstanding_balance": 49000.00,
                    }
                ],
                "actual_history": [
                    {
                        "month": 1,
                        "date": "2024-01-01",
                        "payment_planned": 1500.50,
                        "payment_actual": 1650.00,
                        "amortization": 1000.00,
                        "interest": 500.50,
                        "insurance": 0.00,
                        "outstanding_balance": 49000.00,
                        "payments": [],
                        "deviation": 149.50,
                    }
                ],
                "summary": {
                    "total_payment_planned": 180000.00,
                    "total_payment_actual": 175000.00,
                    "total_interest_planned": 50000.00,
                    "total_interest_actual": 48000.00,
                    "total_interest_saved": 2000.00,
                    "total_insurance": 0.00,
                    "months_planned": 120,
                    "months_actual": 115,
                    "months_ahead": 5,
                    "payoff_date_planned": "2034-12-01",
                    "payoff_date_actual": "2034-07-01",
                    "days_ahead": 153,
                    "total_deviation": 5000.00,
                },
            }
        }
