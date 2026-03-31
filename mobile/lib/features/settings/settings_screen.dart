import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/auth_service.dart';
import '../../shared/widgets/app_button.dart';
import '../subscription/providers.dart';

final _notificationsProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('notifications_enabled') ?? true;
});

final _notificationsToggleProvider =
    StateProvider<bool?>((ref) => null);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(_notificationsProvider);
    final notificationsOverride = ref.watch(_notificationsToggleProvider);
    final subscriptionAsync = ref.watch(subscriptionStatusProvider);
    final auth = AuthService.instance;

    final notificationsEnabled = notificationsOverride ??
        notificationsAsync.whenOrNull(data: (v) => v) ??
        true;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Configurações')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Perfil
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.navyLight,
                    backgroundImage: auth.currentUserAvatar != null
                        ? NetworkImage(auth.currentUserAvatar!)
                        : null,
                    child: auth.currentUserAvatar == null
                        ? Text(
                            auth.currentUserName.isNotEmpty
                                ? auth.currentUserName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          )
                        : null,
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUserName,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          auth.currentUserEmail,
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
            const Gap(16),

            // Sua Assinatura
            subscriptionAsync.when(
              data: (subscription) => _SubscriptionCard(
                subscription: subscription,
                onCancel: () => _showCancelConfirmation(context, ref),
              ),
              loading: () => _SubscriptionCardLoading(),
              error: (error, stack) => _SubscriptionCardError(
                error: error,
                onRetry: () {
                  ref.refresh(subscriptionStatusProvider);
                },
              ),
            ),
            const Gap(16),

            // Lista de configurações
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  // Plano
                  _SettingsTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Meu plano',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: auth.isPremium
                            ? AppColors.greenLight
                            : AppColors.navyLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        auth.isPremium ? 'Premium ✨' : 'Gratuito',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: auth.isPremium
                              ? AppColors.green
                              : AppColors.navy,
                        ),
                      ),
                    ),
                    onTap: auth.isPremium
                        ? null
                        : () => context.push('/paywall'),
                  ),
                  const Divider(height: 1, indent: 56),

                  // Notificações
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notificações',
                    trailing: Switch(
                      value: notificationsEnabled,
                      onChanged: (v) async {
                        ref
                            .read(_notificationsToggleProvider.notifier)
                            .state = v;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('notifications_enabled', v);
                      },
                      activeColor: AppColors.green,
                    ),
                  ),
                  const Divider(height: 1, indent: 56),

                  // Sobre o app
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'Sobre o app',
                    subtitle: 'Versão $_appVersion',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: AppStrings.appName,
                        applicationVersion: _appVersion,
                        applicationLegalese:
                            '© 2024 Amortizador Pro. Todos os direitos reservados.',
                      );
                    },
                  ),
                ],
              ),
            ),
            const Gap(32),

            // Botão sair
            AppButton(
              label: 'Sair da conta',
              variant: AppButtonVariant.danger,
              icon: Icons.logout,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sair da conta'),
                    content: const Text(
                        'Tem certeza que deseja sair?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.error),
                        child: const Text('Sair'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await AuthService.instance.signOut();
                  if (context.mounted) {
                    context.go('/onboarding');
                  }
                }
              },
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Assinatura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tem certeza que quer cancelar?'),
            const Gap(12),
            Text(
              'Você pode reativar em até 30 dias.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performCancellation(context, ref);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancellation(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(subscriptionStatusProvider.notifier).cancelSubscription();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assinatura cancelada'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        ref.refresh(subscriptionStatusProvider);
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erro ao cancelar'),
            content: Text('Não conseguimos cancelar sua assinatura: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _performCancellation(context, ref);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.green,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navy, size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary)
              : null),
      onTap: onTap,
    );
  }
}

class _SubscriptionCard extends StatefulWidget {
  final SubscriptionStatus subscription;
  final VoidCallback onCancel;

  const _SubscriptionCard({
    required this.subscription,
    required this.onCancel,
  });

  @override
  State<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<_SubscriptionCard> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final isPremium = !widget.subscription.isTrialActive;
    final planName = widget.subscription.isTrialActive ? 'Trial' : 'Premium';
    final planColor = widget.subscription.isTrialActive ? AppColors.navy : AppColors.green;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sua Assinatura',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plano',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.subscription.isTrialActive 
                        ? AppColors.navyLight 
                        : AppColors.greenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      planName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: planColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.subscription.isTrialActive)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Dias restantes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '${widget.subscription.daysRemaining}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: planColor,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Preço',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'R\$ 14,90/mês',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          if (!widget.subscription.isTrialActive) ...[
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Cancelar Assinatura',
                variant: AppButtonVariant.danger,
                icon: Icons.cancel_outlined,
                isLoading: _isCancelling,
                onPressed: () {
                  setState(() => _isCancelling = true);
                  widget.onCancel();
                  setState(() => _isCancelling = false);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubscriptionCardLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sua Assinatura',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(16),
          const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCardError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _SubscriptionCardError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sua Assinatura',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error),
              const Gap(12),
              Expanded(
                child: Text(
                  'Erro ao carregar assinatura',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.green,
              ),
              child: const Text('Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}
