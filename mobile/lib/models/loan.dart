class Loan {
  const Loan({
    required this.id,
    required this.bankName,
    required this.loanType,
    required this.totalAmount,
    required this.outstandingBalance,
    required this.interestRateYear,
    required this.startDate,
    required this.termMonths,
    required this.remainingMonths,
    required this.insuranceMonthly,
    this.fgtsLastUse,
    this.estimatedSalary,
    this.paymentDueDay = 10,
  });

  final String id;
  final String bankName;

  /// 'SAC' ou 'PRICE'
  final String loanType;
  final double totalAmount;
  final double outstandingBalance;
  final double interestRateYear;
  final DateTime startDate;
  final int termMonths;
  final int remainingMonths;
  final double insuranceMonthly;
  final DateTime? fgtsLastUse;
  final double? estimatedSalary;
  final int paymentDueDay;

  double get interestRateMonth => interestRateYear / 12 / 100;

  double get monthlyPaymentEstimate {
    if (loanType == 'SAC') {
      final amortization = outstandingBalance / remainingMonths;
      final interest = outstandingBalance * interestRateMonth;
      return amortization + interest + insuranceMonthly;
    }
    // PRICE
    final r = interestRateMonth;
    final n = remainingMonths;
    if (r == 0) return outstandingBalance / n + insuranceMonthly;
    final payment =
        outstandingBalance * (r * _pow(1 + r, n)) / (_pow(1 + r, n) - 1);
    return payment + insuranceMonthly;
  }

  static double _pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      bankName: json['bank_name'] as String,
      loanType: json['loan_type'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      outstandingBalance: (json['outstanding_balance'] as num).toDouble(),
      interestRateYear: (json['interest_rate_year'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      termMonths: json['term_months'] as int,
      remainingMonths: json['remaining_months'] as int,
      insuranceMonthly: (json['insurance_monthly'] as num).toDouble(),
      paymentDueDay: (json['payment_due_day'] as int?) ?? 10,
      fgtsLastUse: json['fgts_last_use'] != null
          ? DateTime.parse(json['fgts_last_use'] as String)
          : null,
      estimatedSalary: json['estimated_salary'] != null
          ? (json['estimated_salary'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank_name': bankName,
      'loan_type': loanType,
      'total_amount': totalAmount,
      'outstanding_balance': outstandingBalance,
      'interest_rate_year': interestRateYear,
      'start_date': startDate.toIso8601String(),
      'term_months': termMonths,
      'remaining_months': remainingMonths,
      'insurance_monthly': insuranceMonthly,
      'payment_due_day': paymentDueDay,
      if (fgtsLastUse != null) 'fgts_last_use': fgtsLastUse!.toIso8601String(),
      if (estimatedSalary != null) 'estimated_salary': estimatedSalary,
    };
  }

  Loan copyWith({
    String? id,
    String? bankName,
    String? loanType,
    double? totalAmount,
    double? outstandingBalance,
    double? interestRateYear,
    DateTime? startDate,
    int? termMonths,
    int? remainingMonths,
    double? insuranceMonthly,
    DateTime? fgtsLastUse,
    double? estimatedSalary,
    int? paymentDueDay,
  }) {
    return Loan(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      loanType: loanType ?? this.loanType,
      totalAmount: totalAmount ?? this.totalAmount,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      interestRateYear: interestRateYear ?? this.interestRateYear,
      startDate: startDate ?? this.startDate,
      termMonths: termMonths ?? this.termMonths,
      remainingMonths: remainingMonths ?? this.remainingMonths,
      insuranceMonthly: insuranceMonthly ?? this.insuranceMonthly,
      fgtsLastUse: fgtsLastUse ?? this.fgtsLastUse,
      estimatedSalary: estimatedSalary ?? this.estimatedSalary,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
    );
  }
}
