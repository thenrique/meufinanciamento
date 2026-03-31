import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../models/loan_history.dart';

/// A card widget that displays 4 key financial metrics comparing estimated vs actual loan values.
/// 
/// This widget presents a 2x2 grid layout (responsive to screen width) showing:
/// - Total Paid (Planned vs Actual)
/// - Interest Paid (Planned vs Actual)
/// - Months to Payoff (Planned vs Actual)
/// - Payoff Date (Planned vs Actual)
/// 
/// The interest paid is derived from the total paid minus the original principal.
/// 
/// Example usage:
/// ```dart
/// ComparisonSummaryCard(summary: comparisonSummary)
/// ```
class ComparisonSummaryCard extends StatelessWidget {
  /// The comparison summary data from the calculation engine
  final ComparisonSummary summary;
  
  /// Optional original loan principal for interest calculation
  /// If not provided, interest is calculated as total paid - assumed principal
  final double? originalPrincipal;

  const ComparisonSummaryCard({
    super.key,
    required this.summary,
    this.originalPrincipal,
  });

  /// Formats a double value as Brazilian currency (R$ 1.234,56)
  String _formatCurrency(double value) {
    return 'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(value)}';
  }

  /// Formats a DateTime as dd/MMM/yyyy in Portuguese (e.g., 01/dez/2026)
  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd/MMM/yyyy', 'pt_BR');
    return formatter.format(date);
  }

  /// Builds a single metric tile with planned and actual values
  Widget _buildMetricTile({
    required String label,
    required String plannedLabel,
    required String actualLabel,
    required String icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const Gap(8),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Planejado: ',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        plannedLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2196F3),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Real: ',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        actualLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    // Calculate interest paid values
    // Interest = Total Paid - Principal
    // Since we have interestSaved = interestPlanned - interestActual
    // And totalPaidEstimated includes all payments (principal + interest)
    // We estimate the principal as approximately equal across both scenarios
    // So: interestActual = totalPaidActual - principal
    // And: interestPlanned = totalPaidEstimated - principal
    final estimatedPrincipal = originalPrincipal ?? 160000; // Default estimate
    final interestPlanned = summary.totalPaidEstimated - estimatedPrincipal;
    final interestActual = summary.totalPaidActual - (estimatedPrincipal - summary.interestSaved);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparativo Resumido',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(16),
            if (isSmallScreen)
              Column(
                children: [
                  _buildMetricTile(
                    label: 'Total Pago',
                    plannedLabel: _formatCurrency(summary.totalPaidEstimated),
                    actualLabel: _formatCurrency(summary.totalPaidActual),
                    icon: '💰',
                  ),
                  const Gap(12),
                  _buildMetricTile(
                    label: 'Juros Pagos',
                    plannedLabel: _formatCurrency(interestPlanned),
                    actualLabel: _formatCurrency(interestActual),
                    icon: '📈',
                  ),
                  const Gap(12),
                  _buildMetricTile(
                    label: 'Meses para Quitação',
                    plannedLabel: '180',
                    actualLabel: '${summary.timeSavedMonths}',
                    icon: '⏱️',
                  ),
                  const Gap(12),
                  _buildMetricTile(
                    label: 'Data de Quitação',
                    plannedLabel: _formatDate(summary.estimatedPayoffDate),
                    actualLabel: summary.actualPayoffDate != null
                        ? _formatDate(summary.actualPayoffDate!)
                        : 'N/A',
                    icon: '📅',
                  ),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      _buildMetricTile(
                        label: 'Total Pago',
                        plannedLabel: _formatCurrency(summary.totalPaidEstimated),
                        actualLabel: _formatCurrency(summary.totalPaidActual),
                        icon: '💰',
                      ),
                      const Gap(12),
                      _buildMetricTile(
                        label: 'Juros Pagos',
                        plannedLabel: _formatCurrency(interestPlanned),
                        actualLabel: _formatCurrency(interestActual),
                        icon: '📈',
                      ),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      _buildMetricTile(
                        label: 'Meses para Quitação',
                        plannedLabel: '180',
                        actualLabel: '${summary.timeSavedMonths}',
                        icon: '⏱️',
                      ),
                      const Gap(12),
                      _buildMetricTile(
                        label: 'Data de Quitação',
                        plannedLabel: _formatDate(summary.estimatedPayoffDate),
                        actualLabel: summary.actualPayoffDate != null
                            ? _formatDate(summary.actualPayoffDate!)
                            : 'N/A',
                        icon: '📅',
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
