import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/simulator/simulator_screen.dart';
import '../features/loan_history/loan_history_screen.dart';
import '../features/loans/loan_form_screen.dart';
import '../features/report/report_screen.dart';
import '../features/report/paywall_screen.dart';
import '../features/settings/settings_screen.dart';
import 'subscription_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final isAuthenticated =
          Supabase.instance.client.auth.currentUser != null;
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isPaywall = state.matchedLocation == '/paywall';
      final isSettings = state.matchedLocation == '/settings';

      // Redirect to onboarding if not authenticated (except onboarding itself)
      if (!isAuthenticated && !isOnboarding) return '/onboarding';

      // Redirect to dashboard if authenticated and on onboarding
      if (isAuthenticated && isOnboarding) return '/dashboard';

      // Check subscription for protected routes
      if (isAuthenticated && !isPaywall && !isSettings) {
        final subscriptionStatus = ref.watch(subscriptionStatusProvider);

        // Allow all routes until subscription status is loaded
        if (subscriptionStatus.isLoading) {
          return null;
        }

        // Protected routes that require active subscription
        final protectedRoutes = [
          '/dashboard',
          '/loans',
          '/simulator',
          '/history',
          '/report',
        ];

        final isProtectedRoute = protectedRoutes
            .any((route) => state.matchedLocation.startsWith(route));

        // If subscription is expired and accessing a protected route, redirect to paywall
        if (subscriptionStatus.isExpired && isProtectedRoute) {
          return '/paywall';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/history/:loanId',
            name: 'loanHistory',
            builder: (context, state) => LoanHistoryScreen(
              loanId: state.pathParameters['loanId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/simulator/:loanId',
        name: 'simulator',
        builder: (context, state) {
          final loanId = state.pathParameters['loanId']!;
          return SimulatorScreen(loanId: loanId);
        },
      ),
      GoRoute(
        path: '/loans/new',
        name: 'loan-new',
        builder: (context, state) => const LoanFormScreen(),
      ),
      GoRoute(
        path: '/loans/:id/edit',
        name: 'loan-edit',
        builder: (context, state) {
          final loanId = state.pathParameters['id']!;
          return LoanFormScreen(loanId: loanId);
        },
      ),
      GoRoute(
        path: '/report/:loanId',
        name: 'report',
        builder: (context, state) {
          final loanId = state.pathParameters['loanId']!;
          return ReportScreen(loanId: loanId);
        },
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
    ],
  );
});

class _AppShell extends StatefulWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;

  static const _tabs = ['/dashboard', '/settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          context.go(_tabs[index]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}
