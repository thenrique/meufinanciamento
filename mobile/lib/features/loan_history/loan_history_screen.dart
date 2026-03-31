import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../core/constants.dart';
import 'providers.dart';
import 'widgets/comparison_summary_card.dart';
import 'widgets/loan_history_chart.dart';
import 'widgets/payment_list.dart';
import 'widgets/payment_form_dialog.dart';
import '../../models/payment_record.dart';

/// Main loan history screen showing payment history, comparisons, and balance tracking.
/// 
/// Displays estimated vs actual loan performance with interactive payment tracking.
/// 
/// Example usage with GoRouter:
/// ```dart
/// GoRouter(
///   routes: [
///     GoRoute(
///       path: '/loans/:loanId/history',
///       builder: (context, state) => LoanHistoryScreen(
///         loanId: state.pathParameters['loanId']!,
///       ),
///     ),
///   ],
/// )
/// ```
class LoanHistoryScreen extends ConsumerStatefulWidget {
  /// Unique identifier of the loan (from route params)
  final String loanId;

  const LoanHistoryScreen({
    super.key,
    required this.loanId,
  });

  @override
  ConsumerState<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends ConsumerState<LoanHistoryScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshPayments();
  }

  /// Refreshes payment list from API
  Future<void> _refreshPayments() async {
    setState(() => _isRefreshing = true);
    try {
      await ref.read(paymentNotifierProvider(widget.loanId).notifier).refreshPayments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamentos atualizados'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Tentar novamente',
              onPressed: _refreshPayments,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// Opens payment form dialog for creating new payment
  void _openPaymentForm({
    required double outstandingBalance,
    required DateTime loanStartDate,
    required List<dynamic> existingPayments,
  }) {
    showDialog(
      context: context,
      builder: (context) => PaymentFormDialog(
        loanId: widget.loanId,
        outstandingBalance: outstandingBalance,
        loanStartDate: loanStartDate,
        existingPayments: existingPayments.cast(),
        onSubmit: (payment) async {
          try {
            await ref.read(paymentNotifierProvider(widget.loanId).notifier).createPayment(
              PaymentCreate(
                paymentDate: payment.paymentDate,
                amountPaid: payment.amountPaid,
                paymentType: payment.paymentType,
                notes: payment.notes,
              ),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pagamento registrado com sucesso'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao registrar: $e'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// Opens payment form dialog for editing existing payment
  void _editPayment(dynamic payment) {
    // Get summary data for outstanding balance
    final summaryAsync = ref.watch(loanSummaryProvider(widget.loanId));
    final payments = ref.watch(paymentNotifierProvider(widget.loanId));

    summaryAsync.whenData((summary) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => PaymentFormDialog(
            loanId: widget.loanId,
            outstandingBalance: summary.totalPaidActual,
            loanStartDate: DateTime.now(),
            existingPayments: payments,
            initialPayment: payment,
            onSubmit: (updatedPayment) async {
              try {
                await ref.read(paymentNotifierProvider(widget.loanId).notifier).updatePayment(
                  payment.id,
                  PaymentCreate(
                    paymentDate: updatedPayment.paymentDate,
                    amountPaid: updatedPayment.amountPaid,
                    paymentType: updatedPayment.paymentType,
                    notes: updatedPayment.notes,
                  ),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pagamento atualizado com sucesso'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao atualizar: $e'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
          ),
        );
      }
    });
  }

  /// Deletes a payment record
  Future<void> _deletePayment(String paymentId) async {
    try {
      await ref.read(paymentNotifierProvider(widget.loanId).notifier).deletePayment(paymentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento removido'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanHistoryAsync = ref.watch(loanHistoryProvider(widget.loanId));
    final payments = ref.watch(paymentNotifierProvider(widget.loanId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Histórico de Pagamentos',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        actions: [
          // Refresh button
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshPayments,
            tooltip: 'Atualizar',
          ),
          // Add payment button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.green),
            onPressed: () {
              loanHistoryAsync.whenData((history) {
                _openPaymentForm(
                  outstandingBalance: history.summary.totalPaidActual,
                  loanStartDate: history.loan.startDate,
                  existingPayments: history.paymentRecords,
                );
              });
            },
            tooltip: 'Adicionar pagamento',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          loanHistoryAsync.whenData((history) {
            _openPaymentForm(
              outstandingBalance: history.summary.totalPaidActual,
              loanStartDate: history.loan.startDate,
              existingPayments: history.paymentRecords,
            );
          });
        },
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        tooltip: 'Novo pagamento',
        child: const Icon(Icons.add),
      ),
      body: loanHistoryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const Gap(16),
              Text(
                'Erro ao carregar histórico',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Gap(8),
              Text(
                error.toString(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              ElevatedButton(
                onPressed: _refreshPayments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (loanHistory) {
          return RefreshIndicator(
            color: AppColors.navy,
            onRefresh: () async => _refreshPayments(),
            child: CustomScrollView(
              slivers: [
                // Summary card
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: ComparisonSummaryCard(
                      summary: loanHistory.summary,
                      originalPrincipal: loanHistory.loan.totalAmount,
                    ),
                  ),
                ),
                // Chart section
                if (loanHistory.calculatedHistory.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Evolução do Saldo',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Gap(12),
                          SizedBox(
                            height: 300,
                            child: LoanHistoryChart(
                              estimatedData: loanHistory.calculatedHistory,
                              actualData: loanHistory.actualHistory,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Payment history section
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Histórico de Pagamentos',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                // Payment list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: payments.isEmpty ? 200 : null,
                      child: PaymentListWidget(
                        payments: payments,
                        onEdit: _editPayment,
                        onDelete: (paymentId) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remover pagamento?'),
                              content: const Text(
                                'Esta ação não pode ser desfeita.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deletePayment(paymentId);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: const Text('Remover'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Bottom padding
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 32),
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
