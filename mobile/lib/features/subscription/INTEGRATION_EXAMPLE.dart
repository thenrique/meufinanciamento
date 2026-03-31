// Example integration with GoRouter
// Add this to your router configuration file (e.g., lib/core/router.dart)

// Import
// import 'package:meufinanciamento/features/subscription/screens/paywall_screen.dart';

// Add to your routes:
// GoRoute(
//   path: '/subscription/paywall',
//   builder: (context, state) => const PaywallScreen(),
// ),

// Usage from other screens:
// context.push('/subscription/paywall');

// Or in a check for trial expiration:
// void _checkTrialStatus(WidgetRef ref) {
//   final subscriptionStatus = ref.watch(subscriptionStatusProvider);
//   if (subscriptionStatus.status == SubscriptionStatus.trialExpired) {
//     context.push('/subscription/paywall');
//   }
// }
