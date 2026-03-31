import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../../core/constants.dart';

class StatusIndicator extends StatelessWidget {
  final int monthsAhead;
  final DateTime estimatedPayoffDate;
  final DateTime? actualPayoffDate;

  const StatusIndicator({
    super.key,
    required this.monthsAhead,
    required this.estimatedPayoffDate,
    this.actualPayoffDate,
  });

  @override
  Widget build(BuildContext context) {
    final isAhead = monthsAhead > 0;
    final isLate = monthsAhead < 0;
    final isOnTrack = monthsAhead == 0;

    late Color backgroundColor;
    late Color textColor;
    late IconData icon;
    late String label;

    if (isAhead) {
      backgroundColor = AppColors.greenLight;
      textColor = AppColors.green;
      icon = Icons.check_circle;
      label = 'Adiantado em ${monthsAhead.abs()} ${monthsAhead == 1 ? 'mês' : 'meses'}';
    } else if (isLate) {
      backgroundColor = const Color(0xFFFFE8E8);
      textColor = AppColors.error;
      icon = Icons.error;
      label = 'Atrasado em ${monthsAhead.abs()} ${monthsAhead == -1 ? 'mês' : 'meses'}';
    } else {
      backgroundColor = const Color(0xFFE8F3FF);
      textColor = const Color(0xFF2563EB);
      icon = Icons.check_circle;
      label = 'No prazo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const Gap(8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
