class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.loanId,
    required this.paymentDate,
    required this.amountPaid,
    required this.paymentType,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String loanId;
  final DateTime paymentDate;
  final double amountPaid;
  final String paymentType; // normal, extra_monthly, extra_one_time, amortization
  final String? notes;
  final DateTime createdAt;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      loanId: json['loan_id'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      paymentType: json['payment_type'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'loan_id': loanId,
        'payment_date': paymentDate.toIso8601String(),
        'amount_paid': amountPaid,
        'payment_type': paymentType,
        if (notes != null) 'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  PaymentRecord copyWith({
    String? id,
    String? loanId,
    DateTime? paymentDate,
    double? amountPaid,
    String? paymentType,
    String? notes,
    DateTime? createdAt,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      paymentDate: paymentDate ?? this.paymentDate,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentType: paymentType ?? this.paymentType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          loanId == other.loanId &&
          paymentDate == other.paymentDate &&
          amountPaid == other.amountPaid &&
          paymentType == other.paymentType &&
          notes == other.notes &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      loanId.hashCode ^
      paymentDate.hashCode ^
      amountPaid.hashCode ^
      paymentType.hashCode ^
      notes.hashCode ^
      createdAt.hashCode;
}

class PaymentCreate {
  const PaymentCreate({
    required this.paymentDate,
    required this.amountPaid,
    required this.paymentType,
    this.notes,
  });

  final DateTime paymentDate;
  final double amountPaid;
  final String paymentType;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'payment_date': paymentDate.toIso8601String(),
        'amount_paid': amountPaid,
        'payment_type': paymentType,
        if (notes != null) 'notes': notes,
      };
}
