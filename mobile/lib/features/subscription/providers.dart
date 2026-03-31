import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/user_subscription.dart';
import '../../models/subscription_status.dart';

// API constants
const String apiBaseUrl = 'http://localhost:8000';
const String getSubscriptionUrl = '$apiBaseUrl/api/user/subscription';
const String extendTrialUrl = '$apiBaseUrl/api/subscription/extend-trial';
const String cancelSubscriptionUrl = '$apiBaseUrl/api/subscription';

/// Exception thrown when a subscription operation fails.
class SubscriptionException implements Exception {
  SubscriptionException(this.message, [this.originalError]);

  final String message;
  final Object? originalError;

  @override
  String toString() => message;
}

/// Manages subscription state with async operations.
///
/// Handles extending trial and cancelling subscription with automatic refetch.
class SubscriptionNotifier extends StateNotifier<AsyncValue<UserSubscription>> {
  /// Creates a new SubscriptionNotifier.
  ///
  /// Initial state is loading. Call [_fetchSubscription] to load data.
  SubscriptionNotifier({
    required ApiClient api,
  })  : _api = api,
        super(const AsyncValue.loading()) {
    _initialize();
  }

  final ApiClient _api;

  /// Initializes the notifier by fetching the subscription.
  void _initialize() {
    _fetchSubscription();
  }

  /// Fetches the subscription from the API.
  Future<void> _fetchSubscription() async {
    try {
      state = const AsyncValue.loading();
      final subscription = await _api.getSubscription();
      state = AsyncValue.data(subscription);
    } catch (e, stackTrace) {
      final message = 'Erro ao carregar assinatura: ${_errorMessage(e)}';
      debugPrint('[SubscriptionNotifier] $message');
      state = AsyncValue.error(
        SubscriptionException(message, e),
        stackTrace,
      );
    }
  }

  /// Extends the trial by making a POST request to the API.
  ///
  /// Returns the updated [UserSubscription] after extension.
  ///
  /// Throws [SubscriptionException] if the API call fails.
  Future<UserSubscription> extendTrial() async {
    try {
      final subscription = await _api.extendTrial();
      state = AsyncValue.data(subscription);
      return subscription;
    } catch (e, stackTrace) {
      final message = 'Erro ao estender período de teste: ${_errorMessage(e)}';
      debugPrint('[SubscriptionNotifier] $message');
      final exception = SubscriptionException(message, e);
      state = AsyncValue.error(exception, stackTrace);
      throw exception;
    }
  }

  /// Cancels the subscription by making a DELETE request to the API.
  ///
  /// Refetches the subscription after cancellation.
  ///
  /// Throws [SubscriptionException] if the API call fails.
  Future<void> cancelSubscription() async {
    try {
      await _api.cancelSubscription();
      await _fetchSubscription();
    } catch (e, stackTrace) {
      final message = 'Erro ao cancelar assinatura: ${_errorMessage(e)}';
      debugPrint('[SubscriptionNotifier] $message');
      final exception = SubscriptionException(message, e);
      state = AsyncValue.error(exception, stackTrace);
      throw exception;
    }
  }

  /// Extracts a user-friendly error message from an exception.
  String _errorMessage(Object error) {
    if (error is SubscriptionException) return error.message;
    return friendlyNetworkError(error);
  }
}

/// Provider for subscription data with API integration.
///
/// Fetches subscription information from the API with 1-minute TTL cache.
/// Invalidates on user login for fresh data.
///
/// Usage:
/// ```dart
/// final subscription = ref.watch(subscriptionProvider);
/// subscription.when(
///   data: (sub) => Text('Days: ${sub.daysRemaining}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, _) => Text('Error: $err'),
/// );
/// ```
final subscriptionProvider = FutureProvider<UserSubscription>((ref) async {
  final api = ref.watch(apiProvider);
  return api.getSubscription();
});

/// Provider for subscription status computed from subscription data.
///
/// Derives subscription status information including days remaining,
/// active/expired status, trial information, etc.
///
/// Usage:
/// ```dart
/// final status = ref.watch(subscriptionStatusProvider);
/// status.when(
///   data: (status) => Text('Days left: ${status.daysRemaining}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, _) => Text('Error: $err'),
/// );
/// ```
final subscriptionStatusProvider = FutureProvider<SubscriptionStatus>((ref) async {
  final subscription = await ref.watch(subscriptionProvider.future);
  return SubscriptionStatus.fromSubscription(subscription);
});

/// Provider for subscription notifier with state management.
///
/// Manages subscription operations: extend trial and cancel subscription.
/// Automatically refetches data after operations.
///
/// Usage:
/// ```dart
/// final notifier = ref.read(subscriptionNotifierProvider.notifier);
/// await notifier.extendTrial();
/// final state = ref.watch(subscriptionNotifierProvider);
/// ```
final subscriptionNotifierProvider = StateNotifierProvider<
    SubscriptionNotifier,
    AsyncValue<UserSubscription>>((ref) {
  return SubscriptionNotifier(
    api: ref.watch(apiProvider),
  );
});

/// Provider for easy-access trial status information.
///
/// Derived from the main subscription notifier, provides convenient
/// access to trial-specific information.
///
/// Usage:
/// ```dart
/// final trial = ref.watch(trialNotifierProvider);
/// trial.when(
///   data: (status) => Text('Trial ends in ${status.daysRemaining} days'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, _) => Text('Error: $err'),
/// );
/// ```
final trialNotifierProvider = Provider<AsyncValue<SubscriptionStatus>>((ref) {
  final subscriptionAsync = ref.watch(subscriptionNotifierProvider);
  return subscriptionAsync.whenData(
    (subscription) => SubscriptionStatus.fromSubscription(subscription),
  );
});

// API Provider reference
final apiProvider = Provider((ref) => ApiClient.instance);
