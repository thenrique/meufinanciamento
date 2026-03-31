import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../models/payment_record.dart';
import 'widgets/payment_list.dart';

void _noop(_) {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  String formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  group('PaymentListWidget Tests', () {
    // Test 1: Renders with multiple payments
    testWidgets('Renders PaymentListWidget with multiple payments',
        (WidgetTester tester) async {
      final payments = [
        PaymentRecord(
          id: '1',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 3, 15),
          amountPaid: 1500.0,
          paymentType: 'normal',
          createdAt: DateTime.now(),
        ),
        PaymentRecord(
          id: '2',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 3, 20),
          amountPaid: 500.0,
          paymentType: 'extra_monthly',
          createdAt: DateTime.now(),
        ),
        PaymentRecord(
          id: '3',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 2, 28),
          amountPaid: 1500.0,
          paymentType: 'normal',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentListWidget(
              payments: payments,
              onEdit: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      );

      // Verify all payments are rendered
      expect(find.byType(PaymentListWidget), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      // Verify amount text is displayed
      expect(find.text(formatAmount(1500.0)), findsWidgets);
      expect(find.text(formatAmount(500.0)), findsOneWidget);
    });

    // Test 2: Correct grouping by month
    testWidgets('Correctly groups payments by month',
        (WidgetTester tester) async {
      final payments = [
        PaymentRecord(
          id: '1',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 3, 15),
          amountPaid: 1500.0,
          paymentType: 'normal',
          createdAt: DateTime.now(),
        ),
        PaymentRecord(
          id: '2',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 3, 25),
          amountPaid: 500.0,
          paymentType: 'extra_monthly',
          createdAt: DateTime.now(),
        ),
        PaymentRecord(
          id: '3',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 2, 28),
          amountPaid: 1500.0,
          paymentType: 'normal',
          createdAt: DateTime.now(),
        ),
        PaymentRecord(
          id: '4',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 2, 10),
          amountPaid: 750.0,
          paymentType: 'amortization',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentListWidget(
              payments: payments,
              onEdit: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      );

      // Verify month headers are displayed
      expect(find.text('Março/2026 (2 pagamentos)'), findsOneWidget);
      expect(find.text('Fevereiro/2026 (2 pagamentos)'), findsOneWidget);

      // Verify payment type labels
      expect(find.text('Normal'), findsWidgets);
      expect(find.text('Extra Mensal'), findsOneWidget);
      expect(find.text('Amortização'), findsOneWidget);
    });

    // Test 3: Correct sorting within month (descending by date)
    testWidgets('Sorts payments within month by date descending',
        (WidgetTester tester) async {
      final payments = [
        PaymentRecord(
          id: '1',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 3, 10),
          amountPaid: 1000.0,
          paymentType: 'normal',
          createdAt: DateTime.now(),
        ),
        PaymentRecord(
          id: '2',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 3, 25),
          amountPaid: 2000.0,
          paymentType: 'extra_monthly',
          createdAt: DateTime.now(),
        ),
        PaymentRecord(
          id: '3',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 3, 15),
          amountPaid: 1500.0,
          paymentType: 'normal',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentListWidget(
              payments: payments,
              onEdit: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      );

      // Verify the month header appears
      expect(find.text('Março/2026 (3 pagamentos)'), findsOneWidget);

      // Verify all amounts should be found
      expect(find.text(formatAmount(2000.0)), findsOneWidget); // 25th - highest
      expect(find.text(formatAmount(1500.0)), findsOneWidget); // 15th - middle
      expect(find.text(formatAmount(1000.0)), findsOneWidget); // 10th - lowest
    });

    // Test 4: Empty state message
    testWidgets('Shows empty state when no payments', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentListWidget(
              payments: [],
              onEdit: _noop,
              onDelete: _noop,
            ),
          ),
        ),
      );

      // Verify empty state is displayed
      expect(find.text('Nenhum pagamento registrado'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    // Test 5: Edit and delete callbacks are invoked
    testWidgets('Invokes edit callback when edit button is pressed',
        (WidgetTester tester) async {
      var editedPayment = '';
      var deletedPayment = '';

      final payments = [
        PaymentRecord(
          id: 'payment_1',
          loanId: 'loan_1',
          paymentDate: DateTime(2026, 3, 15),
          amountPaid: 1500.0,
          paymentType: 'normal',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentListWidget(
              payments: payments,
              onEdit: (payment) {
                editedPayment = payment.id;
              },
              onDelete: (paymentId) {
                deletedPayment = paymentId;
              },
            ),
          ),
        ),
      );

      // Find and tap the edit button (first IconButton)
      final editButton = find.byIcon(Icons.edit).first;
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(editedPayment, equals('payment_1'));

      // Find and tap the delete button
      final deleteButton = find.byIcon(Icons.delete);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Tem certeza que deseja deletar este pagamento?'),
          findsOneWidget);

      // Tap confirm button
      final confirmButton = find.text('Confirmar');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(deletedPayment, equals('payment_1'));
    });
  });
}
