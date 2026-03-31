class MonthEntry {
  const MonthEntry({
    required this.month,
    required this.payment,
    required this.amortization,
    required this.interest,
    required this.insurance,
    required this.outstandingBalance,
  });

  final int month;
  final double payment;
  final double amortization;
  final double interest;
  final double insurance;
  final double outstandingBalance;

  factory MonthEntry.fromJson(Map<String, dynamic> json) {
    return MonthEntry(
      month: json['month'] as int,
      payment: (json['payment'] as num).toDouble(),
      amortization: (json['amortization'] as num).toDouble(),
      interest: (json['interest'] as num).toDouble(),
      insurance: (json['insurance'] as num? ?? 0).toDouble(),
      outstandingBalance: (json['outstanding_balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'payment': payment,
        'amortization': amortization,
        'interest': interest,
        'insurance': insurance,
        'outstanding_balance': outstandingBalance,
      };
}

class SimulationSummary {
  const SimulationSummary({
    required this.mesesEconomizados,
    required this.totalJurosBase,
    required this.totalJurosAporte,
    required this.totalJurosEconomizados,
    required this.economiaTotal,
    required this.dataQuitacaoBase,
    required this.dataQuitacaoAporte,
  });

  final int mesesEconomizados;
  final double totalJurosBase;
  final double totalJurosAporte;
  final double totalJurosEconomizados;
  final double economiaTotal;
  final DateTime dataQuitacaoBase;
  final DateTime dataQuitacaoAporte;

  factory SimulationSummary.fromJson(Map<String, dynamic> json) {
    return SimulationSummary(
      mesesEconomizados: json['meses_economizados'] as int,
      totalJurosBase: (json['total_juros_base'] as num).toDouble(),
      totalJurosAporte: (json['total_juros_aporte'] as num).toDouble(),
      totalJurosEconomizados:
          (json['total_juros_economizados'] as num).toDouble(),
      economiaTotal: (json['economia_total'] as num).toDouble(),
      dataQuitacaoBase:
          DateTime.parse(json['data_quitacao_base'] as String),
      dataQuitacaoAporte:
          DateTime.parse(json['data_quitacao_aporte'] as String),
    );
  }
}

class SimulationResult {
  const SimulationResult({
    required this.cenarioBase,
    required this.cenarioComAporte,
    required this.resumo,
  });

  final List<MonthEntry> cenarioBase;
  final List<MonthEntry> cenarioComAporte;
  final SimulationSummary resumo;

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult(
      cenarioBase: (json['cenario_base'] as List)
          .map((e) => MonthEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      cenarioComAporte: (json['cenario_com_aporte'] as List)
          .map((e) => MonthEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      resumo: SimulationSummary.fromJson(
          json['resumo'] as Map<String, dynamic>),
    );
  }
}
