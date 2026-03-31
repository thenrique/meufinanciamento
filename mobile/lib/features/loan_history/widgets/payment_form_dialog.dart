import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../models/payment_record.dart';

/// Interactive form dialog for adding/editing loan payments with validation.
/// 
/// Example usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => PaymentFormDialog(
///     loanId: 'loan_123',
///     outstandingBalance: 50000.0,
///     loanStartDate: DateTime(2023, 1, 15),
///     existingPayments: existingPayments,
///     onSubmit: (payment) {
///       // Handle payment creation/update
///     },
///   ),
/// );
/// ```
class PaymentFormDialog extends StatefulWidget {
  /// Unique identifier of the loan
  final String loanId;

  /// Current outstanding balance for validation
  final double outstandingBalance;

  /// Loan start date to validate payment dates
  final DateTime loanStartDate;

  /// List of existing payments to check for duplicates
  final List<PaymentRecord> existingPayments;

  /// Callback invoked on successful form submission
  final Function(PaymentRecord) onSubmit;

  /// Existing payment for edit mode (null for create mode)
  final PaymentRecord? initialPayment;

  const PaymentFormDialog({
    super.key,
    required this.loanId,
    required this.outstandingBalance,
    required this.loanStartDate,
    required this.existingPayments,
    required this.onSubmit,
    this.initialPayment,
  });

