import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/auth_service.dart';
import '../../shared/widgets/app_button.dart';

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
