from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from loguru import logger
from app.auth.dependencies import get_current_user
from app.auth.models import SignupRequest, SignupResponse
from app.database import get_supabase
from app.analytics.events import log_event

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=SignupResponse, status_code=status.HTTP_201_CREATED)
async def signup(
    payload: SignupRequest,
) -> SignupResponse:
    """
    Cria uma nova conta de usuário com assinatura trial automática.

    Este endpoint:
    1. Cria a conta no Supabase Auth
    2. Cria o perfil do usuário na tabela 'profiles'
    3. Cria automaticamente uma assinatura trial de 7 dias

    Se a criação da assinatura falhar, a conta ainda é criada, mas a assinatura
    pode ser criada manualmente depois.

    Args:
        payload: Dados de signup (email, password, full_name)

    Returns:
        SignupResponse: ID do usuário, email, nome e data de expiração do trial

    Raises:
        400: Email já registrado ou dados inválidos
        500: Erro ao criar conta ou assinatura
    """
    supabase = get_supabase()

    try:
        # 1. Criar conta no Supabase Auth
        logger.info(f"Criando conta para email: {payload.email}")
        auth_response = supabase.auth.sign_up(
            {
                "email": payload.email,
                "password": payload.password,
            }
        )

        if not auth_response.user:
            logger.error(f"Falha ao criar usuário para {payload.email}: resposta vazia")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao criar conta",
            )

        user_id = auth_response.user.id
        logger.info(f"Usuário criado com sucesso: {user_id}")

        # 2. Criar perfil na tabela 'profiles'
        try:
            now_utc = datetime.now(timezone.utc)
            profile_data = {
                "id": user_id,
                "email": payload.email,
                "full_name": payload.full_name,
                "created_at": now_utc.isoformat(),
            }
            supabase.table("profiles").insert(profile_data).execute()
            logger.info(f"Perfil criado para usuário {user_id}")
        except Exception as exc:
            logger.warning(f"Erro ao criar perfil para {user_id}: {exc}")

        # 3. Criar assinatura trial automaticamente
        trial_created = False
        trial_expires_at = None
        try:
            now_utc = datetime.now(timezone.utc)
            trial_expires_at = now_utc + timedelta(days=7)

            subscription_data = {
                "user_id": user_id,
                "status": "active",
                "plan": "trial",
                "started_at": now_utc.isoformat(),
                "expires_at": trial_expires_at.isoformat(),
                "trial_extended": False,
            }
            resp = supabase.table("user_subscriptions").insert(subscription_data).execute()

            if resp.data:
                trial_created = True
                logger.info(
                    f"Assinatura trial criada para usuário {user_id}, expira em {trial_expires_at}"
                )
            else:
                logger.warning(f"Resposta vazia ao criar trial para {user_id}")
        except Exception as exc:
            logger.error(
                f"Erro ao criar assinatura trial para usuário {user_id}: {exc}. "
                f"Conta foi criada mas a assinatura pode precisar ser criada manualmente."
            )

        # Se não conseguiu criar a assinatura, tenta usar data padrão
        if not trial_expires_at:
            trial_expires_at = datetime.now(timezone.utc) + timedelta(days=7)

        # 4. Log do evento
        try:
            await log_event(
                supabase,
                user_id,
                "user_signup",
                {
                    "email": payload.email,
                    "trial_created": trial_created,
                    "trial_expires_at": trial_expires_at.isoformat(),
                },
            )
        except Exception as exc:
            logger.warning(f"Erro ao registrar evento de signup para {user_id}: {exc}")

        return SignupResponse(
            id=user_id,
            email=payload.email,
            full_name=payload.full_name,
            trial_expires_at=trial_expires_at.isoformat(),
        )

    except HTTPException:
        raise
    except Exception as exc:
        error_detail = str(exc).lower()

        # Tratamento específico para email já existente
        if "user already exists" in error_detail or "email" in error_detail:
            logger.warning(f"Tentativa de signup com email duplicado: {payload.email}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Este email já está registrado",
            )

        logger.error(f"Erro ao criar conta para {payload.email}: {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao criar conta",
        )


@router.get("/me")
async def get_me(user_id: str = Depends(get_current_user)) -> dict:
    """Retorna perfil do usuário autenticado."""
    supabase = get_supabase()
    try:
        response = supabase.table("profiles").select("*").eq("id", user_id).single().execute()
        if not response.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Perfil não encontrado")
        return response.data
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao buscar perfil do usuário {user_id}: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erro interno")
