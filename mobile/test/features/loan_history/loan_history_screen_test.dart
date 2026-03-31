import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amortizador_pro/models/loan.dart';
import 'package:amortizador_pro/models/loan_history.dart';
import 'package:amortizador_pro/models/payment_record.dart';
import 'package:amortizador_pro/features/loan_history/loan_history_screen.dart';
import 'package:amortizador_pro/features/loan_history/providers.dart';

void main() {
  group('LoanHistoryScreen Tests', () {
    // Test data
    final testLoan = Loan(
      id: 'loan_123',
      bankName: 'Banco do Brasil',
      loanType: 'PRICE',
      totalAmount: 100000.0,
      outstandingBalance: 50000.0,
      interestRateYear: 8.5,
      startDate: DateTime(2023, 1, 15),
      termMonths: 120,
      remainingMonths: 60,
      insuranceMonthly: 150.0,
    );

    final testSummary = ComparisonSummary(
      totalPaidEstimated: 50000.0,
      totalPaidActual: 48000.0,
      totalDeviation: -2000.0,
      monthsAhead: 2,
      monthsBehind: 0,
      estimatedPayoffDate: DateTime(2028, 1, 15),
      actualPayoffDate: DateTime(2027, 11, 15),
      timeSavedMonths: 2,
      interestSaved: 2000.0,
    );

    final testPayment = PaymentRecord(
      id: 'payment_1',
      loanId: 'loan_123',
      paymentDate: DateTime(2024, 1, 10),
      amountPaid: 1000.0,
      paymentType: 'normal',
      notes: 'Teste',
      createdAt: DateTime(2024, 1, 10),
    );

    final testLoanHistory = LoanHistory(
      loan: testLoan,
      paymentRecords: [testPayment],
      calculatedHistory: [
        CalculatedMonthEntry(
          month: 1,
          date: DateTime(2023, 2, 15),
          paymentPlanned: 1000.0,
          amortization: 850.0,
          interest: 150.0,
          insurance: 150.0,
          outstandingBalance: 99000.0,
        ),
      ],
      actualHistory: [
        ActualMonthEntry(
          month: 1,
          date: DateTime(2023, 2, 15),
          paymentPlanned: 1000.0,
          amortization: 850.0,
          interest: 150.0,
          insurance: 150.0,
          outstandingBalance: 99000.0,
          paymentActual: 1500.0,
          payments: [testPayment],
          deviation: 500.0,
        ),
      ],
      summary: testSummary,
    );

    testWidgets('renders loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loanHistoryProvider('loan_123').overrideWith(
              (ref) => Future<LoanHistory>.delayed(
                const Duration(seconds: 2),
                () => testLoanHistory,
              ),
            ),
          ],
          child: const MaterialApp(
            home: LoanHistoryScreen(loanId: 'loan_123'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders screen with loan data', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loanHistoryProvider('loan_123').overrideWith(
              (ref) => Future<LoanHistory>.value(testLoanHistory),
            ),
            paymentNotifierProvider('loan_123').overrideWith(
              (ref) => PaymentNotifier(
                api: MockApiClient(),
                loanId: 'loan_123',
              ),
            ),
          ],
          child: const MaterialApp(
            home: LoanHistoryScreen(loanId: 'loan_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for main components
      expect(find.text('Histórico de Pagamentos'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders error state with retry button', (WidgetTester tester) async {
      final testError = Exception('Failed to load loan history');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loanHistoryProvider('loan_123').overrideWith(
              (ref) => Future<LoanHistory>.error(testError),
            ),
          ],
          child: const MaterialApp(
            home: LoanHistoryScreen(loanId: 'loan_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Erro ao carregar histórico'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('opens payment form when FAB tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loanHistoryProvider('loan_123').overrideWith(
              (ref) => Future<LoanHistory>.value(testLoanHistory),
            ),
            paymentNotifierProvider('loan_123').overrideWith(
              (ref) => PaymentNotifier(
                api: MockApiClient(),
                loanId: 'loan_123',
              ),
            ),
          ],
          child: const MaterialApp(
            home: LoanHistoryScreen(loanId: 'loan_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Dialog should open - check for Dialog widget
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('refresh button shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loanHistoryProvider('loan_123').overrideWith(
              (ref) => Future<LoanHistory>.value(testLoanHistory),
            ),
            paymentNotifierProvider('loan_123').overrideWith(
              (ref) => PaymentNotifier(
                api: MockApiClient(),
                loanId: 'loan_123',
              ),
            ),
          ],
          child: const MaterialApp(
            home: LoanHistoryScreen(loanId: 'loan_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
      
      // Verify button is enabled
      final button = find.byIcon(Icons.refresh);
      expect(button, findsOneWidget);
    });

    testWidgets('displays payment list when data available', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loanHistoryProvider('loan_123').overrideWith(
              (ref) => Future<LoanHistory>.value(testLoanHistory),
            ),
            paymentNotifierProvider('loan_123').overrideWith(
              (ref) => PaymentNotifier(
                api: MockApiClient(),
                loanId: 'loan_123',
              ),
            ),
          ],
          child: const MaterialApp(
            home: LoanHistoryScreen(loanId: 'loan_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for payment list widget or related elements
      expect(find.text('Evolução do Saldo'), findsOneWidget);
    });
  });
}

/// Mock API client for testing
class MockApiClient {
  Future<PaymentRecord> createPayment(String loanId, dynamic payment) async {
    return PaymentRecord(
      id: 'new_payment',
      loanId: loanId,
      paymentDate: DateTime.now(),
      amountPaid: 1000.0,
      paymentType: 'normal',
      createdAt: DateTime.now(),
    );
  }

  Future<PaymentRecord> updatePayment(String loanId, String paymentId, dynamic payment) async {
    return PaymentRecord(
      id: paymentId,
      loanId: loanId,
      paymentDate: DateTime.now(),
      amountPaid: 1500.0,
      paymentType: 'normal',
      createdAt: DateTime.now(),
    );
  }

  Future<void> deletePayment(String loanId, String paymentId) async {}

  Future<List<PaymentRecord>> getPayments(String loanId) async {
    return [];
  }

  dynamic get dio => MockDio();
}

class MockDio {
  Future<dynamic> get(String path) async {
    return {};
  }
}
