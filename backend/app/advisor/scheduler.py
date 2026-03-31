from datetime import datetime, timezone
from loguru import logger
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from app.database import get_supabase_admin
from app.finance.bcb_service import get_current_rates
from app.advisor.engine import (
    amortizar_vs_investir,
    alerta_tr,
    fgts_optimizer,
    prioridade_loans,
    meta_quitacao,
    Insight,
)

scheduler = AsyncIOScheduler(timezone="America/Sao_Paulo")


async def _calculate_and_persist_insights(user_id: str, loans: list, rates: dict) -> None:
    """Calcula todos os insights para um usuário e persiste no Supabase."""
    supabase = get_supabase_admin()
    tr = rates["tr_mensal"]
    selic = rates["selic_anual"]

    now = datetime.now(timezone.utc)
    month_key = now.strftime("%Y-%m")

    existing = (
        supabase.table("advisor_insights")
        .select("id")
        .eq("user_id", user_id)
        .eq("month_key", month_key)
        .execute()
    )
    if existing.data:
        logger.debug(f"Insights do mês {month_key} já existem para {user_id}, pulando")
        return

    insights: list[Insight] = []

    for loan in loans:
        try:
            insights.append(amortizar_vs_investir(loan, tr, selic))
        except Exception as exc:
            logger.warning(f"Erro em amortizar_vs_investir para loan {loan.get('id')}: {exc}")

    try:
        tr_historico_resp = (
            supabase.table("rates_cache")
            .select("value, updated_at")
            .eq("key", "TR")
            .order("updated_at", desc=True)
            .limit(4)
            .execute()
        )
        tr_historico = [float(r["value"]) for r in (tr_historico_resp.data or [])]
        tr_historico.reverse()

        for loan in loans:
            alert = alerta_tr(loan, tr_historico)
            if alert:
                insights.append(alert)
    except Exception as exc:
        logger.warning(f"Erro em alerta_tr para {user_id}: {exc}")

    try:
        profile_resp = (
            supabase.table("profiles")
            .select("fgts_last_use, salario_estimado")
            .eq("id", user_id)
            .single()
            .execute()
        )
        if profile_resp.data:
            from datetime import date
            fgts_raw = profile_resp.data.get("fgts_last_use")
            fgts_date = date.fromisoformat(fgts_raw) if fgts_raw else None
            salario = float(profile_resp.data.get("salario_estimado") or 0)
            for loan in loans:
                hint = fgts_optimizer(loan, fgts_date, salario)
                if hint:
                    insights.append(hint)
    except Exception as exc:
        logger.warning(f"Erro em fgts_optimizer para {user_id}: {exc}")

    try:
        prio = prioridade_loans(loans)
        if prio:
            insights.append(prio)
    except Exception as exc:
        logger.warning(f"Erro em prioridade_loans para {user_id}: {exc}")

    if not insights:
        return

    rows = [
        {
            "user_id": user_id,
            "month_key": month_key,
            "type": i.type,
            "title": i.title,
            "body": i.body,
            "urgency": i.urgency,
            "data": i.data,
            "action_label": i.action_label,
            "action_url": i.action_url,
            "dismissed": False,
            "created_at": now.isoformat(),
        }
        for i in insights
    ]
    supabase.table("advisor_insights").insert(rows).execute()
    logger.info(f"{len(rows)} insights persistidos para {user_id} ({month_key})")


async def run_monthly_insights_job() -> None:
    """Cron job mensal: calcula e persiste insights para todos os usuários ativos."""
    logger.info("Iniciando job mensal de insights do advisor")
    supabase = get_supabase_admin()

    try:
        rates = await get_current_rates()
    except Exception as exc:
        logger.error(f"Falha ao buscar taxas para o job: {exc}")
        return

    try:
        users_resp = supabase.table("profiles").select("id").eq("active", True).execute()
        users = users_resp.data or []
    except Exception as exc:
        logger.error(f"Falha ao listar usuários ativos: {exc}")
        return

    logger.info(f"Processando {len(users)} usuários ativos")
    for user in users:
        user_id = user["id"]
        try:
            loans_resp = (
                supabase.table("loans").select("*").eq("user_id", user_id).execute()
            )
            loans = loans_resp.data or []
            if loans:
                await _calculate_and_persist_insights(user_id, loans, rates)
        except Exception as exc:
            logger.error(f"Erro ao processar insights para {user_id}: {exc}")

    logger.info("Job mensal de insights concluído")


def start_scheduler() -> None:
    """Inicia o APScheduler com o cron job mensal."""
    scheduler.add_job(
        run_monthly_insights_job,
        trigger=CronTrigger(day=1, hour=8, minute=0, timezone="America/Sao_Paulo"),
        id="monthly_insights",
        replace_existing=True,
        misfire_grace_time=3600,
    )
    scheduler.start()
    logger.info("Scheduler iniciado — job mensal agendado para todo dia 1 às 08:00 BRT")


def stop_scheduler() -> None:
    """Para o APScheduler."""
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("Scheduler encerrado")
