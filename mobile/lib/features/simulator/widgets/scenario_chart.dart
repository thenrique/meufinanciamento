import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../models/simulation.dart';

class ScenarioChart extends StatelessWidget {
  const ScenarioChart({
    super.key,
    required this.result,
  });

  final SimulationResult result;

  List<FlSpot> _toSpots(List<MonthEntry> entries) {
    final filtered = <FlSpot>[];
    for (int i = 0; i < entries.length; i++) {
      if (i % 6 == 0 || i == entries.length - 1) {
        filtered.add(FlSpot(
          entries[i].month.toDouble(),
          entries[i].outstandingBalance,
        ));
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final baseSpots = _toSpots(result.cenarioBase);
    final aportSpots = _toSpots(result.cenarioComAporte);

    final maxY = result.cenarioBase.isNotEmpty
        ? result.cenarioBase.first.outstandingBalance * 1.1
        : 1000000.0;

    final numberFmt = NumberFormat.compact(locale: 'pt_BR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evolução do saldo devedor',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Gap(16),
        SizedBox(
          height: 220,
          child: LineChart(
            duration: const Duration(milliseconds: 300),
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: const Color(0xFFF3F4F6),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) => Text(
                      'R\$ ${numberFmt.format(value)}',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 60,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}m',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final isBase = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${isBase ? "Sem aporte" : "Com aporte"}\n'
                        'R\$ ${NumberFormat('#,##0', 'pt_BR').format(spot.y)}',
                        GoogleFonts.inter(
                          color: isBase ? AppColors.error : AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: baseSpots,
                  isCurved: true,
                  color: AppColors.error,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.error.withValues(alpha: 0.05),
                  ),
                ),
                LineChartBarData(
                  spots: aportSpots,
                  isCurved: true,
                  color: AppColors.green,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.green.withValues(alpha: 0.07),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Gap(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: AppColors.error, label: 'Sem aporte'),
            const Gap(24),
            _LegendItem(color: AppColors.green, label: 'Com aporte'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

