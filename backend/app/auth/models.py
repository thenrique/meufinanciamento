"""Models for authentication endpoints."""

from pydantic import BaseModel, EmailStr, Field


class SignupRequest(BaseModel):
    """Modelo para requisição de signup.

    Fields:
        email: Email do usuário (deve ser único)
        password: Senha do usuário (mínimo 6 caracteres)
        full_name: Nome completo do usuário
    """

    email: EmailStr = Field(..., description="Email do usuário")
    password: str = Field(
        ...,
        min_length=6,
        description="Senha do usuário (mínimo 6 caracteres)",
    )
    full_name: str = Field(..., description="Nome completo do usuário")

    class Config:
        json_schema_extra = {
            "example": {
                "email": "usuario@example.com",
                "password": "senha123",
                "full_name": "João da Silva",
            }
        }


class SignupResponse(BaseModel):
    """Modelo para resposta de signup bem-sucedido.

    Fields:
        id: ID único do usuário
        email: Email do usuário registrado
        full_name: Nome completo do usuário
        trial_expires_at: Data de expiração da assinatura trial
    """

    id: str = Field(..., description="ID único do usuário")
    email: str = Field(..., description="Email do usuário registrado")
    full_name: str = Field(..., description="Nome completo do usuário")
    trial_expires_at: str = Field(
        ..., description="Data/hora de expiração da assinatura trial em UTC"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "email": "usuario@example.com",
                "full_name": "João da Silva",
                "trial_expires_at": "2024-01-08T10:00:00+00:00",
            }
        }
