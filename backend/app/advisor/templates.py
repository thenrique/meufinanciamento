from app.advisor.engine import Insight


def render_amortizar_vs_investir(insight: Insight) -> str:
    d = insight.data
    rendimento = d["rendimento_cdb_mensal"]
    custo = d["custo_efetivo_mensal"]
    return insight.body


def render_alerta_tr(insight: Insight) -> str:
    d = insight.data
    impacto = d["impacto_rs"]
    sugestao = d["sugestao_amortizacao"]
    return (
        f"A TR subiu esse mês. Seu saldo devedor cresceu R$ {impacto:,.2f}. "
        f"Uma amortização de R$ {sugestao:,.0f} zera esse efeito."
    )


def render_fgts_optimizer(insight: Insight) -> str:
    d = insight.data
    saldo = d["saldo_fgts_estimado"]
    economia = d["economia_estimada"]
    return (
        f"Sua janela de FGTS está aberta! Você pode usar até R$ {saldo:,.0f} "
        f"para abater o financiamento e economizar cerca de R$ {economia:,.0f} em juros."
    )


def render_prioridade_loans(insight: Insight) -> str:
    d = insight.data
    nome = d["loan_name"]
    custo = d["custo_efetivo_anual"]
    return (
        f"Priorize o financiamento '{nome}': ele custa {custo:.1f}% ao ano. "
        f"Direcione seus aportes extras para ele primeiro e economize mais."
    )


def render_meta_quitacao(insight: Insight) -> str:
    d = insight.data
    meses_ec = d["meses_economizados"]
    extra = d["extra_monthly"]
    data_q = d["data_quitacao_estimada"][:7]
    return (
        f"Com R$ {extra:,.0f}/mês a mais, você quita em {data_q} — "
        f"{meses_ec} meses antes do prazo original."
    )


RENDERERS = {
    "amortizar_vs_investir": render_amortizar_vs_investir,
    "alerta_tr": render_alerta_tr,
    "fgts_optimizer": render_fgts_optimizer,
    "prioridade_loans": render_prioridade_loans,
    "meta_quitacao": render_meta_quitacao,
}


def render_insight(insight: Insight) -> str:
    """Aplica o template PT-BR correto para o tipo de insight."""
    renderer = RENDERERS.get(insight.type)
    if renderer:
        return renderer(insight)
    return insight.body
