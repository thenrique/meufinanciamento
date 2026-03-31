import io
from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
)
from reportlab.graphics.shapes import Drawing, Rect, String
from reportlab.graphics.charts.barcharts import VerticalBarChart
from reportlab.graphics import renderPDF
from loguru import logger

COLOR_VERDE = colors.HexColor("#10B981")
COLOR_AZUL = colors.HexColor("#1E3A5F")
COLOR_CINZA_CLARO = colors.HexColor("#F3F4F6")
COLOR_CINZA = colors.HexColor("#6B7280")


def _build_bar_chart(total_base: float, total_aporte: float) -> Drawing:
    """Gera gráfico de barras comparando total pago nos dois cenários."""
    drawing = Drawing(400, 200)
    chart = VerticalBarChart()
    chart.x = 50
    chart.y = 30
    chart.width = 300
    chart.height = 150
    chart.data = [[total_base, total_aporte]]
    chart.bars[0].fillColor = COLOR_AZUL
    chart.categoryAxis.categoryNames = ["Sem amortização", "Com amortização"]
    chart.valueAxis.valueMin = 0
    chart.valueAxis.valueMax = max(total_base, total_aporte) * 1.1
    chart.valueAxis.valueStep = max(total_base, total_aporte) / 5
    drawing.add(chart)
    return drawing


def generate_report_pdf(
    user_name: str,
    loan: dict,
    simulation_result: dict,
) -> bytes:
    """
    Gera relatório PDF completo em memória (BytesIO).

    Args:
        user_name: Nome do usuário para a capa.
        loan: Dados do financiamento.
        simulation_result: Resultado de compare_scenarios() com resumo e tabelas.

    Returns:
        bytes do PDF gerado.
    """
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )

    styles = getSampleStyleSheet()
    style_title = ParagraphStyle(
        "Title",
        parent=styles["Title"],
        textColor=COLOR_AZUL,
        fontSize=22,
        spaceAfter=6,
    )
    style_subtitle = ParagraphStyle(
        "Subtitle",
        parent=styles["Normal"],
        textColor=COLOR_CINZA,
        fontSize=12,
        spaceAfter=4,
    )
    style_section = ParagraphStyle(
        "Section",
        parent=styles["Heading2"],
        textColor=COLOR_AZUL,
        fontSize=14,
        spaceBefore=14,
        spaceAfter=6,
    )
    style_body = ParagraphStyle(
        "Body",
        parent=styles["Normal"],
        fontSize=10,
        leading=14,
        spaceAfter=4,
    )
    style_highlight = ParagraphStyle(
        "Highlight",
        parent=styles["Normal"],
        textColor=COLOR_VERDE,
        fontSize=13,
        fontName="Helvetica-Bold",
        spaceAfter=4,
    )

    story = []
    resumo = simulation_result.get("resumo", {})
    base_schedule = simulation_result.get("cenario_base", [])
    aporte_schedule = simulation_result.get("cenario_com_aporte", [])

    # --- Capa ---
    story.append(Spacer(1, 1 * cm))
    story.append(Paragraph("Amortizador Pro", style_title))
    story.append(Paragraph("Relatório de Amortização de Financiamento", style_subtitle))
    story.append(HRFlowable(width="100%", thickness=2, color=COLOR_AZUL))
    story.append(Spacer(1, 0.3 * cm))
    story.append(Paragraph(f"Preparado para: <b>{user_name}</b>", style_body))
    story.append(Paragraph(f"Financiamento: <b>{loan.get('name', 'Sem nome')}</b>", style_body))
    story.append(Paragraph(f"Data: {datetime.now().strftime('%d/%m/%Y')}", style_body))
    story.append(Spacer(1, 1 * cm))

    # --- Resumo Executivo ---
    story.append(Paragraph("Resumo Executivo", style_section))
    economia_juros = resumo.get("total_juros_economizados", 0)
    meses_ec = resumo.get("meses_economizados", 0)
    economia_total = resumo.get("economia_total", 0)

    story.append(Paragraph(
        f"✓ Você economizará <b>R$ {economia_juros:,.2f}</b> em juros com os aportes extras.",
        style_highlight,
    ))
    story.append(Paragraph(
        f"✓ Seu financiamento será quitado <b>{meses_ec} meses antes</b> do prazo original.",
        style_highlight,
    ))
    story.append(Paragraph(
        f"✓ Economia total (juros + prazo): <b>R$ {economia_total:,.2f}</b>.",
        style_highlight,
    ))
    story.append(Spacer(1, 0.5 * cm))

    # --- Tabela Comparativa (primeiros 12 meses) ---
    story.append(Paragraph("Comparativo dos Primeiros 12 Meses", style_section))
    story.append(Paragraph(
        "A tabela abaixo compara as parcelas e o saldo devedor nos dois cenários.",
        style_body,
    ))

    header = ["Mês", "Parcela Base", "Saldo Base", "Parcela c/ Aporte", "Saldo c/ Aporte"]
    table_data = [header]
    for i in range(min(12, len(base_schedule), len(aporte_schedule))):
        b = base_schedule[i]
        a = aporte_schedule[i]
        table_data.append([
            str(b["mes"]),
            f"R$ {b['prestacao']:,.2f}",
            f"R$ {b['saldo_final']:,.2f}",
            f"R$ {a['prestacao']:,.2f}",
            f"R$ {a['saldo_final']:,.2f}",
        ])

    tbl = Table(table_data, colWidths=[1.5 * cm, 3.5 * cm, 3.5 * cm, 3.5 * cm, 3.5 * cm])
    tbl.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), COLOR_AZUL),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, COLOR_CINZA_CLARO]),
        ("GRID", (0, 0), (-1, -1), 0.3, COLOR_CINZA),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    story.append(tbl)
    story.append(Spacer(1, 0.5 * cm))

    # --- Gráfico ---
    story.append(Paragraph("Total Pago em Cada Cenário", style_section))
    try:
        chart = _build_bar_chart(
            resumo.get("total_pago_base", 0),
            resumo.get("total_pago_aporte", 0),
        )
        story.append(chart)
    except Exception as exc:
        logger.warning(f"Falha ao gerar gráfico no PDF: {exc}")
    story.append(Spacer(1, 0.5 * cm))

    # --- Guia Prático ---
    story.append(Paragraph("Como Fazer a Amortização no App Habitação Caixa", style_section))
    passos = [
        "1. Acesse o app <b>Habitação Caixa</b> no seu celular (Android ou iOS).",
        "2. Faça login com seu CPF e senha do Internet Banking Caixa.",
        "3. Na tela inicial, toque em <b>Meus Contratos</b> e selecione o financiamento.",
        "4. Toque em <b>Amortização Extraordinária</b>.",
        "5. Escolha entre <b>reduzir o prazo</b> (recomendado para economizar mais juros) "
           "ou reduzir a parcela.",
        "6. Informe o valor do aporte e confirme com sua senha eletrônica.",
        "7. Guarde o comprovante — o saldo devedor é atualizado no próximo dia útil.",
    ]
    for passo in passos:
        story.append(Paragraph(passo, style_body))

    story.append(Spacer(1, 0.5 * cm))
    story.append(HRFlowable(width="100%", thickness=1, color=COLOR_CINZA))
    story.append(Paragraph(
        "Relatório gerado pelo Amortizador Pro • www.amortizadorpro.com.br",
        ParagraphStyle("Footer", parent=styles["Normal"], textColor=COLOR_CINZA, fontSize=8, alignment=1),
    ))

    doc.build(story)
    buffer.seek(0)
    return buffer.read()
