// Example usage of TrialCounterWidget
//
// 1. Basic usage in your screen:
//
//    import 'package:yourapp/features/subscription/widgets/trial_counter.dart';
//
//    class YourScreen extends ConsumerWidget {
//      @override
//      Widget build(BuildContext context, WidgetRef ref) {
//        return Scaffold(
//          body: CustomScrollView(
//            slivers: [
//              SliverPadding(
//                padding: const EdgeInsets.all(16),
//                sliver: SliverToBoxAdapter(
//                  child: TrialCounterWidget(),
//                ),
//              ),
//              // ... rest of your content
//            ],
//          ),
//        );
//      }
//    }
//
// 2. Features included:
//    - Displays remaining trial days with "7 dias grátis" or "X dias restantes"
//    - Visual progress bar showing trial progress
//    - Color-coded by days remaining:
//      * Green (#10b981) for 7+ days
//      * Yellow (#f59e0b) for 3-6 days
//      * Red (#ef4444) for 1-2 days
//    - Shows expiration date (e.g., "Expira em 25/Apr")
//    - Auto-refreshes when app is resumed (24-hour refresh)
//    - Graceful loading state with spinner
//    - Error state with retry button
//    - Expired state with "Sua trial expirou" message
//    - "Estender por 7 dias" button (if trial is active)
//    - "Upgrade Agora" button (if trial is expired or can't extend)
//    - Tap anywhere on card to navigate to paywall
//
// 3. Integration points:
//    - Uses subscriptionNotifierProvider from features/subscription/providers.dart
//    - Requires existing SubscriptionStatus model
//    - Requires UserSubscription model with daysRemaining, isExpired, isTrial
//    - Navigates to /paywall route on upgrade actions
//    - Shows SnackBar notifications for trial extension results
//
// 4. Customization:
//    If you need to customize colors, dates, or labels, edit:
//    - _getProgressColor() method for color scheme
//    - DateFormat in _buildActiveTrialCard() for date format
//    - Button labels in the widget
//
// 5. API Integration (in providers.dart):
//    - extendTrial() API endpoint: POST /api/subscription/extend-trial
//    - getSubscription() API endpoint: GET /api/user/subscription
//    - Both endpoints should return updated UserSubscription object
