class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.userId,
    required this.subscriptionType,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.trialEndDate,
    required this.daysRemaining,
    required this.isActive,
    required this.isExpired,
    required this.isTrial,
    required this.autoRenew,
    required this.price,
    required this.currency,
    required this.nextBillingDate,
  });

  final String id;
  final String userId;
  final String subscriptionType; // 'free', 'trial', 'premium'
  final String status; // 'active', 'expired', 'cancelled', 'pending'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? trialEndDate;
  final int daysRemaining;
  final bool isActive;
  final bool isExpired;
  final bool isTrial;
  final bool autoRenew;
  final double? price;
  final String? currency;
  final DateTime? nextBillingDate;

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subscriptionType: json['subscription_type'] as String,
      status: json['status'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      trialEndDate: json['trial_end_date'] != null
          ? DateTime.parse(json['trial_end_date'] as String)
          : null,
      daysRemaining: json['days_remaining'] as int,
      isActive: json['is_active'] as bool,
      isExpired: json['is_expired'] as bool,
      isTrial: json['is_trial'] as bool,
      autoRenew: json['auto_renew'] as bool? ?? false,
      price:
          json['price'] != null ? (json['price'] as num).toDouble() : null,
      currency: json['currency'] as String?,
      nextBillingDate: json['next_billing_date'] != null
          ? DateTime.parse(json['next_billing_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'subscription_type': subscriptionType,
        'status': status,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (trialEndDate != null) 'trial_end_date': trialEndDate!.toIso8601String(),
        'days_remaining': daysRemaining,
        'is_active': isActive,
        'is_expired': isExpired,
        'is_trial': isTrial,
        'auto_renew': autoRenew,
        if (price != null) 'price': price,
        if (currency != null) 'currency': currency,
        if (nextBillingDate != null)
          'next_billing_date': nextBillingDate!.toIso8601String(),
      };

  UserSubscription copyWith({
    String? id,
    String? userId,
    String? subscriptionType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? trialEndDate,
    int? daysRemaining,
    bool? isActive,
    bool? isExpired,
    bool? isTrial,
    bool? autoRenew,
    double? price,
    String? currency,
    DateTime? nextBillingDate,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      isActive: isActive ?? this.isActive,
      isExpired: isExpired ?? this.isExpired,
      isTrial: isTrial ?? this.isTrial,
      autoRenew: autoRenew ?? this.autoRenew,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
    );
  }
}
