import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/loan_history.dart';
import '../../models/payment_record.dart';

// API Provider reference
final apiProvider = Provider((ref) => ApiClient.instance);

/// Exception thrown when a payment operation fails.
class PaymentException implements Exception {
  PaymentException(this.message, [this.originalError]);

  final String message;
  final Object? originalError;

  @override
  String toString() => message;
}

/// Manages payment records state for a specific loan.
/// 
/// Handles CRUD operations on payment records, maintaining a sorted list
/// (newest first by payment_date). All state mutations are immutable
/// and backed by API calls.
class PaymentNotifier extends StateNotifier<List<PaymentRecord>> {
  /// Creates a new PaymentNotifier for the given [loanId].
  ///
  /// Initial state is an empty list. Call [refreshPayments] to load data.
  PaymentNotifier({
    required ApiClient api,
    required String loanId,
  })  : _api = api,
        _loanId = loanId,
        super([]);

  final ApiClient _api;
  final String _loanId;

  /// Sorts a list of payments by date (newest first).
  List<PaymentRecord> _sortByDate(List<PaymentRecord> payments) {
    final sorted = [...payments];
    sorted.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return sorted;
  }

  /// Creates a new payment record via API and adds it to the state.
  ///
  /// Returns the created [PaymentRecord].
  ///
  /// Throws [PaymentException] if the API call fails. State is not modified
  /// on error (rollback pattern).
  Future<PaymentRecord> createPayment(PaymentCreate payment) async {
    try {
      final record = await _api.createPayment(_loanId, payment);
      state = _sortByDate([...state, record]);
      return record;
    } catch (e) {
      final message = 'Erro ao criar pagamento: ${_errorMessage(e)}';
      debugPrint('[PaymentNotifier] $message');
      throw PaymentException(message, e);
    }
  }

  /// Updates an existing payment record via API.
  ///
  /// Returns the updated [PaymentRecord].
  ///
  /// Throws [PaymentException] if the API call fails. State is not modified
  /// on error (rollback pattern).
  Future<PaymentRecord> updatePayment(
    String paymentId,
    PaymentCreate payment,
  ) async {
    try {
      final updated = await _api.updatePayment(_loanId, paymentId, payment);
      final index = state.indexWhere((p) => p.id == paymentId);
      if (index >= 0) {
        final newPayments = [...state];
        newPayments[index] = updated;
        state = _sortByDate(newPayments);
      }
      return updated;
    } catch (e) {
      final message = 'Erro ao atualizar pagamento: ${_errorMessage(e)}';
      debugPrint('[PaymentNotifier] $message');
      throw PaymentException(message, e);
    }
  }

  /// Deletes a payment record via API and removes it from the state.
  ///
  /// Throws [PaymentException] if the API call fails. State is not modified
  /// on error (rollback pattern).
  Future<void> deletePayment(String paymentId) async {
    try {
      await _api.deletePayment(_loanId, paymentId);
      state = state.where((p) => p.id != paymentId).toList();
    } catch (e) {
      final message = 'Erro ao deletar pagamento: ${_errorMessage(e)}';
      debugPrint('[PaymentNotifier] $message');
      throw PaymentException(message, e);
    }
  }

  /// Refreshes the payment list from the API.
  ///
  /// Returns the complete list of [PaymentRecord] sorted by date.
  ///
  /// Throws [PaymentException] if the API call fails. State is not modified
  /// on error (rollback pattern).
  Future<List<PaymentRecord>> refreshPayments() async {
    try {
      final payments = await _api.getPayments(_loanId);
      state = _sortByDate(payments);
      return state;
    } catch (e) {
      final message = 'Erro ao carregar pagamentos: ${_errorMessage(e)}';
      debugPrint('[PaymentNotifier] $message');
      throw PaymentException(message, e);
    }
  }

  /// Extracts a user-friendly error message from an exception.
  String _errorMessage(Object error) {
    if (error is PaymentException) return error.message;
    return friendlyNetworkError(error);
  }
}

/// Provider for payment records of a specific loan.
/// 
/// Usage:
/// ```dart
/// final payments = ref.watch(paymentNotifierProvider(loanId));
/// await ref.read(paymentNotifierProvider(loanId).notifier).createPayment(payment);
/// ```
final paymentNotifierProvider = StateNotifierProvider.family<
    PaymentNotifier,
    List<PaymentRecord>,
    String>(
  (ref, loanId) => PaymentNotifier(
    api: ref.watch(apiProvider),
    loanId: loanId,
  ),
);

// Loan history provider (estimated vs actual)
final loanHistoryProvider = FutureProvider.family<LoanHistory, String>(
  (ref, loanId) async {
    final api = ref.watch(apiProvider);
    final response = await api.dio.get('/loans/$loanId/history');
    return LoanHistory.fromJson(response.data as Map<String, dynamic>);
  },
);

// Computed: Payment status (adiantado/atrasado/no prazo)
final paymentStatusProvider = Provider.family<String, String>((ref, loanId) {
  final historyAsync = ref.watch(loanHistoryProvider(loanId));
  return historyAsync.when(
    data: (history) {
      if (history.summary.monthsAhead > 0) return 'adiantado';
      if (history.summary.monthsBehind > 0) return 'atrasado';
      return 'no_prazo';
    },
    loading: () => 'carregando',
    error: (_, __) => 'erro',
  );
});

// Computed: Loan summary
final loanSummaryProvider = FutureProvider.family<ComparisonSummary, String>(
  (ref, loanId) async {
    final history = await ref.watch(loanHistoryProvider(loanId).future);
    return history.summary;
  },
);