  @override
  State<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<PaymentFormDialog> {
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedType;
  
  final Map<String, String> _fieldErrors = {};
  bool _isSubmitting = false;

  static const List<String> _paymentTypes = [
    'normal',
    'extra_monthly',
    'extra_one_time',
    'amortization',
  ];

  static const Map<String, String> _typeLabels = {
    'normal': 'Normal',
    'extra_monthly': 'Extra Mensal',
    'extra_one_time': 'Extra Única',
    'amortization': 'Amortização',
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialPayment?.paymentDate ?? DateTime.now();
    _selectedType = widget.initialPayment?.paymentType ?? 'normal';
    _amountController = TextEditingController(
      text: widget.initialPayment?.amountPaid.toStringAsFixed(2) ?? '',
    );
    _amountController.addListener(_validateAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.initialPayment != null;
  bool get _isFormValid => _fieldErrors.isEmpty && _amountController.text.isNotEmpty;

  /// Format currency value from user input
  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    
    final clean = value.replaceAll(RegExp(r'[^\d,.]'), '');
    final parts = clean.split(RegExp(r'[,.]'));
    
    if (parts.isEmpty) return '';
    
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    
    return 'R\$ $integerPart,$decimalPart';
  }

  /// Parse currency input to double
  double? _parseCurrency(String value) {
    try {
      final clean = value.replaceAll(RegExp(r'[^\d,]'), '');
      final normalized = clean.replaceAll(',', '.');
      return double.tryParse(normalized);
    } catch (_) {
      return null;
    }
  }

  void _validateDate() {
    final errors = <String>[];

    // Check if future
    if (_selectedDate.isAfter(DateTime.now())) {
      errors.add('Data não pode ser futura');
    }

    // Check if before loan start
    if (_selectedDate.isBefore(widget.loanStartDate)) {
      errors.add('Data não pode ser antes do início do empréstimo');
    }

    // Check for duplicate dates (unless editing same payment)
    final isDuplicate = widget.existingPayments.any((p) {
      if (_isEditMode && p.id == widget.initialPayment!.id) return false;
      return p.paymentDate.year == _selectedDate.year &&
          p.paymentDate.month == _selectedDate.month &&
          p.paymentDate.day == _selectedDate.day;
    });

    if (isDuplicate) {
      errors.add('Data de pagamento já existente');
    }

    _updateFieldError('data', errors);
  }

  void _validateAmount() {
    final errors = <String>[];
    final amount = _parseCurrency(_amountController.text);

    if (_amountController.text.isEmpty) {
      errors.add('Valor obrigatório');
    } else if (amount == null || amount <= 0) {
      errors.add('Valor deve ser maior que 0');
    } else if (amount > widget.outstandingBalance) {
      errors.add('Valor excede o saldo devedor');
    } else if ((amount * 100).toInt() % 1 != 0 && (amount * 100).toInt() % 1 != 0) {
      // Check for more than 2 decimals
      final decimalCount = amount.toString().split('.').last.length;
      if (decimalCount > 2) {
        errors.add('Máximo de 2 casas decimais');
      }
    }

    _updateFieldError('valor', errors);
  }

  void _validateType() {
    final errors = <String>[];
    if (_selectedType.isEmpty) {
      errors.add('Tipo obrigatório');
    }
    _updateFieldError('tipo', errors);
  }

  void _updateFieldError(String field, List<String> errors) {
    setState(() {
      if (errors.isEmpty) {
        _fieldErrors.remove(field);
      } else {
        _fieldErrors[field] = errors.join(', ');
      }
    });
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.loanStartDate,
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _validateDate();
    }
  }

  Future<void> _handleSubmit() async {
    _validateDate();
    _validateAmount();
    _validateType();

    if (!_isFormValid) return;

    setState(() => _isSubmitting = true);

    try {
      final amount = _parseCurrency(_amountController.text);
      if (amount == null) throw Exception('Invalid amount');

      if (_isEditMode) {
        // For edit mode, use the existing payment's id and createdAt
        final payment = PaymentRecord(
          id: widget.initialPayment!.id,
          loanId: widget.loanId,
          paymentDate: _selectedDate,
          amountPaid: amount,
          paymentType: _selectedType,
          createdAt: widget.initialPayment!.createdAt,
        );
        widget.onSubmit(payment);
      } else {
        // For create mode, generate new id and createdAt
        final payment = PaymentRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          loanId: widget.loanId,
          paymentDate: _selectedDate,
          amountPaid: amount,
          paymentType: _selectedType,
          createdAt: DateTime.now(),
        );
        widget.onSubmit(payment);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar pagamento: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 300, maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _isEditMode ? 'Editar Pagamento' : 'Novo Pagamento',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(24),

                // Date Field
                _buildDateField(dateFormat),
                const Gap(16),

                // Amount Field
                _buildAmountField(),
                const Gap(16),

                // Type Field
                _buildTypeField(),
                const Gap(24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildCancelButton(),
                    const Gap(12),
                    _buildSubmitButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data do Pagamento',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const Gap(8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: _fieldErrors.containsKey('data')
                    ? AppColors.error
                    : const Color(0xFFDEE2E6),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(_selectedDate),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_fieldErrors.containsKey('data'))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _fieldErrors['data']!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valor Pago',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const Gap(8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _fieldErrors.containsKey('valor')
                    ? AppColors.error
                    : const Color(0xFFDEE2E6),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            hintText: 'R\$ 0,00',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.green, width: 1),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14),
          onChanged: (value) {
            // Format as user types
            final formatted = _formatCurrency(value);
            if (formatted != value) {
              _amountController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.fromPosition(
                  TextPosition(offset: formatted.length),
                ),
              );
            }
          },
        ),
        if (_fieldErrors.containsKey('valor'))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _fieldErrors['valor']!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _fieldErrors.containsKey('tipo')
                  ? AppColors.error
                  : const Color(0xFFDEE2E6),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.white,
          ),
          child: DropdownButton<String>(
            value: _selectedType,
            isExpanded: true,
            underline: const SizedBox(),
            items: _paymentTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  _typeLabels[type] ?? type,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
                _validateType();
              }
            },
          ),
        ),
        if (_fieldErrors.containsKey('tipo'))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _fieldErrors['tipo']!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        'Cancelar',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _isSubmitting ? AppColors.textSecondary : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEnabled = _isFormValid && !_isSubmitting;
    
    return FilledButton(
      onPressed: isEnabled ? _handleSubmit : null,
      style: FilledButton.styleFrom(
        backgroundColor: isEnabled ? AppColors.green : const Color(0xFFE5E7EB),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        _isSubmitting
            ? 'Salvando...'
            : (_isEditMode ? 'Atualizar' : 'Adicionar'),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
    );
  }
}
