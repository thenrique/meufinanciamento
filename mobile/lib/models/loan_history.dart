import 'loan.dart';
import 'payment_record.dart';

class CalculatedMonthEntry {
  const CalculatedMonthEntry({
    required this.month,
    required this.date,
    required this.paymentPlanned,
    required this.amortization,
    required this.interest,
    required this.insurance,
    required this.outstandingBalance,
  });

  final int month;
  final DateTime date;
  final double paymentPlanned;
  final double amortization;
  final double interest;
  final double insurance;
  final double outstandingBalance;

  factory CalculatedMonthEntry.fromJson(Map<String, dynamic> json) {
    return CalculatedMonthEntry(
      month: json['month'] as int,
      date: DateTime.parse(json['date'] as String),
      paymentPlanned: (json['payment_planned'] as num).toDouble(),
      amortization: (json['amortization'] as num).toDouble(),
      interest: (json['interest'] as num).toDouble(),
      insurance: (json['insurance'] as num).toDouble(),
      outstandingBalance: (json['outstanding_balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'date': date.toIso8601String(),
        'payment_planned': paymentPlanned,
        'amortization': amortization,
        'interest': interest,
        'insurance': insurance,
        'outstanding_balance': outstandingBalance,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatedMonthEntry &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          date == other.date &&
          paymentPlanned == other.paymentPlanned &&
          amortization == other.amortization &&
          interest == other.interest &&
          insurance == other.insurance &&
          outstandingBalance == other.outstandingBalance;

  @override
  int get hashCode =>
      month.hashCode ^
      date.hashCode ^
      paymentPlanned.hashCode ^
      amortization.hashCode ^
      interest.hashCode ^
      insurance.hashCode ^
      outstandingBalance.hashCode;
}

class ActualMonthEntry extends CalculatedMonthEntry {
  const ActualMonthEntry({
    required super.month,
    required super.date,
    required super.paymentPlanned,
    required super.amortization,
    required super.interest,
    required super.insurance,
    required super.outstandingBalance,
    required this.paymentActual,
    required this.payments,
    required this.deviation,
  });

  final double? paymentActual;
  final List<PaymentRecord> payments;
  final double deviation; // actual - planned

  factory ActualMonthEntry.fromJson(Map<String, dynamic> json) {
    return ActualMonthEntry(
      month: json['month'] as int,
      date: DateTime.parse(json['date'] as String),
      paymentPlanned: (json['payment_planned'] as num).toDouble(),
      amortization: (json['amortization'] as num).toDouble(),
      interest: (json['interest'] as num).toDouble(),
      insurance: (json['insurance'] as num).toDouble(),
      outstandingBalance: (json['outstanding_balance'] as num).toDouble(),
      paymentActual: json['payment_actual'] != null
          ? (json['payment_actual'] as num).toDouble()
          : null,
      payments: (json['payments'] as List? ?? [])
          .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      deviation: (json['deviation'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (paymentActual != null) 'payment_actual': paymentActual,
        'payments': payments.map((p) => p.toJson()).toList(),
        'deviation': deviation,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ActualMonthEntry &&
          runtimeType == other.runtimeType &&
          paymentActual == other.paymentActual &&
          payments == other.payments &&
          deviation == other.deviation;

  @override
  int get hashCode =>
      super.hashCode ^
      paymentActual.hashCode ^
      payments.hashCode ^
      deviation.hashCode;
}

class ComparisonSummary {
  const ComparisonSummary({
    required this.totalPaidEstimated,
    required this.totalPaidActual,
    required this.totalDeviation,
    required this.monthsAhead,
    required this.monthsBehind,
    required this.estimatedPayoffDate,
    this.actualPayoffDate,
    required this.timeSavedMonths,
    required this.interestSaved,
  });

  final double totalPaidEstimated;
  final double totalPaidActual;
  final double totalDeviation;
  final int monthsAhead;
  final int monthsBehind;
  final DateTime estimatedPayoffDate;
  final DateTime? actualPayoffDate;
  final int timeSavedMonths;
  final double interestSaved;

  factory ComparisonSummary.fromJson(Map<String, dynamic> json) {
    return ComparisonSummary(
      totalPaidEstimated: (json['total_paid_estimated'] as num).toDouble(),
      totalPaidActual: (json['total_paid_actual'] as num).toDouble(),
      totalDeviation: (json['total_deviation'] as num).toDouble(),
      monthsAhead: json['months_ahead'] as int,
      monthsBehind: json['months_behind'] as int,
      estimatedPayoffDate:
          DateTime.parse(json['estimated_payoff_date'] as String),
      actualPayoffDate: json['actual_payoff_date'] != null
          ? DateTime.parse(json['actual_payoff_date'] as String)
          : null,
      timeSavedMonths: json['time_saved_months'] as int,
      interestSaved: (json['interest_saved'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_paid_estimated': totalPaidEstimated,
        'total_paid_actual': totalPaidActual,
        'total_deviation': totalDeviation,
        'months_ahead': monthsAhead,
        'months_behind': monthsBehind,
        'estimated_payoff_date': estimatedPayoffDate.toIso8601String(),
        if (actualPayoffDate != null)
          'actual_payoff_date': actualPayoffDate!.toIso8601String(),
        'time_saved_months': timeSavedMonths,
        'interest_saved': interestSaved,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonSummary &&
          runtimeType == other.runtimeType &&
          totalPaidEstimated == other.totalPaidEstimated &&
          totalPaidActual == other.totalPaidActual &&
          totalDeviation == other.totalDeviation &&
          monthsAhead == other.monthsAhead &&
          monthsBehind == other.monthsBehind &&
          estimatedPayoffDate == other.estimatedPayoffDate &&
          actualPayoffDate == other.actualPayoffDate &&
          timeSavedMonths == other.timeSavedMonths &&
          interestSaved == other.interestSaved;

  @override
  int get hashCode =>
      totalPaidEstimated.hashCode ^
      totalPaidActual.hashCode ^
      totalDeviation.hashCode ^
      monthsAhead.hashCode ^
      monthsBehind.hashCode ^
      estimatedPayoffDate.hashCode ^
      actualPayoffDate.hashCode ^
      timeSavedMonths.hashCode ^
      interestSaved.hashCode;
}

class LoanHistory {
  const LoanHistory({
    required this.loan,
    required this.paymentRecords,
    required this.calculatedHistory,
    required this.actualHistory,
    required this.summary,
  });

  final Loan loan;
  final List<PaymentRecord> paymentRecords;
  final List<CalculatedMonthEntry> calculatedHistory;
  final List<ActualMonthEntry> actualHistory;
  final ComparisonSummary summary;

  factory LoanHistory.fromJson(Map<String, dynamic> json) {
    return LoanHistory(
      loan: Loan.fromJson(json['loan'] as Map<String, dynamic>),
      paymentRecords: (json['payment_records'] as List? ?? [])
          .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedHistory: (json['calculated_history'] as List? ?? [])
          .map((e) => CalculatedMonthEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      actualHistory: (json['actual_history'] as List? ?? [])
          .map((e) => ActualMonthEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary:
          ComparisonSummary.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'loan': loan.toJson(),
        'payment_records': paymentRecords.map((p) => p.toJson()).toList(),
        'calculated_history':
            calculatedHistory.map((e) => e.toJson()).toList(),
        'actual_history': actualHistory.map((e) => e.toJson()).toList(),
        'summary': summary.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanHistory &&
          runtimeType == other.runtimeType &&
          loan == other.loan &&
          paymentRecords == other.paymentRecords &&
          calculatedHistory == other.calculatedHistory &&
          actualHistory == other.actualHistory &&
          summary == other.summary;

  @override
  int get hashCode =>
      loan.hashCode ^
      paymentRecords.hashCode ^
      calculatedHistory.hashCode ^
      actualHistory.hashCode ^
      summary.hashCode;
}
