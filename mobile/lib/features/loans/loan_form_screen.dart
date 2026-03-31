import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../features/dashboard/dashboard_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/error_toast.dart';
import 'loan_form_provider.dart';

class LoanFormScreen extends ConsumerStatefulWidget {
  const LoanFormScreen({super.key, this.loanId});

  final String? loanId;

  @override
  ConsumerState<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends ConsumerState<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _totalAmountCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _termCtrl;
  late final TextEditingController _remainingCtrl;
  late final TextEditingController _insuranceCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _fgtsDateCtrl;
  late int _paymentDueDay;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(loanFormProvider(widget.loanId).notifier);
    final s = ref.read(loanFormProvider(widget.loanId));

    _bankNameCtrl = TextEditingController(text: s.bankName);
    _totalAmountCtrl = TextEditingController(
        text: s.totalAmount > 0 ? _fmt(s.totalAmount) : '');
    _balanceCtrl = TextEditingController(
        text: s.outstandingBalance > 0 ? _fmt(s.outstandingBalance) : '');
    _rateCtrl = TextEditingController(
        text: s.interestRateYear > 0
            ? s.interestRateYear.toStringAsFixed(2).replaceAll('.', ',')
            : '');
    _termCtrl =
        TextEditingController(text: s.termMonths > 0 ? '${s.termMonths}' : '');
    _remainingCtrl = TextEditingController(
        text: s.remainingMonths > 0 ? '${s.remainingMonths}' : '');
    _insuranceCtrl = TextEditingController(
        text: s.insuranceMonthly > 0 ? _fmt(s.insuranceMonthly) : '');
    _salaryCtrl = TextEditingController(
        text: s.estimatedSalary != null ? _fmt(s.estimatedSalary!) : '');
    _startDateCtrl = TextEditingController(
        text: s.startDate != null ? _fmtDate(s.startDate!) : '');
    _fgtsDateCtrl = TextEditingController(
        text: s.fgtsLastUse != null ? _fmtDate(s.fgtsLastUse!) : '');
    _paymentDueDay = s.paymentDueDay;

