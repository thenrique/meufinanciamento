import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/simulation.dart';

// Re-export for convenience — friendlyNetworkError lives in api_client.dart

class SimulatorState {
  const SimulatorState({
    required this.loanId,
    this.extraMonthly = 0,
    this.extraOneTime = 0,
    this.result,
    this.isLoading = false,
    this.error,
  });

  final String loanId;
  final double extraMonthly;
  final double extraOneTime;
  final SimulationResult? result;
  final bool isLoading;
  final String? error;

  SimulatorState copyWith({
    double? extraMonthly,
    double? extraOneTime,
    SimulationResult? result,
    bool? isLoading,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return SimulatorState(
      loanId: loanId,
      extraMonthly: extraMonthly ?? this.extraMonthly,
      extraOneTime: extraOneTime ?? this.extraOneTime,
      result: clearResult ? null : (result ?? this.result),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SimulatorNotifier extends StateNotifier<SimulatorState> {
  SimulatorNotifier(String loanId) : super(SimulatorState(loanId: loanId));

  void setExtraMonthly(double value) {
    state = state.copyWith(extraMonthly: value, clearResult: true);
  }

  void setExtraOneTime(double value) {
    state = state.copyWith(extraOneTime: value, clearResult: true);
  }

  Future<void> simulate() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.dio.post(
        '/simulate',
        data: {
          'loan_id': state.loanId,
          'extra_monthly': state.extraMonthly,
          'extra_one_time': state.extraOneTime,
        },
      );
      final result =
          SimulationResult.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(result: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyNetworkError(e),
      );
    }
  }
}

final simulatorProvider =
    StateNotifierProvider.family<SimulatorNotifier, SimulatorState, String>(
  (ref, loanId) => SimulatorNotifier(loanId),
);
