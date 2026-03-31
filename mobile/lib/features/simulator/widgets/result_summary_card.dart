import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../../core/constants.dart';
import '../../../models/simulation.dart';
import '../../../shared/extensions/currency_extension.dart';

class ResultSummaryCard extends StatelessWidget {
  const ResultSummaryCard({
    super.key,
    required this.result,
  });

  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final resumo = result.resumo;

    return Column(
      children: [
        // Card verde — economia total
        _ResultCard(
          color: AppColors.greenLight,
          borderColor: AppColors.green,
          emoji: '💰',
          title: 'Economia em juros',
          value: resumo.totalJurosEconomizados.toCurrency(),
          subtitle:
              'Pagaria ${resumo.totalJurosBase.toCurrency()} → paga ${resumo.totalJurosAporte.toCurrency()}',
        ),
        const Gap(12),
        // Card azul — meses economizados
        _ResultCard(
          color: AppColors.navyLight,
          borderColor: AppColors.navy,
          emoji: '📅',
          title: 'Quitação antecipada',
          value: '${resumo.mesesEconomizados} ${resumo.mesesEconomizados == 1 ? 'mês' : 'meses'} antes',
          subtitle:
              'Prevista para ${resumo.dataQuitacaoAporte.toPortugueseMonthYear()}',
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.color,
    required this.borderColor,
    required this.emoji,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final Color color;
  final Color borderColor;
  final String emoji;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: borderColor,
                  ),
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

