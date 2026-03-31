from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from loguru import logger
from app.database import get_supabase

bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> str:
    """Valida JWT do Supabase e retorna user_id."""
    token = credentials.credentials
    supabase = get_supabase()
    try:
        response = supabase.auth.get_user(token)
        if response is None or response.user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido ou expirado",
            )
        return response.user.id
    except HTTPException:
        raise
    except Exception as exc:
        logger.warning(f"Falha na autenticação: {exc}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Não autenticado",
        )
