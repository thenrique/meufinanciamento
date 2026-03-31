import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveCallback = isLoading ? null : onPressed;

    Widget buttonChild = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _foregroundColor,
                ),
              ),
            ],
          );

    if (fullWidth) {
      buttonChild = SizedBox(width: double.infinity, child: buttonChild);
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.white,
          ),
          child: buttonChild,
        );
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: effectiveCallback,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.navy),
          ),
          child: buttonChild,
        );
      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
          ),
          child: buttonChild,
        );
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return AppColors.white;
      case AppButtonVariant.secondary:
        return AppColors.navy;
    }
  }
}
