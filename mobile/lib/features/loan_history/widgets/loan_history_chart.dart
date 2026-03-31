import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../models/loan_history.dart';
import '../../../core/constants.dart';

class LoanHistoryChart extends StatelessWidget {
  /// Creates a chart showing estimated vs actual outstanding balance over time.
  ///
  /// Both [estimatedData] and [actualData] should be non-null, but actualData
  /// can be empty to show only the estimated line.
  ///
  /// Example:
  /// ```dart
  /// LoanHistoryChart(
  ///   estimatedData: loanHistory.calculatedHistory,
  ///   actualData: loanHistory.actualHistory,
  /// )
  /// ```
  final List<CalculatedMonthEntry> estimatedData;
  final List<ActualMonthEntry> actualData;

  const LoanHistoryChart({
    super.key,
    required this.estimatedData,
    required this.actualData,
  });

  @override
  Widget build(BuildContext context) {
    if (estimatedData.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildLegend(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildLineChart(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Nenhum dado de histórico disponível',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Builds the legend showing "Estimado" (blue) and "Realizado" (green).
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Estimado', const Color(0xFF2196F3)),
          const SizedBox(width: 32),
          if (actualData.isNotEmpty)
            _buildLegendItem('Realizado', const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  /// Builds a single legend item with color and label.
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Builds the main LineChart widget.
  Widget _buildLineChart() {
    final estimatedSpots = _buildSpots(estimatedData);
    final List<FlSpot> actualSpots = actualData.isNotEmpty ? _buildSpots(actualData) : [];

    final maxMonth = _getMaxMonth();
    final maxBalance = _getMaxBalance();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            // Blue line: Estimated balance
            LineChartBarData(
              spots: estimatedSpots,
              isCurved: true,
              color: const Color(0xFF2196F3),
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF2196F3),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: false,
              ),
              isStrokeCapRound: true,
            ),
            // Green line: Actual balance (if data exists)
            if (actualSpots.isNotEmpty)
              LineChartBarData(
                spots: actualSpots,
                isCurved: true,
                color: const Color(0xFF4CAF50),
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF4CAF50),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: false,
                ),
                isStrokeCapRound: true,
              ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) =>
                    _buildYAxisLabel(value),
                reservedSize: 60,
                interval: _getYAxisInterval(maxBalance),
              ),
              axisNameWidget: const Text(
                'Saldo (R\$)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) =>
                    _buildXAxisLabel(value.toInt()),
                reservedSize: 30,
                interval: _getXAxisInterval(maxMonth),
              ),
              axisNameWidget: const Text(
                'Mês',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: _getYAxisInterval(maxBalance),
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[300] ?? const Color(0xFFE5E7EB),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(
                color: Colors.grey[300] ?? const Color(0xFFE5E7EB),
                width: 1,
              ),
              bottom: BorderSide(
                color: Colors.grey[300] ?? const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
          ),
          minX: 0,
          maxX: (maxMonth + 2).toDouble(),
          minY: 0,
          maxY: maxBalance * 1.1,
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            getTouchedSpotIndicator:
                (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes
                  .map((spotIndex) {
                    return const TouchedSpotIndicatorData(
                      FlLine(
                        color: Color(0xFFD1D5DB),
                        strokeWidth: 2,
                      ),
                      FlDotData(show: false),
                    );
                  })
                  .toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.grey[800] ?? Colors.black87,
              tooltipRoundedRadius: 8,
              tooltipBorder: BorderSide(
                color: Colors.grey[600] ?? const Color(0xFF4B5563),
              ),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final month = barSpot.x.toInt();
                  final balance = barSpot.y;

                  final label = barSpot.barIndex == 0 ? 'Estimado' : 'Realizado';
                  final balanceFormatted =
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ')
                          .format(balance);

                  return LineTooltipItem(
                    'Mês $month\n$label\n$balanceFormatted',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Converts month entries to FlSpot objects for charting.
  List<FlSpot> _buildSpots(List<CalculatedMonthEntry> entries) {
    return entries
        .map((entry) =>
            FlSpot(entry.month.toDouble(), entry.outstandingBalance))
        .toList();
  }

  /// Gets the maximum month number from both datasets.
  int _getMaxMonth() {
    int maxEstimated = estimatedData.isEmpty ? 0 : estimatedData.last.month;
    int maxActual = actualData.isEmpty ? 0 : actualData.last.month;
    return maxEstimated > maxActual ? maxEstimated : maxActual;
  }

  /// Gets the maximum outstanding balance from both datasets.
  double _getMaxBalance() {
    double maxEstimated = estimatedData.isEmpty
        ? 0
        : estimatedData
            .map((e) => e.outstandingBalance)
            .reduce((a, b) => a > b ? a : b);
    double maxActual = actualData.isEmpty
        ? 0
        : actualData
            .map((e) => e.outstandingBalance)
            .reduce((a, b) => a > b ? a : b);
    return maxEstimated > maxActual ? maxEstimated : maxActual;
  }

  /// Determines the appropriate interval for Y-axis based on max balance.
  double _getYAxisInterval(double maxBalance) {
    if (maxBalance <= 0) return 10000;
    if (maxBalance <= 50000) return 10000;
    if (maxBalance <= 100000) return 20000;
    if (maxBalance <= 200000) return 50000;
    if (maxBalance <= 500000) return 100000;
    return 200000;
  }

  /// Determines the appropriate interval for X-axis based on max month.
  double _getXAxisInterval(int maxMonth) {
    if (maxMonth <= 12) return 1;
    if (maxMonth <= 24) return 3;
    if (maxMonth <= 60) return 6;
    if (maxMonth <= 120) return 12;
    return 24;
  }

  /// Builds a formatted label for the Y-axis.
  Widget _buildYAxisLabel(double value) {
    String formattedValue;

    if (value >= 1000000) {
      formattedValue = 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      formattedValue = 'R\$ ${(value / 1000).toStringAsFixed(0)}K';
    } else {
      formattedValue = 'R\$ ${value.toStringAsFixed(0)}';
    }

    return Text(
      formattedValue,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
      ),
    );
  }

  /// Builds a formatted label for the X-axis.
  Widget _buildXAxisLabel(int month) {
    return Text(
      month.toString(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
      ),
    );
  }
}
