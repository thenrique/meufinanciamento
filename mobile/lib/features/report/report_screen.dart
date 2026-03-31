import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../core/constants.dart';
import '../../core/auth_service.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/error_toast.dart';

final _reportLoadingProvider = StateProvider<bool>((ref) => false);

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = AuthService.instance.isPremium;
    final isLoading = ref.watch(_reportLoadingProvider);

    if (!isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.replace('/paywall');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Meu relatório'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 28)),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Relatório Premium ativado',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.navy,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Seu relatório completo de amortização está disponível.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),
            Text(
              'Seu relatório inclui:',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(12),
            ...[
              'Projeção completa mês a mês',
              'Comparativo detalhado dos cenários',
              'Guia prático de amortização no app da Caixa',
              'PDF para guardar e compartilhar',
            ].map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.green, size: 20),
                      const Gap(10),
                      Text(item,
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                )),
            const Spacer(),
            AppButton(
              label: 'Baixar PDF do relatório',
              icon: Icons.picture_as_pdf_outlined,
              isLoading: isLoading,
              onPressed: () async {
                ref.read(_reportLoadingProvider.notifier).state = true;
                try {
                  final response = await ApiClient.instance.dio
                      .post('/report/generate', data: {'loan_id': loanId});
                  final url = response.data['url'] as String?;
                  if (url != null && context.mounted) {
                    // Open PDF URL in browser
                    context.push('/report/webview?url=${Uri.encodeComponent(url)}');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ErrorToast.show(context,
                        'Erro ao gerar relatório. Tente novamente.');
                  }
                } finally {
                  ref.read(_reportLoadingProvider.notifier).state = false;
                }
              },
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}

