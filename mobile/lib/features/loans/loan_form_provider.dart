import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/loan.dart';

class LoanFormState {
  const LoanFormState({
    this.loanId,
    this.bankName = '',
    this.loanType = 'SAC',
    this.totalAmount = 0,
    this.outstandingBalance = 0,
    this.interestRateYear = 0,
    this.startDate,
    this.termMonths = 360,
    this.remainingMonths = 360,
    this.insuranceMonthly = 0,
    this.estimatedSalary,
    this.fgtsLastUse,
    this.paymentDueDay = 10,
    this.isLoading = false,
    this.isSaved = false,
    this.errors = const {},
  });

  final String? loanId;
  final String bankName;
  final String loanType;
  final double totalAmount;
  final double outstandingBalance;
  final double interestRateYear;
  final DateTime? startDate;
  final int termMonths;
  final int remainingMonths;
  final double insuranceMonthly;
  final double? estimatedSalary;
  final DateTime? fgtsLastUse;
  final int paymentDueDay;
  final bool isLoading;
  final bool isSaved;
  final Map<String, String> errors;

  bool get isEditing => loanId != null;

  LoanFormState copyWith({
    String? loanId,
    String? bankName,
    String? loanType,
    double? totalAmount,
    double? outstandingBalance,
    double? interestRateYear,
    DateTime? startDate,
    int? termMonths,
    int? remainingMonths,
    double? insuranceMonthly,
    double? estimatedSalary,
    DateTime? fgtsLastUse,
    int? paymentDueDay,
    bool? isLoading,
    bool? isSaved,
    Map<String, String>? errors,
  }) {
    return LoanFormState(
      loanId: loanId ?? this.loanId,
      bankName: bankName ?? this.bankName,
      loanType: loanType ?? this.loanType,
      totalAmount: totalAmount ?? this.totalAmount,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      interestRateYear: interestRateYear ?? this.interestRateYear,
      startDate: startDate ?? this.startDate,
      termMonths: termMonths ?? this.termMonths,
      remainingMonths: remainingMonths ?? this.remainingMonths,
      insuranceMonthly: insuranceMonthly ?? this.insuranceMonthly,
      estimatedSalary: estimatedSalary ?? this.estimatedSalary,
      fgtsLastUse: fgtsLastUse ?? this.fgtsLastUse,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      isLoading: isLoading ?? this.isLoading,
      isSaved: isSaved ?? this.isSaved,
      errors: errors ?? this.errors,
    );
  }

  Map<String, String> validate() {
    final errs = <String, String>{};
    if (bankName.trim().isEmpty) {
      errs['bankName'] = 'Informe o nome do banco.';
    }
    if (totalAmount <= 0) {
      errs['totalAmount'] = 'O valor deve ser maior que zero.';
    }
    if (outstandingBalance <= 0) {
      errs['outstandingBalance'] = 'O saldo devedor deve ser maior que zero.';
    }
    if (outstandingBalance > totalAmount && totalAmount > 0) {
      errs['outstandingBalance'] =
          'O saldo devedor não pode ser maior que o valor total.';
    }
    if (interestRateYear < 0.1 || interestRateYear > 30) {
      errs['interestRateYear'] = 'A taxa deve estar entre 0,1% e 30%.';
    }
    if (termMonths < 12 || termMonths > 420) {
      errs['termMonths'] = 'O prazo total deve ser entre 12 e 420 meses.';
    }
    if (remainingMonths < 1 || remainingMonths > termMonths) {
      errs['remainingMonths'] =
          'O prazo restante deve ser entre 1 e $termMonths meses.';
    }
    if (insuranceMonthly < 0) {
      errs['insuranceMonthly'] = 'O seguro não pode ser negativo.';
    }
    if (paymentDueDay < 1 || paymentDueDay > 31) {
      errs['paymentDueDay'] = 'O dia do vencimento deve estar entre 1 e 31.';
    }
    return errs;
  }
}

class LoanFormNotifier extends StateNotifier<LoanFormState> {
  LoanFormNotifier([String? loanId])
      : super(LoanFormState(loanId: loanId));

  void loadFromLoan(Loan loan) {
    state = LoanFormState(
      loanId: loan.id,
      bankName: loan.bankName,
      loanType: loan.loanType,
      totalAmount: loan.totalAmount,
      outstandingBalance: loan.outstandingBalance,
      interestRateYear: loan.interestRateYear,
      startDate: loan.startDate,
      termMonths: loan.termMonths,
      remainingMonths: loan.remainingMonths,
      insuranceMonthly: loan.insuranceMonthly,
      estimatedSalary: loan.estimatedSalary,
      fgtsLastUse: loan.fgtsLastUse,
      paymentDueDay: loan.paymentDueDay,
    );
  }

  void update({
    String? bankName,
    String? loanType,
    double? totalAmount,
    double? outstandingBalance,
    double? interestRateYear,
    DateTime? startDate,
    int? termMonths,
    int? remainingMonths,
    double? insuranceMonthly,
    double? estimatedSalary,
    DateTime? fgtsLastUse,
    int? paymentDueDay,
  }) {
    state = state.copyWith(
      bankName: bankName,
      loanType: loanType,
      totalAmount: totalAmount,
      outstandingBalance: outstandingBalance,
      interestRateYear: interestRateYear,
      startDate: startDate,
      termMonths: termMonths,
      remainingMonths: remainingMonths,
      insuranceMonthly: insuranceMonthly,
      estimatedSalary: estimatedSalary,
      fgtsLastUse: fgtsLastUse,
      paymentDueDay: paymentDueDay,
      errors: {},
    );
  }

  Future<void> save() async {
    final errs = state.validate();
    if (errs.isNotEmpty) {
      state = state.copyWith(errors: errs);
      return;
    }

    state = state.copyWith(isLoading: true, errors: {});

    final body = {
      'bank_name': state.bankName.trim(),
      'loan_type': state.loanType,
      'total_amount': state.totalAmount,
      'outstanding_balance': state.outstandingBalance,
      'interest_rate_year': state.interestRateYear,
      'start_date': (state.startDate ?? DateTime.now()).toIso8601String(),
      'term_months': state.termMonths,
      'remaining_months': state.remainingMonths,
      'insurance_monthly': state.insuranceMonthly,
      'payment_due_day': state.paymentDueDay,
      if (state.estimatedSalary != null)
        'estimated_salary': state.estimatedSalary,
      if (state.fgtsLastUse != null)
        'fgts_last_use': state.fgtsLastUse!.toIso8601String(),
    };

    try {
      if (state.isEditing) {
        await ApiClient.instance.dio
            .put('/loans/${state.loanId}', data: body);
      } else {
        await ApiClient.instance.dio.post('/loans', data: body);
      }
      state = state.copyWith(isLoading: false, isSaved: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errors: {'general': friendlyNetworkError(e)},
      );
    }
  }
}

final loanFormProvider =
    StateNotifierProvider.autoDispose.family<LoanFormNotifier, LoanFormState, String?>(
  (ref, loanId) => LoanFormNotifier(loanId),
);
