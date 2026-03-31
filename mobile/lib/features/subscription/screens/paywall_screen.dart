import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../../core/constants.dart';
import '../providers.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const _stripeCheckoutUrl =
      String.fromEnvironment('STRIPE_CHECKOUT_URL', defaultValue: '');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          // Header com gradiente
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, Color(0xFF2D5487)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 16,
                24,
                40,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const Gap(16),
                  const Text(
                    '⏰',
                    style: TextStyle(fontSize: 56),
                  ),
                  const Gap(16),
                  Text(
                    'Sua trial expirou!',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    'Continue aproveitando todos os benefícios',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Gap(8),

                // Benefícios
                Text(
                  'O que você recebe:',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(16),
                ...[
                  'Simulações ilimitadas',
                  'Histórico de pagamentos',
                  'Análise de cenários',
                  'Suporte prioritário',
                ].map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.greenLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppColors.green,
                              size: 18,
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                const Gap(32),

                // Preço
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.navy.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Plano Premium',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'R\$ 14,90',
                        style: GoogleFonts.inter(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '/mês',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Gap(12),
                      Text(
                        'Sem contrato, cancele quando quiser',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Gap(32),

                // Botão primário
                _buildActivateButton(context, ref, subscriptionAsync),

                const Gap(12),

                // Botão secundário
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Text(
                    'Continuar como visitante',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                ),

                const Gap(12),

                // Botão terciário
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const Gap(32),

                // Info reativação
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFCD34D),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('ℹ️', style: TextStyle(fontSize: 24)),
                      const Gap(8),
                      Text(
                        'Se cancelou e quer voltar?',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(4),
                      Text(
                        'Reative sua assinatura em até 30 dias e recupere seu acesso',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFB45309),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Gap(24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivateButton(
      BuildContext context, WidgetRef ref, AsyncValue<dynamic> subscriptionAsync) {
    return subscriptionAsync.when(
      data: (_) => ElevatedButton(
        onPressed: () => _openCheckout(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
        ),
        child: Text(
          'Ativar Assinatura',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      loading: () => ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          disabledBackgroundColor: AppColors.green.withValues(alpha: 0.6),
        ),
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.white,
          ),
        ),
      ),
      error: (error, stack) => Column(
        children: [
          ElevatedButton(
            onPressed: () => _openCheckout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.white,
              minimumSize: const Size(double.infinity, 56),
            ),
            child: Text(
              'Ativar Assinatura',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Gap(8),
          Text(
            'Erro ao conectar. Tente novamente.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openCheckout(BuildContext context) {
    if (_stripeCheckoutUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checkout não configurado. Por favor, contate o suporte.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Future: Implement Stripe checkout integration
    // For now, show a toast indicating the action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Redirecionando para pagamento...',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: AppColors.green,
      ),
    );
  }
}
