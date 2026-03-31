# Subscription Feature

This feature handles subscription and trial management for the Meu Financiamento app.

## Screens

### PaywallScreen
Displays the trial expiration paywall with:
- **Header**: Gradient navy background with expiration message
- **Benefits List**: Checkmark icons for subscription features
- **Pricing**: Monthly subscription price with no-contract messaging
- **Actions**:
  - "Ativar Assinatura" (Primary) - Opens Stripe checkout
  - "Continuar como visitante" (Secondary) - Continue with limited features
  - "Cancelar" (Tertiary) - Go back
- **Reactivation Info**: Message about reactivating within 30 days
- **Error Handling**: Network error recovery with retry button

## Providers

### subscriptionStatusProvider
StateProvider that tracks the current subscription status:
- `active`: User has active paid subscription
- `trialActive`: User is in active trial period
- `trialExpired`: User's trial has expired
- `cancelled`: User cancelled subscription
- `unknown`: Status couldn't be determined

### reactivateSubscriptionProvider
FutureProvider for handling subscription reactivation (future integration with backend).

## Design System
- **Colors**: Navy (#1E3A5F) primary, green (#10B981) for actions
- **Spacing**: Uses Gap widget for consistent spacing
- **Typography**: Google Fonts (Inter)
- **Animations**: Smooth transitions (implemented in button states)

## Future Integrations

1. **Stripe Checkout**: Link the "Ativar Assinatura" button to Stripe checkout
2. **API Integration**: Connect reactivateSubscriptionProvider to backend
3. **User Data**: Fetch user email and subscription details from auth service
4. **Analytics**: Track paywall views, button clicks, conversions

## Usage

```dart
import 'package:meufinanciamento/features/subscription/screens/paywall_screen.dart';

// In router
GoRoute(
  path: '/subscription/paywall',
  builder: (context, state) => const PaywallScreen(),
)

// From another screen
context.push('/subscription/paywall');
```
