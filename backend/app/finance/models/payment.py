"""Payment record models for loan amortization tracking."""
from datetime import date, datetime, timezone
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, field_validator


class PaymentType(str, Enum):
    """
    Tipos de pagamento para um financiamento.

    - normal: Pagamento mensal regular da parcela
    - extra_monthly: Aporte extra mensal para amortização acelerada
    - extra_one_time: Aporte extra pontual (uma única vez)
    - amortization: Pagamento de amortização adicional (reduz saldo devedor)
    """

    NORMAL = "normal"
    EXTRA_MONTHLY = "extra_monthly"
    EXTRA_ONE_TIME = "extra_one_time"
    AMORTIZATION = "amortization"


class PaymentRecord(BaseModel):
    """
    Registro de pagamento realizado em um financiamento.

    Fields:
        id: Identificador único do pagamento
        loan_id: ID do financiamento ao qual este pagamento se refere
        payment_date: Data do pagamento realizado
        amount_paid: Valor pago em R$
        payment_type: Tipo de pagamento (normal, extra_monthly, extra_one_time, amortization)
        notes: Anotações opcionais sobre o pagamento
        created_at: Data e hora de criação do registro em UTC
    """

    id: str = Field(..., description="Identificador único do pagamento")
    loan_id: str = Field(..., description="ID do financiamento")
    payment_date: date = Field(..., description="Data do pagamento realizado")
    amount_paid: float = Field(..., gt=0, description="Valor pago em R$")
    payment_type: PaymentType = Field(..., description="Tipo de pagamento")
    notes: Optional[str] = Field(None, description="Anotações opcionais")
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Data e hora de criação em UTC",
    )

    @field_validator("amount_paid")
    @classmethod
    def amount_must_be_positive(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("Valor do pagamento deve ser maior que zero")
        return v

    class Config:
        json_schema_extra = {
            "example": {
                "id": "pay_123abc",
                "loan_id": "loan_456def",
                "payment_date": "2024-01-15",
                "amount_paid": 1500.50,
                "payment_type": "normal",
                "notes": "Pagamento da parcela nº 12",
                "created_at": "2024-01-15T10:30:00+00:00",
            }
        }


class PaymentCreate(BaseModel):
    """
    Schema para criação de um novo registro de pagamento.

    Request fields (sem id e created_at que são gerados automaticamente):
        loan_id: ID do financiamento
        payment_date: Data do pagamento
        amount_paid: Valor pago em R$
        payment_type: Tipo de pagamento
        notes: Anotações opcionais
    """

    loan_id: str = Field(..., description="ID do financiamento")
    payment_date: date = Field(..., description="Data do pagamento realizado")
    amount_paid: float = Field(..., gt=0, description="Valor pago em R$")
    payment_type: PaymentType = Field(..., description="Tipo de pagamento")
    notes: Optional[str] = Field(None, description="Anotações opcionais")

    @field_validator("amount_paid")
    @classmethod
    def amount_must_be_positive(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("Valor do pagamento deve ser maior que zero")
        return v

    class Config:
        json_schema_extra = {
            "example": {
                "loan_id": "loan_456def",
                "payment_date": "2024-01-15",
                "amount_paid": 1500.50,
                "payment_type": "normal",
                "notes": "Pagamento da parcela nº 12",
            }
        }


class PaymentUpdate(BaseModel):
    """
    Schema para atualização de um registro de pagamento.

    Todos os campos são opcionais - apenas os fornecidos serão atualizados:
        payment_date: Data do pagamento
        amount_paid: Valor pago em R$
        payment_type: Tipo de pagamento
        notes: Anotações opcionais
    """

    payment_date: Optional[date] = Field(None, description="Data do pagamento realizado")
    amount_paid: Optional[float] = Field(None, gt=0, description="Valor pago em R$")
    payment_type: Optional[PaymentType] = Field(None, description="Tipo de pagamento")
    notes: Optional[str] = Field(None, description="Anotações opcionais")

    @field_validator("amount_paid")
    @classmethod
    def amount_must_be_positive(cls, v: Optional[float]) -> Optional[float]:
        if v is not None and v <= 0:
            raise ValueError("Valor do pagamento deve ser maior que zero")
        return v

    class Config:
        json_schema_extra = {
            "example": {
                "payment_date": "2024-01-15",
                "amount_paid": 1600.00,
                "notes": "Ajuste no valor do pagamento",
            }
        }
