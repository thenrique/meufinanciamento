import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class SubscriptionStatus {
  final bool isActive;
  final bool isExpired;
  final int daysRemaining;
  final DateTime? expiryDate;
  final bool isLoading;
  final String? error;

  SubscriptionStatus({
    required this.isActive,
    required this.isExpired,
    required this.daysRemaining,
    this.expiryDate,
    this.isLoading = false,
    this.error,
  });

  factory SubscriptionStatus.loading() => SubscriptionStatus(
    isActive: false,
    isExpired: false,
    daysRemaining: 0,
    isLoading: true,
  );

  factory SubscriptionStatus.error(String error) => SubscriptionStatus(
    isActive: false,
    isExpired: false,
    daysRemaining: 0,
    error: error,
  );

  factory SubscriptionStatus.fromUserMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) {
      return SubscriptionStatus(
        isActive: true,
        isExpired: false,
        daysRemaining: 30,
      );
    }

    final expiryDateStr = metadata['trial_expiry'] as String?;
    final isTrialActive = metadata['trial_active'] as bool? ?? false;

    if (expiryDateStr == null || !isTrialActive) {
      return SubscriptionStatus(
        isActive: true,
        isExpired: false,
        daysRemaining: 30,
      );
    }

    final expiryDate = DateTime.tryParse(expiryDateStr);
    if (expiryDate == null) {
      return SubscriptionStatus(
        isActive: true,
        isExpired: false,
        daysRemaining: 30,
      );
    }

    final now = DateTime.now();
    final isExpired = now.isAfter(expiryDate);
    final daysRemaining = expiryDate.difference(now).inDays;

    return SubscriptionStatus(
      isActive: !isExpired,
      isExpired: isExpired,
      daysRemaining: daysRemaining.clamp(0, daysRemaining),
      expiryDate: expiryDate,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionStatus> {
  final AuthService _authService;

  SubscriptionNotifier(this._authService)
      : super(SubscriptionStatus.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        state = SubscriptionStatus(
          isActive: true,
          isExpired: false,
          daysRemaining: 30,
        );
        return;
      }

      state = SubscriptionStatus.fromUserMetadata(user.userMetadata);
    } catch (e) {
      state = SubscriptionStatus.error(e.toString());
    }
  }

  Future<void> refresh() async {
    state = SubscriptionStatus.loading();
    await _initialize();
  }

  void markAsExpired() {
    state = SubscriptionStatus(
      isActive: false,
      isExpired: true,
      daysRemaining: 0,
      expiryDate: state.expiryDate,
    );
  }
}

final subscriptionStatusProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionStatus>((ref) {
  return SubscriptionNotifier(AuthService.instance);
});
