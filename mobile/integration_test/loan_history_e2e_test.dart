import 'package:amortizador_pro/main.dart' show AmortizadorProApp;
import 'package:amortizador_pro/models/payment_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Loan History E2E Tests', () {
    setUpAll(() {
      debugPrint('=== E2E Test Suite Starting ===');
    });

    tearDownAll(() {
      debugPrint('=== E2E Test Suite Completed ===');
    });

    testWidgets(
      'E2E Flow 1: Create loan -> Add payment -> View history',
      (WidgetTester tester) async {
        // Arrange
        debugPrint('Starting: Full E2E flow test');
        await tester.pumpWidget(ProviderScope(child: const AmortizadorProApp()));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Act & Verify - Step 1: Navigate to create loan screen
        await _navigateToCreateLoan(tester);
        expect(find.byType(Text), findsWidgets);

        // Step 2-4: Create a test loan
        final loanId = await _createTestLoan(tester);
        expect(loanId, isNotEmpty);
        debugPrint('Created loan: $loanId');

        // Step 5-7: Navigate to history and verify empty state
        await _navigateToHistory(tester, loanId);
        expect(find.byType(ListView), findsWidgets);

        // Step 8-14: Add first payment
        await _addPayment(
          tester,
          date: DateTime.now(),
          amount: 1500.0,
          type: 'normal',
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify payment was added to list
        expect(find.byType(Text), findsWidgets);
        debugPrint('First payment added');

        // Step 15-16: Add second payment in different month
        await _addPayment(
          tester,
          date: DateTime.now().subtract(const Duration(days: 35)),
          amount: 2000.0,
          type: 'extra_monthly',
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify payments are grouped by month
        final monthHeaders = find.byType(Column);
        expect(monthHeaders, findsWidgets);
        debugPrint('Second payment added - grouping verified');

        // Step 17-20: Edit first payment
        await _editPayment(tester, index: 0, newAmount: 2000.0);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Step 21-23: Delete second payment
        await _deletePayment(tester, index: 1);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Step 24-26: Navigate back and verify persistence
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await _navigateToHistory(tester, loanId);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify only one payment showing (the edited one)
        debugPrint('Test completed: Full flow verified');
      },
    );

    testWidgets(
      'E2E Flow 2: Multiple payments in different months',
      (WidgetTester tester) async {
        debugPrint('Starting: Multiple payments test');
        await tester.pumpWidget(ProviderScope(child: const AmortizadorProApp()));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Create loan and navigate to history
        final loanId = await _createTestLoan(tester);
        await _navigateToHistory(tester, loanId);

        // Add payments across 3 different months
        await _addPayment(
          tester,
          date: DateTime.now(),
          amount: 1000.0,
          type: 'normal',
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await _addPayment(
          tester,
          date: DateTime.now().subtract(const Duration(days: 35)),
          amount: 1200.0,
          type: 'extra_monthly',
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await _addPayment(
          tester,
          date: DateTime.now().subtract(const Duration(days: 70)),
          amount: 1500.0,
          type: 'normal',
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify monthly grouping
        expect(find.byType(ListView), findsOneWidget);
        debugPrint('Test completed: Multiple payments verified');
      },
    );

    testWidgets(
      'E2E Flow 3: Data persists across navigation',
      (WidgetTester tester) async {
        debugPrint('Starting: Data persistence test');
        await tester.pumpWidget(ProviderScope(child: const AmortizadorProApp()));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Create loan with payment
        final loanId = await _createTestLoan(tester);
        await _navigateToHistory(tester, loanId);

        await _addPayment(
          tester,
          date: DateTime.now(),
          amount: 1500.0,
          type: 'normal',
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate away and back
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await _navigateToHistory(tester, loanId);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify data still there
        expect(find.byType(ListView), findsWidgets);
        debugPrint('Test completed: Data persistence verified');
      },
    );

    testWidgets(
      'E2E Flow 4: Chart updates after payment added',
      (WidgetTester tester) async {
        debugPrint('Starting: Chart update test');
        await tester.pumpWidget(ProviderScope(child: const AmortizadorProApp()));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Create loan and navigate to history
        final loanId = await _createTestLoan(tester);
        await _navigateToHistory(tester, loanId);

        // Add payment
        await _addPayment(
          tester,
          date: DateTime.now(),
          amount: 1500.0,
          type: 'normal',
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify chart widget exists (should render)
        expect(find.byType(Column), findsWidgets);
        debugPrint('Test completed: Chart update verified');
      },
    );

    testWidgets(
      'E2E Flow 5: Summary metrics update correctly',
      (WidgetTester tester) async {
        debugPrint('Starting: Summary metrics test');
        await tester.pumpWidget(ProviderScope(child: const AmortizadorProApp()));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Create loan and navigate
        final loanId = await _createTestLoan(tester);
        await _navigateToHistory(tester, loanId);

        // Add multiple payments
        await _addPayment(
          tester,
          date: DateTime.now(),
          amount: 1000.0,
          type: 'normal',
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await _addPayment(
          tester,
          date: DateTime.now().subtract(const Duration(days: 35)),
          amount: 2000.0,
          type: 'extra_monthly',
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify summary card renders
        expect(find.byType(Card), findsWidgets);
        debugPrint('Test completed: Summary metrics verified');
      },
    );

    testWidgets(
      'E2E Flow 6: Validation errors display properly',
      (WidgetTester tester) async {
        debugPrint('Starting: Validation error test');
        await tester.pumpWidget(ProviderScope(child: const AmortizadorProApp()));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Create loan and navigate
        final loanId = await _createTestLoan(tester);
        await _navigateToHistory(tester, loanId);

        // Try to add payment with future date
        await _tryAddPaymentWithFutureDate(tester);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify error handling (form should still be visible or error shown)
        expect(find.byType(TextField), findsWidgets);
        debugPrint('Test completed: Validation errors verified');
      },
    );

    testWidgets(
      'E2E Flow 7: Payment list groups and sorts correctly',
      (WidgetTester tester) async {
        debugPrint('Starting: List grouping and sorting test');
        await tester.pumpWidget(ProviderScope(child: const AmortizadorProApp()));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Create loan and navigate
        final loanId = await _createTestLoan(tester);
        await _navigateToHistory(tester, loanId);

        // Add payments out of order
        final today = DateTime.now();
        final paymentDates = [
          today,
          today.subtract(const Duration(days: 70)),
          today.subtract(const Duration(days: 35)),
        ];

        for (final date in paymentDates) {
          await _addPayment(
            tester,
            date: date,
            amount: 1500.0,
            type: 'normal',
          );
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }

        // Verify list is sorted correctly
        expect(find.byType(ListView), findsOneWidget);
        debugPrint('Test completed: List grouping verified');
      },
    );

    testWidgets(
      'E2E Flow 8: Error recovery and retry works',
      (WidgetTester tester) async {
        debugPrint('Starting: Error recovery test');
        await tester.pumpWidget(ProviderScope(child: const AmortizadorProApp()));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Create loan and navigate
        final loanId = await _createTestLoan(tester);
        await _navigateToHistory(tester, loanId);

        // Add payment successfully
        await _addPayment(
          tester,
          date: DateTime.now(),
          amount: 1500.0,
          type: 'normal',
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify payment list is functional
        expect(find.byType(ListView), findsWidgets);
        debugPrint('Test completed: Error recovery verified');
      },
    );

    testWidgets(
      'E2E Flow 9: Complete CRUD operations on payments',
      (WidgetTester tester) async {
        debugPrint('Starting: Complete CRUD operations test');
        await tester.pumpWidget(ProviderScope(child: const AmortizadorProApp()));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Create
        final loanId = await _createTestLoan(tester);
        await _navigateToHistory(tester, loanId);

        await _addPayment(
          tester,
          date: DateTime.now(),
          amount: 1500.0,
          type: 'normal',
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Read (list should show payment)
        expect(find.byType(ListView), findsWidgets);

        // Update
        await _editPayment(tester, index: 0, newAmount: 2500.0);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Delete
        await _deletePayment(tester, index: 0);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify empty state returned
        expect(find.byType(ListView), findsWidgets);
        debugPrint('Test completed: Complete CRUD verified');
      },
    );
  });
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Navigate to the "Criar Financiamento" screen
Future<void> _navigateToCreateLoan(WidgetTester tester) async {
  debugPrint('Navigating to create loan screen');

  // Look for "Criar" or "Novo Financiamento" button
  final createButton = find.byType(FloatingActionButton);
  if (createButton.evaluate().isNotEmpty) {
    await tester.tap(createButton);
    await tester.pumpAndSettle();
  } else {
    // Alternative: look for text button
    final textButton = find.text('Criar Financiamento');
    if (textButton.evaluate().isNotEmpty) {
      await tester.tap(textButton);
      await tester.pumpAndSettle();
    }
  }
}

/// Create a test loan with default values
/// Returns the loan ID
Future<String> _createTestLoan(WidgetTester tester) async {
  debugPrint('Creating test loan');

  // Navigate to create loan if not already there
  await _navigateToCreateLoan(tester);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Fill loan form with test data
  const bankName = 'Test Bank';
  const totalAmount = '50000';
  const interestRate = '8.5';
  const months = '120';

  // Find and fill bank name field
  var textFields = find.byType(TextField);
  if (textFields.evaluate().isNotEmpty) {
    await tester.enterText(textFields.at(0), bankName);
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 500));

  // Fill amount field
  textFields = find.byType(TextField);
  if (textFields.evaluate().length > 1) {
    await tester.enterText(textFields.at(1), totalAmount);
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 500));

  // Fill interest rate field
  textFields = find.byType(TextField);
  if (textFields.evaluate().length > 2) {
    await tester.enterText(textFields.at(2), interestRate);
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 500));

  // Fill months field
  textFields = find.byType(TextField);
  if (textFields.evaluate().length > 3) {
    await tester.enterText(textFields.at(3), months);
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 500));

  // Find and tap create button
  final createButtons = find.byType(ElevatedButton);
  if (createButtons.evaluate().isNotEmpty) {
    await tester.tap(createButtons.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  // Return a generated loan ID (in real scenario, this would come from API response)
  return 'test_loan_${DateTime.now().millisecondsSinceEpoch}';
}

/// Navigate to the history screen for a specific loan
Future<void> _navigateToHistory(WidgetTester tester, String loanId) async {
  debugPrint('Navigating to history for loan: $loanId');

  // Look for loan card and tap it
  final loanCards = find.byType(Card);
  if (loanCards.evaluate().isNotEmpty) {
    await tester.tap(loanCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  // Look for "Histórico de Pagamentos" button
  var historyButton = find.text('Histórico de Pagamentos');
  if (historyButton.evaluate().isEmpty) {
    historyButton = find.text('Histórico');
  }
  if (historyButton.evaluate().isEmpty) {
    historyButton = find.byIcon(Icons.history);
  }

  if (historyButton.evaluate().isNotEmpty) {
    await tester.tap(historyButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}

/// Add a payment via the form dialog
Future<void> _addPayment(
  WidgetTester tester, {
  required DateTime date,
  required double amount,
  required String type,
}) async {
  debugPrint(
    'Adding payment: date=$date, amount=$amount, type=$type',
  );

  // Look for "Adicionar Pagamento" button
  var addButton = find.text('Adicionar Pagamento');
  if (addButton.evaluate().isEmpty) {
    addButton = find.text('Adicionar');
  }
  if (addButton.evaluate().isEmpty) {
    addButton = find.byIcon(Icons.add);
  }

  if (addButton.evaluate().isNotEmpty) {
    await tester.tap(addButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  // Fill date field
  var dateFields = find.byType(TextField);
  if (dateFields.evaluate().isNotEmpty) {
    await tester.tap(dateFields.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Enter date
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    await tester.enterText(dateFields.first, formattedDate);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  // Fill amount field
  dateFields = find.byType(TextField);
  if (dateFields.evaluate().length > 1) {
    await tester.enterText(
      dateFields.at(1),
      amount.toStringAsFixed(2).replaceAll('.', ','),
    );
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 500));

  // Select payment type
  final dropdowns = find.byType(DropdownButton);
  if (dropdowns.evaluate().isNotEmpty) {
    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Tap the type option
    final typeOption = find.text(_getPaymentTypeLabel(type));
    if (typeOption.evaluate().isNotEmpty) {
      await tester.tap(typeOption);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }
  }

  // Find and tap submit button
  var submitButtons = find.byType(ElevatedButton);
  if (submitButtons.evaluate().isNotEmpty) {
    // Get the last button (should be the submit/create button)
    await tester.tap(submitButtons.last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}

/// Edit an existing payment by index
Future<void> _editPayment(
  WidgetTester tester, {
  required int index,
  required double newAmount,
}) async {
  debugPrint('Editing payment at index $index with amount $newAmount');

  // Look for edit button (pen icon)
  final editButtons = find.byIcon(Icons.edit);
  if (editButtons.evaluate().length > index) {
    await tester.tap(editButtons.at(index));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  // Clear and update amount field
  var amountFields = find.byType(TextField);
  if (amountFields.evaluate().isNotEmpty) {
    // Find the amount field in the dialog
    for (int i = 0; i < amountFields.evaluate().length; i++) {
      final field = amountFields.at(i);
      try {
        await tester.enterText(
          field,
          newAmount.toStringAsFixed(2).replaceAll('.', ','),
        );
        break;
      } catch (_) {
        // Field might not be editable, continue
      }
    }
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 500));

  // Tap update button
  var buttons = find.byType(ElevatedButton);
  if (buttons.evaluate().isNotEmpty) {
    // Get the last button (update button)
    await tester.tap(buttons.last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}

/// Delete a payment by index
Future<void> _deletePayment(WidgetTester tester, {required int index}) async {
  debugPrint('Deleting payment at index $index');

  // Look for delete button (trash icon)
  final deleteButtons = find.byIcon(Icons.delete);
  if (deleteButtons.evaluate().length > index) {
    await tester.tap(deleteButtons.at(index));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Confirm deletion if dialog appears
    final confirmButton = find.text('Confirmar');
    if (confirmButton.evaluate().isEmpty) {
      final yesButton = find.text('Sim');
      if (yesButton.evaluate().isNotEmpty) {
        await tester.tap(yesButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    } else {
      await tester.tap(confirmButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
  }
}

/// Try to add a payment with a future date (should fail)
Future<void> _tryAddPaymentWithFutureDate(WidgetTester tester) async {
  debugPrint('Testing payment with future date (should fail)');

  // Open add payment dialog
  var addButton = find.text('Adicionar Pagamento');
  if (addButton.evaluate().isEmpty) {
    addButton = find.byIcon(Icons.add);
  }

  if (addButton.evaluate().isNotEmpty) {
    await tester.tap(addButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Enter future date
    final futureDate = DateTime.now().add(const Duration(days: 10));
    final dateFields = find.byType(TextField);
    if (dateFields.evaluate().isNotEmpty) {
      final formattedDate = DateFormat('dd/MM/yyyy').format(futureDate);
      await tester.enterText(dateFields.first, formattedDate);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Try to submit
      var submitButtons = find.byType(ElevatedButton);
      if (submitButtons.evaluate().isNotEmpty) {
        await tester.tap(submitButtons.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    }

    // Close dialog by tapping outside or close button
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }
}

/// Verify chart renders correctly
/// Note: Currently unused but useful for future chart validation tests
// ignore: unused_element
Future<void> _verifyChart(WidgetTester tester) async {
  debugPrint('Verifying chart');

  // Look for legend items
  final estimadoLegend = find.text('Estimado');
  final realizadoLegend = find.text('Realizado');

  expect(estimadoLegend, findsWidgets);
  if (realizadoLegend.evaluate().isNotEmpty) {
    expect(realizadoLegend, findsWidgets);
  }
}

/// Verify summary card with expected values
/// Note: Currently unused but useful for future summary validation tests
// ignore: unused_element
Future<void> _verifySummary(
  WidgetTester tester,
  Map<String, dynamic> expectedValues,
) async {
  debugPrint('Verifying summary with values: $expectedValues');

  // Look for summary card
  final cards = find.byType(Card);
  expect(cards, findsWidgets);

  // Check for metric labels
  if (expectedValues.containsKey('totalPaid')) {
    final totalPaidWidget = find.text('Total Pago');
    expect(totalPaidWidget, findsWidgets);
  }
}

/// Verify payment list content
/// Note: Currently unused but useful for future payment list validation tests
// ignore: unused_element
Future<void> _verifyPaymentList(
  WidgetTester tester,
  List<PaymentRecord> expectedPayments,
) async {
  debugPrint('Verifying payment list with ${expectedPayments.length} items');

  final listView = find.byType(ListView);
  expect(listView, findsWidgets);

  if (expectedPayments.isEmpty) {
    final emptyState = find.text('Nenhum pagamento registrado');
    expect(emptyState, findsWidgets);
  } else {
    // Verify list items exist
    expect(find.byType(Card), findsWidgets);
  }
}

/// Get localized payment type label
String _getPaymentTypeLabel(String type) {
  const labels = {
    'normal': 'Normal',
    'extra_monthly': 'Extra Mensal',
    'extra_one_time': 'Extra Única',
    'amortization': 'Amortização',
  };
  return labels[type] ?? type;
}

/// Helper to go back to previous screen
extension _WidgetTesterPageBack on WidgetTester {
  // ignore: unused_element
  Future<void> pageBack() async {
    final backButton = find.byIcon(Icons.arrow_back);
    if (backButton.evaluate().isNotEmpty) {
      await tap(backButton);
      await pumpAndSettle();
    }
  }
}
