from datetime import date, datetime, timezone
from typing import Optional
from pydantic import BaseModel
from loguru import logger


class Insight(BaseModel):
    type: str
    title: str
    body: str
    urgency: str  # "low" | "medium" | "high"
    data: dict
    action_label: str
    action_url: str


def amortizar_vs_investir(loan: dict, tr_rate: float, selic_rate: float) -> Insight:
    """
    Compara o custo efetivo do financiamento com o rendimento de um CDB a 90% do CDI/Selic.
    Decide se vale mais amortizar ou investir.
    """
    taxa_mensal = (1 + loan["interest_rate_year"] / 100) ** (1 / 12) - 1
    tr_mensal = tr_rate / 100
    custo_efetivo = (1 + taxa_mensal) * (1 + tr_mensal) - 1

    rendimento_cdb = selic_rate * 0.9 / 12 / 100

    if rendimento_cdb > custo_efetivo:
        urgency = "low"
        title = "Invista agora"
        body = (
            f"Hoje vale mais investir: o CDB rende {rendimento_cdb * 100:.2f}% ao mês, "
            f"enquanto seu financiamento custa {custo_efetivo * 100:.2f}% ao mês. "
            f"Guarde os recursos e revise em 30 dias."
        )
        action_label = "Ver opções de investimento"
        action_url = "/advisor/investimentos"
    else:
        urgency = "high"
        title = "Amortize agora"
        body = (
            f"Seu financiamento custa {custo_efetivo * 100:.2f}% ao mês, "
            f"mais caro que um CDB ({rendimento_cdb * 100:.2f}% ao mês). "
            f"Vale a pena usar as reservas para reduzir a dívida."
        )
        action_label = "Simular amortização"
        action_url = f"/simulate?loan_id={loan.get('id', '')}"

    return Insight(
        type="amortizar_vs_investir",
        title=title,
        body=body,
        urgency=urgency,
        data={
            "custo_efetivo_mensal": round(custo_efetivo * 100, 4),
            "rendimento_cdb_mensal": round(rendimento_cdb * 100, 4),
            "selic_anual": selic_rate,
            "tr_mensal": tr_rate,
        },
        action_label=action_label,
        action_url=action_url,
    )


def alerta_tr(loan: dict, tr_historico: list[float]) -> Optional[Insight]:
    """
    Dispara alerta se a TR atual subiu mais de 15% em relação à média dos últimos 3 meses.
    Informa o impacto em reais no saldo devedor.
    """
    if not tr_historico or len(tr_historico) < 2:
        return None

    tr_atual = tr_historico[-1]
    media_3m = sum(tr_historico[-4:-1]) / min(3, len(tr_historico) - 1)

    if media_3m == 0 or tr_atual <= media_3m * 1.15:
        return None

    saldo = loan.get("outstanding_balance", 0)
    impacto = saldo * (tr_atual - media_3m) / 100
    sugestao = round(impacto * 2, -2)

    return Insight(
        type="alerta_tr",
        title="A TR subiu esse mês",
        body=(
            f"A TR subiu esse mês. Seu saldo devedor cresceu R$ {impacto:,.2f}. "
            f"Uma amortização de R$ {sugestao:,.0f} zera esse efeito."
        ),
        urgency="high",
        data={
            "tr_atual": tr_atual,
            "media_3m": round(media_3m, 4),
            "impacto_rs": round(impacto, 2),
            "sugestao_amortizacao": sugestao,
        },
        action_label="Simular amortização",
        action_url=f"/simulate?loan_id={loan.get('id', '')}&extra_one_time={sugestao}",
    )


