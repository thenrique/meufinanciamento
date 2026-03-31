import 'user_subscription.dart';

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.daysRemaining,
    required this.isActive,
    required this.isExpired,
    required this.isTrial,
    required this.subscriptionType,
    required this.status,
    required this.expirationDate,
    required this.trialEndDate,
  });

  final int daysRemaining;
  final bool isActive;
  final bool isExpired;
  final bool isTrial;
  final String subscriptionType;
  final String status;
  final DateTime expirationDate;
  final DateTime? trialEndDate;

  factory SubscriptionStatus.fromSubscription(UserSubscription subscription) {
    return SubscriptionStatus(
      daysRemaining: subscription.daysRemaining,
      isActive: subscription.isActive,
      isExpired: subscription.isExpired,
      isTrial: subscription.isTrial,
      subscriptionType: subscription.subscriptionType,
      status: subscription.status,
      expirationDate: subscription.endDate,
      trialEndDate: subscription.trialEndDate,
    );
  }

  bool get shouldExtendTrial => isTrial && daysRemaining < 7 && !isExpired;

  bool get shouldUpgrade => isExpired || (isTrial && isExpired);

  String get statusLabel {
    if (isExpired) return 'Expirado';
    if (isTrial) return 'Período de Teste';
    if (isActive) return 'Ativo';
    return status;
  }

  Map<String, dynamic> toJson() => {
        'days_remaining': daysRemaining,
        'is_active': isActive,
        'is_expired': isExpired,
        'is_trial': isTrial,
        'subscription_type': subscriptionType,
        'status': status,
        'expiration_date': expirationDate.toIso8601String(),
        if (trialEndDate != null) 'trial_end_date': trialEndDate!.toIso8601String(),
      };
}
