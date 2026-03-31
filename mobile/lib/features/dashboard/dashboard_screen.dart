import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../core/constants.dart';
import '../../core/auth_service.dart';
import '../../core/subscription_provider.dart';
import '../../shared/widgets/error_toast.dart';
import 'dashboard_provider.dart';
import 'widgets/loan_card.dart';
import 'widgets/total_balance_card.dart';
import 'widgets/insight_card.dart';
import 'widgets/trial_counter_widget.dart';
import 'widgets/paywall_overlay.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansProvider);
    final visibleInsightsAsync = ref.watch(visibleInsightsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final userName = AuthService.instance.currentUserName;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(
              'Olá, ${userName.split(' ').first} 👋',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.navy),
                onPressed: () => context.go('/settings'),
                tooltip: 'Configurações',
              ),
            ],
          ),
          floatingActionButton: !subscriptionStatus.isExpired
              ? FloatingActionButton(
                  onPressed: () => context.push('/loans/new'),
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                  tooltip: 'Adicionar financiamento',
                  child: const Icon(Icons.add),
                )
              : null,
          body: RefreshIndicator(
            color: AppColors.navy,
            onRefresh: () async {
              ref.invalidate(loansProvider);
              ref.invalidate(insightsProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: const TrialCounterWidget(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: TotalBalanceCard(totalBalance: totalBalance),
                  ),
                ),
                // Seção de alertas
                visibleInsightsAsync.when(
                  data: (insights) {
                    if (insights.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                    return SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                            child: Text(
                              'Seus alertas',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: insights.length,
                              separatorBuilder: (_, __) => const Gap(12),
                              itemBuilder: (context, index) {
                                return InsightCard(
                                  insight: insights[index],
                                  onDismiss: () {
                                    ref
                                        .read(dismissedInsightsProvider.notifier)
                                        .update((s) => {...s, insights[index].id});
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                // Seção de financiamentos
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seus financiamentos',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                loansAsync.when(
                  data: (loans) {
                    if (loans.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _EmptyLoansState(
                          onAdd: () => context.push('/loans/new'),
                          isExpired: subscriptionStatus.isExpired,
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: loans.length,
                        separatorBuilder: (_, __) => const Gap(12),
                        itemBuilder: (context, index) {
                          return LoanCard(
                            loan: loans[index],
                            onSimulate: !subscriptionStatus.isExpired
                                ? () => context.push('/simulator/${loans[index].id}')
                                : null,
                            onEdit: !subscriptionStatus.isExpired
                                ? () =>
                                    context.push('/loans/${loans[index].id}/edit')
                                : null,
                            onDelete: !subscriptionStatus.isExpired
                                ? () async {
                                    final confirmed = await _confirmDelete(context);
                                    if (confirmed == true) {
                                      ref
                                          .read(deleteLoanProvider(loans[index].id)
                                              .future)
                                          .catchError((e) {
                                        ErrorToast.show(context,
                                            'Erro ao excluir financiamento. Tente novamente.');
                                      });
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.navy),
                    ),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off,
                                color: AppColors.textSecondary, size: 48),
                            const Gap(16),
                            Text(
                              'Não foi possível carregar seus financiamentos.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary),
                            ),
                            const Gap(16),
                            TextButton(
                              onPressed: () => ref.invalidate(loansProvider),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (subscriptionStatus.isExpired) const PaywallOverlay(),
      ],
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir financiamento'),
        content: const Text(
            'Tem certeza que deseja excluir este financiamento? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _EmptyLoansState extends StatelessWidget {
  const _EmptyLoansState({required this.onAdd, required this.isExpired});

  final VoidCallback onAdd;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.home_work_outlined,
                color: AppColors.navy, size: 40),
          ),
          const Gap(16),
          Text(
            'Nenhum financiamento ainda',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(8),
          Text(
            isExpired
                ? 'Upgrade para começar a adicionar financiamentos.'
                : 'Adicione seu primeiro financiamento para começar a simular e economizar.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
          const Gap(24),
          if (!isExpired)
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar financiamento'),
            ),
        ],
      ),
    );
  }
}
