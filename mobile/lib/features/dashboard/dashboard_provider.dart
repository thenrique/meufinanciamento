import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/loan.dart';
import '../../models/insight.dart';
import '../../core/api_client.dart';

final loansProvider = FutureProvider<List<Loan>>((ref) async {
  final response = await ApiClient.instance.dio.get('/loans');
  final list = response.data as List;
  return list.map((e) => Loan.fromJson(e as Map<String, dynamic>)).toList();
});

final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  final response = await ApiClient.instance.dio.get('/advisor/insights');
  final list = response.data as List;
  final insights =
      list.map((e) => Insight.fromJson(e as Map<String, dynamic>)).toList();
  // Ordenar: high primeiro, depois medium, depois low
  insights.sort((a, b) {
    const order = {'high': 0, 'medium': 1, 'low': 2};
    return (order[a.urgency] ?? 3).compareTo(order[b.urgency] ?? 3);
  });
  return insights;
});

final totalBalanceProvider = Provider<double>((ref) {
  final loansAsync = ref.watch(loansProvider);
  return loansAsync.when(
    data: (loans) =>
        loans.fold(0.0, (sum, loan) => sum + loan.outstandingBalance),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final dismissedInsightsProvider =
    StateProvider<Set<String>>((ref) => {});

final visibleInsightsProvider = Provider<AsyncValue<List<Insight>>>((ref) {
  final insightsAsync = ref.watch(insightsProvider);
  final dismissed = ref.watch(dismissedInsightsProvider);

  return insightsAsync.whenData(
    (insights) =>
        insights.where((i) => !dismissed.contains(i.id)).toList(),
  );
});

final deleteLoanProvider =
    FutureProvider.family<void, String>((ref, loanId) async {
  await ApiClient.instance.dio.delete('/loans/$loanId');
  ref.invalidate(loansProvider);
});
