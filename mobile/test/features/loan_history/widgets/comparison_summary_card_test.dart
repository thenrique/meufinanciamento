import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:amortizador_pro/features/loan_history/widgets/comparison_summary_card.dart';
import 'package:amortizador_pro/models/loan_history.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('ComparisonSummaryCard', () {
    late ComparisonSummary testSummary;

    setUp(() {
      testSummary = ComparisonSummary(
        totalPaidEstimated: 251601.77,
        totalPaidActual: 3050.00,
        totalDeviation: 248551.77,
        monthsAhead: 153,
        monthsBehind: 0,
        estimatedPayoffDate: DateTime(2038, 12, 1),
        actualPayoffDate: DateTime(2026, 3, 1),
        timeSavedMonths: 153,
        interestSaved: 65132.23,
      );
    });

    testWidgets('renders card with valid summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonSummaryCard(summary: testSummary),
          ),
        ),
      );

      expect(find.byType(ComparisonSummaryCard), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Comparativo Resumido'), findsOneWidget);
    });

    testWidgets('renders all 4 metric tiles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonSummaryCard(summary: testSummary),
          ),
        ),
      );

      expect(find.text('Total Pago'), findsOneWidget);
      expect(find.text('Juros Pagos'), findsOneWidget);
      expect(find.text('Meses para Quitação'), findsOneWidget);
      expect(find.text('Data de Quitação'), findsOneWidget);
    });

    testWidgets('formats currency correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonSummaryCard(summary: testSummary),
          ),
        ),
      );

      // Format: R$ 1.234,56 (dot for thousands, comma for decimal)
      expect(find.text('R\$ 251.601,77'), findsWidgets);
      expect(find.text('R\$ 3.050,00'), findsWidgets);
    });

    testWidgets('formats dates correctly (dd/MMM/yyyy)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonSummaryCard(summary: testSummary),
          ),
        ),
      );

      // Expected date format: 01/dez/2038 and 01/mar/2026
      final dateFormatter = DateFormat('dd/MMM/yyyy', 'pt_BR');
      final plannedDate = dateFormatter.format(testSummary.estimatedPayoffDate);
      final actualDate = dateFormatter.format(testSummary.actualPayoffDate!);

      expect(find.text(plannedDate), findsWidgets);
      expect(find.text(actualDate), findsWidgets);
    });

    testWidgets('displays months to payoff correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonSummaryCard(summary: testSummary),
          ),
        ),
      );

      // Should display planned months (180) and actual months (timeSavedMonths)
      expect(find.text('180'), findsWidgets);
      expect(find.text('${testSummary.timeSavedMonths}'), findsWidgets);
    });

    testWidgets('handles null actualPayoffDate gracefully', (WidgetTester tester) async {
      final summaryNoActualDate = ComparisonSummary(
        totalPaidEstimated: 251601.77,
        totalPaidActual: 3050.00,
        totalDeviation: 248551.77,
        monthsAhead: 153,
        monthsBehind: 0,
        estimatedPayoffDate: DateTime(2038, 12, 1),
        actualPayoffDate: null,
        timeSavedMonths: 153,
        interestSaved: 65132.23,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonSummaryCard(summary: summaryNoActualDate),
          ),
        ),
      );

      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('accepts optional originalPrincipal parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonSummaryCard(
              summary: testSummary,
              originalPrincipal: 200000.0,
            ),
          ),
        ),
      );

      expect(find.byType(ComparisonSummaryCard), findsOneWidget);
    });
  });
}
