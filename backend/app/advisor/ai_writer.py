from typing import Optional
from loguru import logger
from app.advisor.engine import Insight
from app.config import get_settings


async def generate_ai_summary(insights: list[Insight]) -> Optional[str]:
    """
    Gera um resumo personalizado via GPT-4o-mini quando:
    - 2 ou mais insights têm urgency="high"
    - usuário tem 3 ou mais financiamentos

    Envia apenas dados calculados, sem PII ou dados brutos.
    Retorna None se a chamada falhar (fallback para template padrão).
    """
    settings = get_settings()
    if not settings.OPENAI_API_KEY:
        logger.warning("OPENAI_API_KEY não configurada, usando template padrão")
        return None

    try:
        import openai
        client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

        insights_summary = [
            {
                "tipo": i.type,
                "titulo": i.title,
                "urgencia": i.urgency,
                "dados_chave": i.data,
            }
            for i in insights
        ]

        prompt = (
            "Você é um conselheiro financeiro brasileiro especialista em financiamentos imobiliários. "
            "Com base nos seguintes insights calculados para um cliente, escreva um parágrafo curto "
            "(máximo 2 frases) em português, tom cordial e direto, sem jargão, resumindo a situação "
            "e a ação mais urgente. Não mencione nomes ou dados pessoais.\n\n"
            f"Insights: {insights_summary}"
        )

        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=150,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.4,
        )
        return response.choices[0].message.content.strip()
    except Exception as exc:
        logger.warning(f"Falha na chamada OpenAI, usando template padrão: {exc}")
        return None


def should_use_ai(insights: list[Insight], loan_count: int) -> bool:
    """Verifica se os critérios para uso da IA estão satisfeitos."""
    high_urgency_count = sum(1 for i in insights if i.urgency == "high")
    return high_urgency_count >= 2 or loan_count >= 3
