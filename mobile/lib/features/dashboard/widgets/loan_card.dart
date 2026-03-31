import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../../core/constants.dart';
import '../../../models/loan.dart';
import '../../../shared/extensions/currency_extension.dart';

class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.loan,
    required this.onSimulate,
    required this.onEdit,
    required this.onDelete,
  });

  final Loan loan;
  final VoidCallback onSimulate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isHighBalance =
        loan.outstandingBalance > loan.totalAmount * 0.7;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🏦', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.bankName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Gap(4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: loan.loanType == 'SAC'
                              ? AppColors.greenLight
                              : AppColors.navyLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          loan.loanType,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: loan.loanType == 'SAC'
                                ? AppColors.green
                                : AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          Gap(8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          Gap(8),
                          Text('Excluir',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Gap(16),
            const Divider(height: 1),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'Saldo devedor',
                    value: loan.outstandingBalance.toCurrency(),
                    valueColor:
                        isHighBalance ? AppColors.error : AppColors.green,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Parcela estimada',
                    value: loan.monthlyPaymentEstimate.toCurrency(),
                    valueColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'Taxa anual',
                    value: loan.interestRateYear.toPercent(),
                    valueColor: AppColors.textPrimary,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Prazo restante',
                    value: loan.remainingMonths.toMonths(),
                    valueColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: onSimulate,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Simular amortização'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const Gap(2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