    // Load loan data if editing
    if (widget.loanId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final loansAsync = ref.read(loansProvider);
        loansAsync.whenData((loans) {
          final loan =
              loans.where((l) => l.id == widget.loanId).firstOrNull;
          if (loan != null) {
            notifier.loadFromLoan(loan);
            setState(() {
              _bankNameCtrl.text = loan.bankName;
              _totalAmountCtrl.text = _fmt(loan.totalAmount);
              _balanceCtrl.text = _fmt(loan.outstandingBalance);
              _rateCtrl.text =
                  loan.interestRateYear.toStringAsFixed(2).replaceAll('.', ',');
              _termCtrl.text = '${loan.termMonths}';
              _remainingCtrl.text = '${loan.remainingMonths}';
              _insuranceCtrl.text = _fmt(loan.insuranceMonthly);
              if (loan.estimatedSalary != null) {
                _salaryCtrl.text = _fmt(loan.estimatedSalary!);
              }
              _startDateCtrl.text = _fmtDate(loan.startDate);
              if (loan.fgtsLastUse != null) {
                _fgtsDateCtrl.text = _fmtDate(loan.fgtsLastUse!);
              }
              _paymentDueDay = loan.paymentDueDay;
            });
          }
        });
      });
    }
  }

  String _fmt(double v) =>
      NumberFormat('#,##0.00', 'pt_BR').format(v);

  String _fmtDate(DateTime d) =>
      DateFormat('dd/MM/yyyy').format(d);

  double _parseCurrency(String v) {
    final clean = v.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(clean) ?? 0;
  }

  double _parseRate(String v) {
    final clean = v.replaceAll(',', '.');
    return double.tryParse(clean) ?? 0;
  }

  @override
  void dispose() {
    for (final c in [
      _bankNameCtrl,
      _totalAmountCtrl,
      _balanceCtrl,
      _rateCtrl,
      _termCtrl,
      _remainingCtrl,
      _insuranceCtrl,
      _salaryCtrl,
      _startDateCtrl,
      _fgtsDateCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(loanFormProvider(widget.loanId));
    final notifier = ref.read(loanFormProvider(widget.loanId).notifier);

    ref.listen<LoanFormState>(loanFormProvider(widget.loanId), (prev, next) {
      if (next.isSaved && !(prev?.isSaved ?? false)) {
        ref.invalidate(loansProvider);
        ErrorToast.showSuccess(
          context,
          next.isEditing
              ? 'Financiamento atualizado!'
              : 'Financiamento adicionado!',
        );
        context.pop();
      }
      if (next.errors['general'] != null &&
          next.errors['general'] != prev?.errors['general']) {
        ErrorToast.show(context, next.errors['general']!);
      }
    });

    final isEditing = widget.loanId != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar financiamento' : 'Novo financiamento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Dados do banco'),
              const Gap(12),

              // Nome do banco
              TextFormField(
                controller: _bankNameCtrl,
                decoration: const InputDecoration(labelText: 'Nome do banco *'),
                textCapitalization: TextCapitalization.words,
                onChanged: (v) => notifier.update(bankName: v),
                validator: (_) => formState.errors['bankName'],
              ),
              const Gap(16),

              // Sistema
              Text(
                'Sistema de amortização *',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const Gap(8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'SAC', label: Text('SAC')),
                  ButtonSegment(value: 'PRICE', label: Text('PRICE')),
                ],
                selected: {formState.loanType},
                onSelectionChanged: (s) =>
                    notifier.update(loanType: s.first),
              ),
              const Gap(24),

              _SectionTitle('Valores'),
              const Gap(12),

              // Valor total
              TextFormField(
                controller: _totalAmountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Valor total do financiamento *',
                  prefixText: 'R\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                onChanged: (v) =>
                    notifier.update(totalAmount: _parseCurrency(v)),
                validator: (_) => formState.errors['totalAmount'],
              ),
              const Gap(16),

              // Saldo devedor
              TextFormField(
                controller: _balanceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Saldo devedor atual *',
                  prefixText: 'R\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                onChanged: (v) =>
                    notifier.update(outstandingBalance: _parseCurrency(v)),
                validator: (_) => formState.errors['outstandingBalance'],
              ),
              const Gap(16),

              // Taxa de juros
              TextFormField(
                controller: _rateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Taxa de juros anual *',
                  suffixText: '% a.a.',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                onChanged: (v) =>
                    notifier.update(interestRateYear: _parseRate(v)),
                validator: (_) => formState.errors['interestRateYear'],
              ),
              const Gap(24),

              _SectionTitle('Prazos'),
              const Gap(12),

              // Data de início
              TextFormField(
                controller: _startDateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Data de início',
                  suffixIcon:
                      Icon(Icons.calendar_today, color: AppColors.navy),
                ),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: formState.startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) {
                    _startDateCtrl.text = _fmtDate(picked);
                    notifier.update(startDate: picked);
                  }
                },
              ),
              const Gap(16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _termCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Prazo total *',
                        suffixText: 'meses',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      onChanged: (v) =>
                          notifier.update(termMonths: int.tryParse(v) ?? 0),
                      validator: (_) => formState.errors['termMonths'],
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: TextFormField(
                      controller: _remainingCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Prazo restante *',
                        suffixText: 'meses',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      onChanged: (v) =>
                          notifier.update(remainingMonths: int.tryParse(v) ?? 0),
                      validator: (_) => formState.errors['remainingMonths'],
                    ),
                  ),
                ],
              ),
              const Gap(24),

              _SectionTitle('Seguro e FGTS (opcional)'),
              const Gap(12),

              // Seguro mensal
              TextFormField(
                controller: _insuranceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Seguro mensal MIP+DFI',
                  prefixText: 'R\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                onChanged: (v) =>
                    notifier.update(insuranceMonthly: _parseCurrency(v)),
                validator: (_) => formState.errors['insuranceMonthly'],
              ),
              const Gap(16),

              // Salário estimado
              TextFormField(
                controller: _salaryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Salário estimado (para FGTS)',
                  prefixText: 'R\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                onChanged: (v) {
                  final parsed = _parseCurrency(v);
                  notifier.update(estimatedSalary: parsed > 0 ? parsed : null);
                },
              ),
              const Gap(16),

              // Último uso FGTS
              TextFormField(
                controller: _fgtsDateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Último uso do FGTS',
                  suffixIcon:
                      Icon(Icons.calendar_today, color: AppColors.navy),
                ),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        formState.fgtsLastUse ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) {
                    _fgtsDateCtrl.text = _fmtDate(picked);
                    notifier.update(fgtsLastUse: picked);
                  }
                },
              ),
              const Gap(24),

              _SectionTitle('Vencimento'),
              const Gap(12),

              Text(
                'Dia do vencimento: $_paymentDueDay',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Gap(8),
              Slider(
                value: _paymentDueDay.toDouble(),
                min: 1,
                max: 31,
                divisions: 30,
                label: '$_paymentDueDay',
                onChanged: (value) {
                  setState(() {
                    _paymentDueDay = value.toInt();
                  });
                  notifier.update(paymentDueDay: value.toInt());
                },
              ),
              const Gap(32),

              AppButton(
                label: isEditing ? 'Salvar alterações' : 'Adicionar financiamento',
                isLoading: formState.isLoading,
                onPressed: () => notifier.save(),
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
    );
  }
}
