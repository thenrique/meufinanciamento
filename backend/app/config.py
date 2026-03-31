from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    SUPABASE_URL: str
    SUPABASE_KEY: str
    SUPABASE_SERVICE_KEY: str
    OPENAI_API_KEY: str = ""
    MP_ACCESS_TOKEN: str
    MP_WEBHOOK_SECRET: str
    SENTRY_DSN: str = ""
    ENVIRONMENT: str = "dev"

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()
