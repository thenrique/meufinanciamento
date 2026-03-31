# Subscription State Management with Riverpod

This document describes the Riverpod providers for managing user subscription state in the Amortizador Pro mobile app.

## Overview

The subscription module provides comprehensive state management for:
- Fetching and caching user subscription data
- Extending trial periods
- Cancelling subscriptions
- Computing subscription status information
- Accessing trial-specific information

## Models

### UserSubscription
Represents the complete subscription data for a user.

**Properties:**
- `id`: Unique subscription identifier
- `userId`: Associated user ID
- `subscriptionType`: Type of subscription ('free', 'trial', 'premium')
- `status`: Current status ('active', 'expired', 'cancelled', 'pending')
- `startDate`: When subscription started
- `endDate`: When subscription expires
- `trialEndDate`: When trial period ends (nullable)
- `daysRemaining`: Days until expiration
- `isActive`: Whether subscription is currently active
- `isExpired`: Whether subscription has expired
- `isTrial`: Whether currently in trial period
- `autoRenew`: Whether subscription auto-renews
- `price`: Subscription cost (nullable)
- `currency`: Currency code (nullable)
- `nextBillingDate`: Next billing date (nullable)

### SubscriptionStatus
Computed subscription status information derived from UserSubscription.

**Properties:**
- `daysRemaining`: Days until expiration
- `isActive`, `isExpired`, `isTrial`: Status flags
- `subscriptionType`: Type of subscription
- `status`: Current status
- `expirationDate`: Expiration date
- `trialEndDate`: Trial end date (nullable)

**Helpers:**
- `shouldExtendTrial`: True if trial is ending soon (< 7 days) and not expired
- `shouldUpgrade`: True if subscription is expired
- `statusLabel`: User-friendly status string in Portuguese

## Providers

### 1. subscriptionProvider (FutureProvider)
Fetches subscription data from the API with automatic caching.

**Endpoint:** `GET /api/user/subscription`

**Usage:**
```dart
final subscription = ref.watch(subscriptionProvider);

subscription.when(
  data: (sub) => Text('Days remaining: ${sub.daysRemaining}'),
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

**Cache Behavior:**
- Automatically caches for 1 minute (Riverpod default FutureProvider)
- Refetches on provider invalidation or dependency changes

### 2. subscriptionStatusProvider (FutureProvider)
Computed subscription status derived from the subscription provider.

**Endpoint:** None (computed from subscriptionProvider)

**Usage:**
```dart
final status = ref.watch(subscriptionStatusProvider);

status.when(
  data: (status) => Column(
    children: [
      Text('Status: ${status.statusLabel}'),
      Text('Days left: ${status.daysRemaining}'),
      if (status.shouldExtendTrial)
        ElevatedButton(
          onPressed: () => ref.read(subscriptionNotifierProvider.notifier).extendTrial(),
          child: const Text('Extend Trial'),
        ),
    ],
  ),
  loading: () => const CircularProgressIndicator(),
  error: (err, _) => Text('Error: $err'),
);
```

### 3. subscriptionNotifierProvider (StateNotifierProvider)
Manages mutable subscription state with operations for extending trials and cancelling subscriptions.

**Operations:**
- `extendTrial()`: POST `/api/subscription/extend-trial`
  - Extends the trial period
  - Returns updated UserSubscription
  - Throws SubscriptionException on failure
  
- `cancelSubscription()`: DELETE `/api/subscription`
  - Cancels the active subscription
  - Automatically refetches subscription data
  - Throws SubscriptionException on failure

**Usage:**
```dart
// Watch current state
final subAsync = ref.watch(subscriptionNotifierProvider);

// Access notifier for operations
final notifier = ref.read(subscriptionNotifierProvider.notifier);

// Extend trial
try {
  final updated = await notifier.extendTrial();
  // Show success message
} on SubscriptionException catch (e) {
  // Handle error: e.message
}

// Cancel subscription
try {
  await notifier.cancelSubscription();
  // Show success message
} on SubscriptionException catch (e) {
  // Handle error: e.message
}
```

### 4. trialNotifierProvider (Provider)
Derived provider for easy access to trial status information.

**Usage:**
```dart
final trial = ref.watch(trialNotifierProvider);

