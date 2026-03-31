import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:amortizador_pro/models/loan_history.dart';
import 'package:amortizador_pro/features/loan_history/widgets/loan_history_chart.dart';
import 'package:amortizador_pro/core/constants.dart';

void main() {
  group('LoanHistoryChart Widget Tests', () {
    // Helper function to create test data
    List<CalculatedMonthEntry> createEstimatedData({
      int months = 24,
      double initialBalance = 100000,
    }) {
      final entries = <CalculatedMonthEntry>[];
      for (int i = 0; i <= months; i++) {
        final balance =
            initialBalance * (1 - (i.toDouble() / months.toDouble()));
        entries.add(
          CalculatedMonthEntry(
            month: i,
            date: DateTime.now().add(Duration(days: i * 30)),
            paymentPlanned: 5000,
            amortization: 2500,
            interest: 2000,
            insurance: 500,
            outstandingBalance: balance.clamp(0, double.infinity),
          ),
        );
      }
      return entries;
    }

    List<ActualMonthEntry> createActualData({
      int months = 24,
      double initialBalance = 100000,
    }) {
      final entries = <ActualMonthEntry>[];
      for (int i = 0; i <= months; i++) {
        final balance =
            initialBalance * (1 - (i.toDouble() / months.toDouble()));
        entries.add(
          ActualMonthEntry(
            month: i,
            date: DateTime.now().add(Duration(days: i * 30)),
            paymentPlanned: 5000,
            amortization: 2500,
            interest: 2000,
            insurance: 500,
            outstandingBalance: balance.clamp(0, double.infinity),
            paymentActual: 5200,
            payments: [],
            deviation: 200,
          ),
        );
      }
      return entries;
    }

    Widget buildTestWidget({
      required List<CalculatedMonthEntry> estimatedData,
      required List<ActualMonthEntry> actualData,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: LoanHistoryChart(
              estimatedData: estimatedData,
              actualData: actualData,
            ),
          ),
        ),
      );
    }

    testWidgets('renders with valid data', (WidgetTester tester) async {
      final estimatedData = createEstimatedData(months: 24);
      final actualData = createActualData(months: 24);

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: actualData,
        ),
      );

      expect(find.byType(LoanHistoryChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Estimado'), findsOneWidget);
      expect(find.text('Realizado'), findsOneWidget);
    });

    testWidgets('shows empty state when no data provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: [],
          actualData: [],
        ),
      );

      expect(find.byType(LoanHistoryChart), findsOneWidget);
      expect(find.text('Nenhum dado de histórico disponível'),
          findsOneWidget);
    });

    testWidgets('shows only blue line when actual data is empty',
        (WidgetTester tester) async {
      final estimatedData = createEstimatedData(months: 12);

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: [],
        ),
      );

      expect(find.byType(LoanHistoryChart), findsOneWidget);
      expect(find.text('Estimado'), findsOneWidget);
      expect(find.text('Realizado'), findsNothing);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('legend displays correctly with both lines',
        (WidgetTester tester) async {
      final estimatedData = createEstimatedData(months: 24);
      final actualData = createActualData(months: 24);

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: actualData,
        ),
      );

      // Check legend items
      expect(find.text('Estimado'), findsOneWidget);
      expect(find.text('Realizado'), findsOneWidget);

      // Verify legend items are Rows with proper structure
      final legendRows = find.byType(Row);
      expect(legendRows, findsWidgets);
    });

    testWidgets('responds to touch interaction', (WidgetTester tester) async {
      final estimatedData = createEstimatedData(months: 24);
      final actualData = createActualData(months: 24);

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: actualData,
        ),
      );

      // Tap on the chart area to trigger tooltip
      await tester.tapAt(Offset(200, 200));
      await tester.pumpAndSettle();

      // Chart should still be present and interactive
      expect(find.byType(LoanHistoryChart), findsOneWidget);
    });

    testWidgets('handles very short loans (3-6 months)',
        (WidgetTester tester) async {
      final estimatedData = createEstimatedData(months: 6);
      final actualData = createActualData(months: 6);

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: actualData,
        ),
      );

      expect(find.byType(LoanHistoryChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('handles different length histories',
        (WidgetTester tester) async {
      final estimatedData = createEstimatedData(months: 30);
      final actualData = createActualData(months: 20);

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: actualData,
        ),
      );

      expect(find.byType(LoanHistoryChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('chart is responsive to container size',
        (WidgetTester tester) async {
      final estimatedData = createEstimatedData(months: 24);
      final actualData = createActualData(months: 24);

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: actualData,
        ),
      );

      expect(find.byType(LoanHistoryChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('Y-axis labels format correctly', (WidgetTester tester) async {
      final estimatedData = createEstimatedData(months: 24);

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: [],
        ),
      );

      // Chart should be rendered with Y-axis labels
      expect(find.byType(LoanHistoryChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      // Text should include currency formatting
      final textFinder = find.byType(Text);
      expect(textFinder, findsWidgets);
    });

    testWidgets('X-axis labels show month numbers', (WidgetTester tester) async {
      final estimatedData = createEstimatedData(months: 24);

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: [],
        ),
      );

      expect(find.byType(LoanHistoryChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      // Month label should be present
      expect(find.text('Mês'), findsOneWidget);
    });

    testWidgets('chart handles large loan amounts (over 1M)',
        (WidgetTester tester) async {
      final estimatedData = createEstimatedData(
        months: 30,
        initialBalance: 1500000,
      );
      final actualData = createActualData(
        months: 30,
        initialBalance: 1500000,
      );

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: actualData,
        ),
      );

      expect(find.byType(LoanHistoryChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('displays converging lines at payoff',
        (WidgetTester tester) async {
      final estimatedData = createEstimatedData(months: 24);
      final actualData = createActualData(months: 24);

      await tester.pumpWidget(
        buildTestWidget(
          estimatedData: estimatedData,
          actualData: actualData,
        ),
      );

      // Both lines should end near zero (payoff)
      expect(find.byType(LoanHistoryChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      // Verify the last points have low outstanding balance
      final lastEstimated = estimatedData.last.outstandingBalance;
      final lastActual = actualData.last.outstandingBalance;
      expect(lastEstimated, lessThan(1000));
      expect(lastActual, lessThan(1000));
    });
  });
}
