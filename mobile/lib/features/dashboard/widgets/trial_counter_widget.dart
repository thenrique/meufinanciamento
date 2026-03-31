import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../features/subscription/providers.dart';

class TrialCounterWidget extends ConsumerWidget {
  const TrialCounterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionStatusProvider);

    return subscriptionAsync.when(
      data: (status) {
        // Hide if user has active premium subscription
        if (!status.isTrial && status.isActive) {
          return const SizedBox.shrink();
        }

        // Show expired state
        if (status.isExpired) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withAlpha((0.3 * 255).toInt())),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                const Gap(8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trial expirado',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Seu período de testes terminou. Upgrade para continuar.',
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

        // Show trial countdown
        if (status.isTrial && status.isActive) {
          final daysLeft = status.daysRemaining;
          final isWarning = daysLeft <= 3;

          return Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isWarning
                  ? AppColors.warning.withAlpha((0.1 * 255).toInt())
                  : AppColors.navy.withAlpha((0.05 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isWarning
                    ? AppColors.warning.withAlpha((0.3 * 255).toInt())
                    : AppColors.navy.withAlpha((0.1 * 255).toInt()),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isWarning ? Icons.hourglass_bottom : Icons.info_outlined,
                  color: isWarning ? AppColors.warning : AppColors.navy,
                  size: 20,
                ),
                const Gap(8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teste grátis',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isWarning ? AppColors.warning : AppColors.navy,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        daysLeft == 1
                            ? 'Último dia do seu período de testes'
                            : 'Mais $daysLeft dias de acesso total',
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

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
