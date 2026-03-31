import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.isCurrency = false,
    this.isPercent = false,
    this.hint,
    this.onChanged,
    this.initialValue,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
    this.suffixText,
    this.prefixText,
    this.onTap,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isCurrency;
  final bool isPercent;
  final String? hint;
  final void Function(String)? onChanged;
  final String? initialValue;
  final bool enabled;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffixText;
  final String? prefixText;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  bool _ownController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController(text: widget.initialValue ?? '');
      _ownController = true;
    } else {
      _controller = widget.controller!;
    }
  }

  @override
  void dispose() {
    if (_ownController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      validator: widget.validator,
      keyboardType: widget.isCurrency || widget.isPercent
          ? const TextInputType.numberWithOptions(decimal: true)
          : widget.keyboardType,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      style: GoogleFonts.inter(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixText: widget.isCurrency
            ? 'R\$ '
            : widget.prefixText,
        suffixText: widget.isPercent
            ? '%'
            : widget.suffixText,
        prefixStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
        suffixStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
      ),
    );
  }
}