def fgts_optimizer(
    loan: dict,
    fgts_last_use: Optional[date],
    salario_estimado: float,
) -> Optional[Insight]:
    """
    Verifica se a janela de uso do FGTS está aberta (2+ anos sem usar).
    Estima o saldo disponível e a economia de juros.
    """
    hoje = date.today()
    if fgts_last_use is not None:
        dias_desde_uso = (hoje - fgts_last_use).days
        if dias_desde_uso < 730:
            return None

    meses_fgts = 24
    saldo_fgts_estimado = salario_estimado * 0.08 * meses_fgts
    saldo_devedor = loan.get("outstanding_balance", 0)

    if saldo_fgts_estimado <= 0 or saldo_devedor <= 0:
        return None

    taxa_mensal = (1 + loan["interest_rate_year"] / 100) ** (1 / 12) - 1
    meses = loan.get("term_months", 120)

    juros_sem_fgts = saldo_devedor * taxa_mensal * meses
    novo_saldo = max(0.0, saldo_devedor - saldo_fgts_estimado)
    juros_com_fgts = novo_saldo * taxa_mensal * meses
    economia = juros_sem_fgts - juros_com_fgts

    return Insight(
        type="fgts_optimizer",
        title="Sua janela de FGTS está aberta",
        body=(
            f"Você pode usar até R$ {saldo_fgts_estimado:,.0f} do FGTS para abater seu financiamento. "
            f"Isso pode economizar aproximadamente R$ {economia:,.0f} em juros ao longo do contrato."
        ),
        urgency="medium",
        data={
            "saldo_fgts_estimado": round(saldo_fgts_estimado, 2),
            "economia_estimada": round(economia, 2),
            "fgts_last_use": fgts_last_use.isoformat() if fgts_last_use else None,
        },
        action_label="Saiba como usar o FGTS",
        action_url="/advisor/fgts",
    )


def prioridade_loans(loans: list[dict]) -> Optional[Insight]:
    """
    Identifica o financiamento mais caro entre todos do usuário e recomenda priorizá-lo.
    Só dispara quando o usuário tem 2 ou mais financiamentos.
    """
    if len(loans) < 2:
        return None

    def custo_efetivo(loan: dict) -> float:
        taxa_anual = loan.get("interest_rate_year", 0)
        tr_anual = 0.5
        seguro_anual = loan.get("insurance_monthly", 0) * 12
        saldo = loan.get("outstanding_balance", 1)
        return taxa_anual + tr_anual + (seguro_anual / saldo * 100 if saldo > 0 else 0)

    loans_sorted = sorted(loans, key=custo_efetivo, reverse=True)
    mais_caro = loans_sorted[0]
    custo = custo_efetivo(mais_caro)

    return Insight(
        type="prioridade_loans",
        title="Priorize o financiamento mais caro",
        body=(
            f"Seu financiamento '{mais_caro.get('name', 'sem nome')}' custa cerca de "
            f"{custo:.1f}% ao ano (incluindo seguros). Direcione seus aportes extras para ele primeiro."
        ),
        urgency="medium",
        data={
            "loan_id": mais_caro.get("id"),
            "loan_name": mais_caro.get("name"),
            "custo_efetivo_anual": round(custo, 2),
        },
        action_label="Simular amortização",
        action_url=f"/simulate?loan_id={mais_caro.get('id', '')}",
    )


def meta_quitacao(loan: dict, extra_monthly: float) -> Insight:
    """
    Calcula a data estimada de quitação com aportes mensais extras.
    Mostra quantos meses serão economizados.
    """
    from app.finance.engine import CaixaModel
    import asyncio

    saldo = loan.get("outstanding_balance", 0)
    taxa = loan.get("interest_rate_year", 0)
    meses = loan.get("term_months", 120)
    seguro = loan.get("insurance_monthly", 0)

    async def _calc():
        model = CaixaModel()
        df_base = await model.calculate_schedule(saldo, taxa, meses, seguro)
        df_extra = await model.calculate_schedule(saldo, taxa, meses, seguro, extra_monthly)
        return len(df_base), len(df_extra)

    try:
        loop = asyncio.get_event_loop()
        meses_base, meses_extra = loop.run_until_complete(_calc())
    except Exception as exc:
        logger.warning(f"Erro ao calcular meta_quitacao: {exc}")
        meses_base, meses_extra = meses, meses

    meses_economizados = meses_base - meses_extra
    hoje = datetime.now(timezone.utc)
    from dateutil.relativedelta import relativedelta
    data_quitacao = hoje + relativedelta(months=meses_extra)

    return Insight(
        type="meta_quitacao",
        title="Sua meta de quitação",
        body=(
            f"Com aportes extras de R$ {extra_monthly:,.0f}/mês, você quita o financiamento "
            f"em {data_quitacao.strftime('%B de %Y')}, economizando {meses_economizados} meses."
        ),
        urgency="low",
        data={
            "meses_base": meses_base,
            "meses_com_extra": meses_extra,
            "meses_economizados": meses_economizados,
            "data_quitacao_estimada": data_quitacao.isoformat(),
            "extra_monthly": extra_monthly,
        },
        action_label="Ver simulação completa",
        action_url=f"/simulate?loan_id={loan.get('id', '')}&extra_monthly={extra_monthly}",
    )
