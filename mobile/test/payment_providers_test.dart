import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amortizador_pro/core/api_client.dart';
import 'package:amortizador_pro/models/payment_record.dart';
import 'package:amortizador_pro/features/loan_history/providers.dart';

import 'payment_providers_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('PaymentNotifier', () {
    late MockApiClient mockApi;
    late PaymentNotifier notifier;
    const loanId = 'loan-123';

    final testPayment1 = PaymentRecord(
      id: 'payment-1',
      loanId: loanId,
      paymentDate: DateTime(2024, 1, 15),
      amountPaid: 1000.0,
      paymentType: 'normal',
      createdAt: DateTime(2024, 1, 15),
    );

    final testPayment2 = PaymentRecord(
      id: 'payment-2',
      loanId: loanId,
      paymentDate: DateTime(2024, 1, 20),
      amountPaid: 500.0,
      paymentType: 'normal',
      createdAt: DateTime(2024, 1, 20),
    );

    final testPayment3 = PaymentRecord(
      id: 'payment-3',
      loanId: loanId,
      paymentDate: DateTime(2024, 1, 10),
      amountPaid: 2000.0,
      paymentType: 'extra_monthly',
      createdAt: DateTime(2024, 1, 10),
    );

    final paymentCreate = PaymentCreate(
      paymentDate: DateTime(2024, 2, 1),
      amountPaid: 1500.0,
      paymentType: 'normal',
    );

    setUp(() {
      mockApi = MockApiClient();
      notifier = PaymentNotifier(api: mockApi, loanId: loanId);
    });

    test('Initial state is empty list', () {
      expect(notifier.state, isEmpty);
    });

    test('refreshPayments loads and sorts payments by date (newest first)', () async {
      // Arrange - setup mock before calling refreshPayments
      final unsortedPayments = [testPayment1, testPayment2, testPayment3];
      when(mockApi.getPayments(loanId)).thenAnswer(
        (_) async => unsortedPayments,
      );

      // Act
      final result = await notifier.refreshPayments();

      // Assert
      expect(result, hasLength(3));
      // Verify sorted by date descending (newest first)
      expect(result[0].paymentDate, DateTime(2024, 1, 20)); // Jan 20
      expect(result[1].paymentDate, DateTime(2024, 1, 15)); // Jan 15
      expect(result[2].paymentDate, DateTime(2024, 1, 10)); // Jan 10
      expect(notifier.state, result);
    });

    test('createPayment adds payment to state and returns created record', () async {
      // Arrange - pre-populate state with existing payments
      final newPaymentRecord = PaymentRecord(
        id: 'payment-new',
        loanId: loanId,
        paymentDate: paymentCreate.paymentDate,
        amountPaid: paymentCreate.amountPaid,
        paymentType: paymentCreate.paymentType,
        createdAt: DateTime.now(),
      );

      when(mockApi.createPayment(loanId, paymentCreate)).thenAnswer(
        (_) async => newPaymentRecord,
      );
      // Manually set initial state
      notifier.state = [testPayment1, testPayment2, testPayment3];

      // Act
      final created = await notifier.createPayment(paymentCreate);

      // Assert
      expect(created.id, 'payment-new');
      expect(notifier.state, contains(created));
      expect(notifier.state, hasLength(4));
      // Verify still sorted by date (newest first)
      expect(notifier.state[0].paymentDate, DateTime(2024, 2, 1));
    });

    test('updatePayment modifies payment in state and returns updated record',
        () async {
      // Arrange - manually set initial state
      notifier.state = [testPayment1, testPayment2, testPayment3];

      final updatedPayment = PaymentRecord(
        id: 'payment-1',
        loanId: loanId,
        paymentDate: DateTime(2024, 1, 25),
        amountPaid: 1500.0,
        paymentType: 'extra_monthly',
        createdAt: testPayment1.createdAt,
      );

      final updateData = PaymentCreate(
        paymentDate: updatedPayment.paymentDate,
        amountPaid: updatedPayment.amountPaid,
        paymentType: updatedPayment.paymentType,
      );

      when(mockApi.updatePayment(loanId, 'payment-1', updateData)).thenAnswer(
        (_) async => updatedPayment,
      );

      // Act
      final result = await notifier.updatePayment('payment-1', updateData);

      // Assert
      expect(result.id, 'payment-1');
      expect(result.amountPaid, 1500.0);
      expect(result.paymentType, 'extra_monthly');
      // Verify updated in state
      final updatedInState =
          notifier.state.firstWhere((p) => p.id == 'payment-1');
      expect(updatedInState.amountPaid, 1500.0);
      // Verify still sorted
      expect(notifier.state[0].paymentDate, DateTime(2024, 1, 25));
    });

    test('deletePayment removes payment from state', () async {
      // Arrange - manually set initial state
      notifier.state = [testPayment1, testPayment2, testPayment3];
      expect(notifier.state, hasLength(3));

      when(mockApi.deletePayment(loanId, 'payment-1')).thenAnswer((_) async {});

      // Act
      await notifier.deletePayment('payment-1');

      // Assert
      expect(notifier.state, hasLength(2));
      expect(notifier.state, isNot(contains(testPayment1)));
    });

    test('API error in refreshPayments throws PaymentException', () async {
      // Arrange
      when(mockApi.getPayments(loanId))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => notifier.refreshPayments(),
        throwsA(isA<PaymentException>()),
      );
      // State should remain unchanged
      expect(notifier.state, isEmpty);
    });

    test('API error in createPayment throws PaymentException and does not modify state',
        () async {
      // Arrange - manually set initial state
      notifier.state = [testPayment1];

      when(mockApi.createPayment(loanId, paymentCreate))
          .thenThrow(Exception('API error'));

      // Act & Assert
      expect(
        () => notifier.createPayment(paymentCreate),
        throwsA(isA<PaymentException>()),
      );
      // State should remain unchanged
      expect(notifier.state, hasLength(1));
      expect(notifier.state[0].id, 'payment-1');
    });

    test('API error in updatePayment throws PaymentException and does not modify state',
        () async {
      // Arrange - manually set initial state
      notifier.state = [testPayment1];

      when(mockApi.updatePayment(loanId, 'payment-1', paymentCreate))
          .thenThrow(Exception('API error'));

      // Act & Assert
      expect(
        () => notifier.updatePayment('payment-1', paymentCreate),
        throwsA(isA<PaymentException>()),
      );
      // State should remain unchanged
      expect(notifier.state[0].amountPaid, 1000.0);
    });

    test('API error in deletePayment throws PaymentException and does not modify state',
        () async {
      // Arrange - manually set initial state
      notifier.state = [testPayment1, testPayment2];

      when(mockApi.deletePayment(loanId, 'payment-1'))
          .thenThrow(Exception('API error'));

      // Act & Assert
      expect(
        () => notifier.deletePayment('payment-1'),
        throwsA(isA<PaymentException>()),
      );
      // State should remain unchanged
      expect(notifier.state, hasLength(2));
    });

    test('State is always sorted by date after operations', () async {
      // Arrange
      final unsortedPayments = [testPayment3, testPayment1, testPayment2];
      notifier.state = unsortedPayments;

      when(mockApi.getPayments(loanId)).thenAnswer(
        (_) async => unsortedPayments,
      );

      // Act
      await notifier.refreshPayments();

      // Assert - verify descending order (newest first)
      for (int i = 0; i < notifier.state.length - 1; i++) {
        expect(
          notifier.state[i].paymentDate.isAfter(notifier.state[i + 1].paymentDate) ||
              notifier.state[i].paymentDate.isAtSameMomentAs(notifier.state[i + 1].paymentDate),
          true,
          reason:
              'Payments should be sorted with newest first (${notifier.state[i].paymentDate} should be >= ${notifier.state[i + 1].paymentDate})',
        );
      }
    });

    test('Multiple payments with same date maintain stable order', () async {
      // Arrange
      final sameDate = DateTime(2024, 1, 15);
      final payment1 = PaymentRecord(
        id: 'p1',
        loanId: loanId,
        paymentDate: sameDate,
        amountPaid: 100.0,
        paymentType: 'normal',
        createdAt: DateTime(2024, 1, 15, 10),
      );
      final payment2 = PaymentRecord(
        id: 'p2',
        loanId: loanId,
        paymentDate: sameDate,
        amountPaid: 200.0,
        paymentType: 'normal',
        createdAt: DateTime(2024, 1, 15, 11),
      );

      when(mockApi.getPayments(loanId)).thenAnswer(
        (_) async => [payment1, payment2],
      );

      // Act
      await notifier.refreshPayments();

      // Assert
      expect(notifier.state, hasLength(2));
      expect(notifier.state[0].paymentDate, notifier.state[1].paymentDate);
    });

    test('refreshPayments replaces entire state', () async {
      // Arrange - setup initial state
      notifier.state = [testPayment1, testPayment2];
      expect(notifier.state, hasLength(2));

      // Act - refresh with different payments
      when(mockApi.getPayments(loanId)).thenAnswer(
        (_) async => [testPayment3],
      );
      await notifier.refreshPayments();

      // Assert - state should be completely replaced
      expect(notifier.state, hasLength(1));
      expect(notifier.state[0].id, 'payment-3');
    });

    test('PaymentException contains friendly error message', () {
      // Arrange
      final exception = PaymentException('Erro ao criar pagamento: Sem conexão');

      // Act & Assert
      expect(exception.message, contains('Erro ao criar pagamento'));
      expect(exception.toString(), contains('Erro ao criar pagamento'));
    });
  });
}
