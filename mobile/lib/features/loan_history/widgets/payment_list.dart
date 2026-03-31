import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../models/payment_record.dart';

class PaymentListWidget extends StatelessWidget {
  final List<PaymentRecord> payments;
  final Function(PaymentRecord) onEdit;
  final Function(String) onDelete;

  const PaymentListWidget({
    super.key,
    required this.payments,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return _buildEmptyState(context);
    }

    final groupedPayments = _groupPaymentsByMonth();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groupedPayments.length,
      itemBuilder: (context, index) {
        final monthKey = groupedPayments.keys.elementAt(index);
        final monthPayments = groupedPayments[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthHeader(monthKey, monthPayments.length),
            ...monthPayments.map((payment) => _buildPaymentCard(context, payment)),
            const Gap(12),
          ],
        );
      },
    );
  }

  Map<String, List<PaymentRecord>> _groupPaymentsByMonth() {
    final grouped = <String, List<PaymentRecord>>{};

    for (final payment in payments) {
      final monthKey = _formatMonthKey(payment.paymentDate);
      grouped.putIfAbsent(monthKey, () => []).add(payment);
    }

    // Sort within each month by date (descending)
    grouped.forEach((_, paymentList) {
      paymentList.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    });

    // Sort months by date (descending - newest first)
    final sortedGroups = Map<String, List<PaymentRecord>>.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) {
          final dateA = a.value.first.paymentDate;
          final dateB = b.value.first.paymentDate;
          return dateB.compareTo(dateA);
        }),
    );

    return sortedGroups;
  }

  String _formatMonthKey(DateTime date) {
    final monthNames = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return '${monthNames[date.month - 1]}/${date.year}';
  }

  String _getFullMonthName(DateTime date) {
    final monthNames = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return monthNames[date.month - 1];
  }

  Widget _buildMonthHeader(String monthKey, int count) {
    final parts = monthKey.split('/');
    final monthName = _getFullMonthName(
      DateTime(int.parse(parts[1]), _getMonthNumber(parts[0])),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
      ),
      child: Text(
        '$monthName/${parts[1]} ($count ${count == 1 ? 'pagamento' : 'pagamentos'})',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  int _getMonthNumber(String monthAbbr) {
    const months = {
      'jan': 1,
      'fev': 2,
      'mar': 3,
      'abr': 4,
      'mai': 5,
      'jun': 6,
      'jul': 7,
      'ago': 8,
      'set': 9,
      'out': 10,
      'nov': 11,
      'dez': 12,
    };
    return months[monthAbbr.toLowerCase()] ?? 1;
  }

  Widget _buildPaymentCard(BuildContext context, PaymentRecord payment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pagamento de ${_formatAmount(payment.amountPaid)}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Date + Type + Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      _formatPaymentDate(payment.paymentDate),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _getPaymentTypeLabel(payment.paymentType),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      _formatAmount(payment.amountPaid),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              // Row 2: Status badge (placeholder - could be extended)
              Row(
                children: [
                  _buildStatusBadge('no_prazo'),
                ],
              ),
              const Gap(8),
              // Row 3: Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildEditButton(context, payment),
                  _buildDeleteButton(context, payment),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPaymentDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _getPaymentTypeLabel(String type) {
    const labels = {
      'normal': 'Normal',
      'extra_monthly': 'Extra Mensal',
      'extra_one_time': 'Extra Única',
      'amortization': 'Amortização',
    };
    return labels[type] ?? type;
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  Widget _buildStatusBadge(String status) {
    late Color backgroundColor;
    late Color textColor;
    late String label;

    switch (status) {
      case 'adiantado':
        backgroundColor = AppColors.greenLight;
        textColor = AppColors.green;
        label = 'Adiantado';
        break;
      case 'atrasado':
        backgroundColor = const Color(0xFFFFE8E8);
        textColor = AppColors.error;
        label = 'Atrasado';
        break;
      case 'no_prazo':
      default:
        backgroundColor = const Color(0xFFE8F3FF);
        textColor = const Color(0xFF2563EB);
        label = 'No prazo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, PaymentRecord payment) {
    return IconButton(
      icon: const Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
      onPressed: () {
        onEdit(payment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abrindo formulário de edição...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton(BuildContext context, PaymentRecord payment) {
    return IconButton(
      icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
      onPressed: () {
        _showDeleteConfirmation(context, payment);
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, PaymentRecord payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
          'Tem certeza que deseja deletar este pagamento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              try {
                onDelete(payment.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pagamento deletado com sucesso'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao deletar: $e'),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: AppColors.textSecondary.withAlpha(128),
          ),
          const Gap(16),
          Text(
            'Nenhum pagamento registrado',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
