from fastapi import APIRouter, Depends, HTTPException, status
from loguru import logger
from app.auth.dependencies import get_current_user
from app.database import get_supabase

router = APIRouter(prefix="/auth", tags=["auth"])


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
