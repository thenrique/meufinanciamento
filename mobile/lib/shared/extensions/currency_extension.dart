import 'package:intl/intl.dart' as intl;

extension CurrencyFormat on double {
  String toCurrency() =>
      'R\$ ${intl.NumberFormat('#,##0.00', 'pt_BR').format(this)}';

  String toPercent([int decimals = 2]) =>
      '${toStringAsFixed(decimals).replaceAll('.', ',')}%';

  String toMonths() {
    if (this == 1) return '1 mês';
    return '${toInt()} meses';
  }
}

extension IntFormat on int {
  String toMonths() {
    if (this == 1) return '1 mês';
    return '$this meses';
  }
}

extension DateTimeFormat on DateTime {
  String toPortugueseMonthYear() {
    final formatter = intl.DateFormat('MMMM \'de\' yyyy', 'pt_BR');
    return formatter.format(this);
  }

  String toPortugueseDate() {
    final formatter = intl.DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR');
    return formatter.format(this);
  }
}
