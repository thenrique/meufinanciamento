import sys
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from loguru import logger
from app.config import get_settings
from app.auth.router import router as auth_router
from app.finance.router import router as finance_router
from app.finance.subscription_router import router as subscription_router
from app.advisor.router import router as advisor_router
from app.payments.mercadopago import router as payment_router
from app.pdf.router import router as pdf_router
from app.middleware.subscription_check import subscription_middleware


def _configure_logging() -> None:
    logger.remove()
    logger.add(
        sys.stdout,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{line}</cyan> - {message}",
        level="DEBUG",
        colorize=True,
    )


def _configure_sentry(dsn: str) -> None:
    try:
        import sentry_sdk
        from sentry_sdk.integrations.fastapi import FastApiIntegration
        from sentry_sdk.integrations.starlette import StarletteIntegration
        sentry_sdk.init(
            dsn=dsn,
            integrations=[StarletteIntegration(), FastApiIntegration()],
            traces_sample_rate=0.2,
        )
        logger.info("Sentry inicializado")
    except Exception as exc:
        logger.warning(f"Falha ao inicializar Sentry: {exc}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    _configure_logging()

    if settings.SENTRY_DSN:
        _configure_sentry(settings.SENTRY_DSN)

    from app.advisor.scheduler import start_scheduler, stop_scheduler
    start_scheduler()
    logger.info(f"Amortizador Pro iniciado — ambiente: {settings.ENVIRONMENT}")

    yield

    stop_scheduler()
    logger.info("Amortizador Pro encerrado")


settings = get_settings()

app = FastAPI(
    title="Amortizador Pro API",
    description="Backend do conselheiro financeiro de amortização de financiamentos imobiliários brasileiros.",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.ENVIRONMENT == "dev" else None,
    redoc_url="/redoc" if settings.ENVIRONMENT == "dev" else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.ENVIRONMENT == "dev" else ["https://amortizadorpro.com.br"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def subscription_check_middleware(request: Request, call_next):
    return await subscription_middleware(request, call_next)


@app.middleware("http")
async def logging_middleware(request: Request, call_next):
    logger.info(f"→ {request.method} {request.url.path}")
    response = await call_next(request)
    logger.info(f"← {response.status_code} {request.url.path}")
    return response


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Erro não tratado em {request.url.path}: {exc}")
    return JSONResponse(status_code=500, content={"detail": "Erro interno do servidor"})


@app.get("/health", tags=["infra"])
async def health_check() -> dict:
    """Verifica se o serviço está operacional."""
    return {"status": "ok", "service": "amortizador-pro-api"}


app.include_router(auth_router)
app.include_router(finance_router)
app.include_router(subscription_router)
app.include_router(advisor_router)
app.include_router(payment_router)
app.include_router(pdf_router)
