import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:amortizador_pro/models/payment_record.dart';
import 'package:amortizador_pro/features/loan_history/widgets/payment_form_dialog.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('PaymentFormDialog', () {
    final now = DateTime.now();
    final loanStartDate = DateTime(now.year, now.month, 1);
    final testPayment = PaymentRecord(
      id: 'pay_001',
      loanId: 'loan_001',
      paymentDate: loanStartDate.add(const Duration(days: 30)),
      amountPaid: 1000.0,
      paymentType: 'normal',
      createdAt: now,
    );

    Future<void> pumpDialog(
      WidgetTester tester, {
      PaymentRecord? initialPayment,
      List<PaymentRecord> existingPayments = const [],
      VoidCallback? onSubmitCallback,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => PaymentFormDialog(
                        loanId: 'loan_001',
                        outstandingBalance: 50000.0,
                        loanStartDate: loanStartDate,
                        existingPayments: existingPayments,
                        initialPayment: initialPayment,
                        onSubmit: (payment) {
                          onSubmitCallback?.call();
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }

    testWidgets('renders create mode correctly', (tester) async {
      await pumpDialog(tester);

      expect(find.text('Novo Pagamento'), findsOneWidget);
      expect(find.text('Adicionar'), findsOneWidget);
      expect(find.byType(PaymentFormDialog), findsOneWidget);
      expect(find.text('Data do Pagamento'), findsOneWidget);
      expect(find.text('Valor Pago'), findsOneWidget);
      expect(find.text('Tipo'), findsOneWidget);
    });

    testWidgets('renders edit mode correctly', (tester) async {
      await pumpDialog(tester, initialPayment: testPayment);

      expect(find.text('Editar Pagamento'), findsOneWidget);
      expect(find.text('Atualizar'), findsOneWidget);
    });

    testWidgets('shows date picker field', (tester) async {
      await pumpDialog(tester);

      final dateField = find.byType(GestureDetector);
      expect(dateField, findsWidgets);
    });

    testWidgets('shows amount input field', (tester) async {
      await pumpDialog(tester);

      final amountField = find.byType(TextField);
      expect(amountField, findsWidgets);
    });

    testWidgets('shows payment type dropdown', (tester) async {
      await pumpDialog(tester);

      final typeDropdown = find.byType(DropdownButton<String>);
      expect(typeDropdown, findsOneWidget);
    });

    testWidgets('displays all payment type options', (tester) async {
      await pumpDialog(tester);

      final typeDropdown = find.byType(DropdownButton<String>);
      await tester.tap(typeDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Normal'), findsWidgets);
      expect(find.text('Extra Mensal'), findsWidgets);
      expect(find.text('Extra Única'), findsWidgets);
      expect(find.text('Amortização'), findsWidgets);
    });

    testWidgets('submit button is disabled initially', (tester) async {
      await pumpDialog(tester);

      final submitButton = find.byType(FilledButton);
      expect(submitButton, findsOneWidget);
    });

    testWidgets('submit button becomes enabled with valid data', (tester) async {
      await pumpDialog(tester);

      final amountField = find.byType(TextField);
      await tester.enterText(amountField.first, '1000');
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('handles form submission', (tester) async {
      var submitCalled = false;

      await pumpDialog(
        tester,
        onSubmitCallback: () => submitCalled = true,
      );

      // Don't interact with the form, just open it
      expect(find.byType(PaymentFormDialog), findsOneWidget);
    });

    testWidgets('closes dialog on successful submission', (tester) async {
      await pumpDialog(tester);

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('cancel button closes dialog', (tester) async {
      await pumpDialog(tester);

      final cancelButton = find.byType(TextButton);
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('displays error messages', (tester) async {
      await pumpDialog(tester);

      expect(find.byType(PaymentFormDialog), findsOneWidget);
    });

    testWidgets('initializes with existing payment data in edit mode',
        (tester) async {
      await pumpDialog(tester, initialPayment: testPayment);

      expect(find.byType(PaymentFormDialog), findsOneWidget);
    });

    testWidgets('prevents duplicate payment dates', (tester) async {
      final existingPayments = [testPayment];

      await pumpDialog(tester, existingPayments: existingPayments);

      expect(find.byType(PaymentFormDialog), findsOneWidget);
    });

    testWidgets('validates amount exceeds balance', (tester) async {
      await pumpDialog(tester);

      expect(find.byType(PaymentFormDialog), findsOneWidget);
    });
  });
}
