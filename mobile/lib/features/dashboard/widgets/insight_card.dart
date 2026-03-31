import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../../core/constants.dart';
import '../../../models/insight.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
    required this.onDismiss,
  });

  final Insight insight;
  final VoidCallback onDismiss;

  Color get _borderColor {
    switch (insight.urgency) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.green;
    }
  }

  String get _urgencyEmoji {
    switch (insight.urgency) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      default:
        return '🟢';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: _borderColor, width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_urgencyEmoji, style: const TextStyle(fontSize: 16)),
                const Gap(6),
                Expanded(
                  child: Text(
                    insight.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close,
                      size: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
            const Gap(6),
            Expanded(
              child: Text(
                insight.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Gap(8),
            if (insight.actionLabel.isNotEmpty)
              GestureDetector(
                onTap: () {
                  if (insight.actionUrl.startsWith('/')) {
                    context.push(insight.actionUrl);
                  }
                },
                child: Text(
                  insight.actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _borderColor,
                    decoration: TextDecoration.underline,
                    decorationColor: _borderColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