trial.when(
  data: (status) => Text('Trial: ${status.daysRemaining} days'),
  loading: () => const CircularProgressIndicator(),
  error: (err, _) => Text('Error: $err'),
);
```

## Error Handling

All providers include comprehensive error handling with user-friendly Portuguese error messages.

### SubscriptionException
Custom exception for subscription operations.

**Properties:**
- `message`: User-friendly error message in Portuguese
- `originalError`: Original exception that caused the error

**Example:**
```dart
try {
  await notifier.extendTrial();
} on SubscriptionException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
}
```

## Common Patterns

### Showing Loading and Error States
```dart
final subscription = ref.watch(subscriptionProvider);

return subscription.when(
  data: (sub) => Text('Days: ${sub.daysRemaining}'),
  loading: () => const CircularProgressIndicator(),
  error: (error, stackTrace) => ErrorWidget(error: error),
);
```

### Performing Operations with Loading State
```dart
final subAsync = ref.watch(subscriptionNotifierProvider);
final notifier = ref.read(subscriptionNotifierProvider.notifier);

return AsyncValueWidget(
  value: subAsync,
  data: (sub) => ElevatedButton(
    onPressed: () async {
      try {
        await notifier.extendTrial();
      } catch (e) {
        // Handle error
      }
    },
    child: const Text('Extend Trial'),
  ),
);
```

### Invalidating Cache
```dart
// Manually refetch subscription data
ref.refresh(subscriptionProvider);

// Also refresh computed status
ref.refresh(subscriptionStatusProvider);
```

## Integration with User Login

To refetch subscription data when a user logs in:

```dart
// In your auth provider or login handler
ref.refresh(subscriptionProvider);
ref.refresh(subscriptionNotifierProvider);
```

## API Endpoints

All endpoints use the base URL configured in `ApiEndpoints.baseUrl`:

- **Get Subscription:** `GET /api/user/subscription`
- **Extend Trial:** `POST /api/subscription/extend-trial`
- **Cancel Subscription:** `DELETE /api/subscription`

Authentication is handled automatically via the `_AuthInterceptor` in ApiClient, which adds the Bearer token from Supabase.

## File Structure

```
mobile/
├── lib/
│   ├── core/
│   │   ├── api_client.dart (contains ApiClient with subscription methods)
│   │   └── constants.dart (contains ApiEndpoints)
│   ├── models/
│   │   ├── user_subscription.dart (UserSubscription model)
│   │   └── subscription_status.dart (SubscriptionStatus model)
│   └── features/
│       └── subscription/
│           ├── providers.dart (all providers and state management)
│           ├── screens/
│           └── widgets/
```

## Testing

Example widget test:

```dart
testWidgets('Show trial extension button', (WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderContainer(
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (context, ref, _) {
            final status = ref.watch(subscriptionStatusProvider);
            return status.when(
              data: (status) => status.shouldExtendTrial
                  ? const Text('Extend Trial')
                  : const SizedBox(),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox(),
            );
          }),
        ),
      ),
      overrides: [
        subscriptionProvider.overrideWithValue(
          AsyncValue.data(
            UserSubscription(
              id: 'test-id',
              userId: 'user-id',
              subscriptionType: 'trial',
              status: 'active',
              startDate: DateTime.now(),
              endDate: DateTime.now().add(Duration(days: 5)),
              trialEndDate: DateTime.now().add(Duration(days: 5)),
              daysRemaining: 5,
              isActive: true,
              isExpired: false,
              isTrial: true,
              autoRenew: false,
              price: null,
              currency: null,
              nextBillingDate: null,
            ),
          ),
        ),
      ],
    ),
  );

  expect(find.text('Extend Trial'), findsOneWidget);
});
```

## Notes

- All API calls include automatic authentication via Supabase Bearer token
- Network errors are automatically translated to user-friendly Portuguese messages
- Loading states are handled via AsyncValue from Riverpod
- The subscription notifier automatically refetches data after operations
- Trial extension and cancellation operations throw SubscriptionException for explicit error handling
