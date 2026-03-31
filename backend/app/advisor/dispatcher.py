from typing import Optional
from loguru import logger
from app.advisor.engine import Insight
from app.advisor.templates import render_insight
from app.advisor.ai_writer import generate_ai_summary, should_use_ai


async def dispatch_insights(
    insights: list[Insight],
    loan_count: int,
) -> list[dict]:
    """
    Recebe lista de Insights, decide qual mensagem usar (template ou IA),
    e retorna lista final de cards prontos para exibição.
    """
    if not insights:
        return []

    ai_summary: Optional[str] = None
    if should_use_ai(insights, loan_count):
        ai_summary = await generate_ai_summary(insights)
        if ai_summary:
            logger.info("Usando resumo gerado por IA para insights do advisor")
        else:
            logger.info("Fallback para templates padrão")

    cards = []
    for insight in insights:
        body = ai_summary if (ai_summary and insight == insights[0]) else render_insight(insight)
        cards.append({
            "id": f"{insight.type}",
            "type": insight.type,
            "title": insight.title,
            "body": body,
            "urgency": insight.urgency,
            "data": insight.data,
            "action_label": insight.action_label,
            "action_url": insight.action_url,
        })

    cards.sort(key=lambda c: {"high": 0, "medium": 1, "low": 2}.get(c["urgency"], 3))
    return cards
