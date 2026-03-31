import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../models/subscription_status.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers.dart';

/// A widget that displays the trial period status with a visual progress indicator.
///
/// Features:
/// - Shows remaining days in trial with color-coded progress
/// - Green (7+ days), Yellow (3-6 days), Red (1-2 days)
/// - Auto-refreshes every 24 hours
/// - Displays expiration date
/// - Navigate to paywall/upgrade screen on tap
/// - Shows loading and error states gracefully
class TrialCounterWidget extends ConsumerStatefulWidget {
  const TrialCounterWidget({super.key});

  @override
  ConsumerState<TrialCounterWidget> createState() => _TrialCounterWidgetState();
}

class _TrialCounterWidgetState extends ConsumerState<TrialCounterWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh subscription status when app is resumed
      ref.invalidate(subscriptionStatusProvider);
      ref.invalidate(subscriptionNotifierProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(subscriptionNotifierProvider);

    return subscriptionAsync.when(
      data: (userSubscription) {
        final status = SubscriptionStatus.fromSubscription(userSubscription);
        final daysRemaining = status.daysRemaining;
        final isExpired = status.isExpired;

        if (isExpired) {
          return _buildExpiredCard(context);
        }

        return _buildActiveTrialCard(
          context,
          daysRemaining,
          status.expirationDate,
          status.isTrial,
        );
      },
      loading: () => _buildLoadingCard(),
      error: (error, stack) => _buildErrorCard(context, error),
    );
  }

  Widget _buildLoadingCard() {
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
            Row(
              children: [
                const Text('⏱️', style: TextStyle(fontSize: 24)),
                const Gap(12),
                Text(
                  'Trial',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Gap(16),
            const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
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
            Row(
              children: [
                const Text('⏱️', style: TextStyle(fontSize: 24)),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Trial',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            Text(
              'Não foi possível carregar o status do trial',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => ref.invalidate(subscriptionStatusProvider),
                child: const Text('Tentar novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredCard(BuildContext context) {
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
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 24)),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Trial expirado',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(12),
            Text(
              'Sua trial expirou',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(20),
            AppButton(
              label: 'Upgrade Agora',
              onPressed: () => context.push('/paywall'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTrialCard(
    BuildContext context,
    int daysRemaining,
    DateTime expirationDate,
    bool isTrial,
  ) {
    final progressValue = (daysRemaining / 7).clamp(0.0, 1.0);
    final progressColor = _getProgressColor(daysRemaining);

    final isFirstDay = daysRemaining == 7;
    final canExtend = isTrial && daysRemaining > 0;

    final formattedDate = DateFormat('dd/MMM', 'pt_BR').format(expirationDate);

    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Card(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('⏱️', style: TextStyle(fontSize: 24)),
                  const Gap(12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFirstDay ? '7 dias grátis' : '$daysRemaining dias restantes',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Expira em $formattedDate',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const Gap(16),
              // Button
              if (canExtend)
                AppButton(
                  label: 'Estender por 7 dias',
                  onPressed: () => _handleExtendTrial(context),
                )
              else
                AppButton(
                  label: 'Upgrade Agora',
                  onPressed: () => context.push('/paywall'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(int daysRemaining) {
    if (daysRemaining >= 7) {
      return const Color(0xFF10B981); // Green
    } else if (daysRemaining >= 3) {
      return const Color(0xFFF59E0B); // Yellow
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }

  Future<void> _handleExtendTrial(BuildContext context) async {
    try {
      final notifier = ref.read(subscriptionNotifierProvider.notifier);
      await notifier.extendTrial();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trial estendido por 7 dias!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao estender trial: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
