import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../core/constants.dart';
import '../../core/auth_service.dart';
import '../../models/loan.dart';
import '../../shared/widgets/error_toast.dart';
import '../../features/dashboard/dashboard_provider.dart';
import 'simulator_provider.dart';
import 'widgets/scenario_chart.dart';
import 'widgets/result_summary_card.dart';

class SimulatorScreen extends ConsumerWidget {
  const SimulatorScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansProvider);

    final loan = loansAsync.whenOrNull(
      data: (loans) =>
          loans.where((l) => l.id == loanId).firstOrNull,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(loan?.bankName ?? 'Simulador'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: loan == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navy))
          : _SimulatorBody(loan: loan, loanId: loanId),
    );
  }
}

class _SimulatorBody extends ConsumerStatefulWidget {
  const _SimulatorBody({required this.loan, required this.loanId});

  final Loan loan;
  final String loanId;

  @override
  ConsumerState<_SimulatorBody> createState() => _SimulatorBodyState();
}

class _SimulatorBodyState extends ConsumerState<_SimulatorBody> {
  final _oneTimeController = TextEditingController();

  @override
  void dispose() {
    _oneTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(simulatorProvider(widget.loanId));
    final notifier = ref.read(simulatorProvider(widget.loanId).notifier);

    ref.listen<SimulatorState>(simulatorProvider(widget.loanId), (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ErrorToast.show(context, next.error!);
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de resumo do financiamento
          _LoanSummaryCard(loan: widget.loan),
          const Gap(24),

          // Aporte mensal extra
          Text(
            'Aporte mensal extra',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(8),
          Center(
            child: Text(
              simState.extraMonthly == 0
                  ? 'Sem aporte extra'
                  : 'R\$ ${simState.extraMonthly.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          ),
          Slider(
            value: simState.extraMonthly,
            min: 0,
            max: 5000,
            divisions: 100,
            label: 'R\$ ${simState.extraMonthly.toStringAsFixed(0)}',
            onChanged: (v) {
              final rounded = (v / 50).round() * 50.0;
              notifier.setExtraMonthly(rounded);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('R\$ 0',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text('R\$ 5.000',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Gap(20),

          // Aporte único
          Text(
            'Aporte único (opcional)',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(8),
          TextFormField(
            controller: _oneTimeController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor do aporte único',
              prefixText: 'R\$ ',
              hintText: '0,00',
            ),
            onChanged: (v) {
              final parsed = double.tryParse(
                    v.replaceAll('.', '').replaceAll(',', '.'),
                  ) ??
                  0;
              notifier.setExtraOneTime(parsed);
            },
          ),
          const Gap(24),

          // Botão Simular
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: simState.isLoading ? null : () => notifier.simulate(),
              child: simState.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.white),
                    )
                  : const Text('Simular'),
            ),
          ),

          // Resultados
          if (simState.result != null) ...[
            const Gap(24),
            ResultSummaryCard(result: simState.result!),
            const Gap(24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
                ],
              ),
              child: ScenarioChart(result: simState.result!),
            ),
            const Gap(24),

            // Botão relatório
            OutlinedButton.icon(
              onPressed: () {
                if (AuthService.instance.isPremium) {
                  context.push('/report/${widget.loanId}');
                } else {
                  context.push('/paywall');
                }
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Baixar relatório completo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const Gap(32),
          ],
        ],
      ),
    );
  }
}

class _LoanSummaryCard extends StatelessWidget {
  const _LoanSummaryCard({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loan.bankName,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(12),
          _Row(label: 'Saldo devedor',
              value: 'R\$ ${loan.outstandingBalance.toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'),
          const Gap(6),
          _Row(
            label: 'Taxa de juros',
            value: '${loan.interestRateYear.toStringAsFixed(2).replaceAll('.', ',')}% a.a.',
          ),
          const Gap(6),
          _Row(
            label: 'Prazo restante',
            value: '${loan.remainingMonths} meses',
          ),
          const Gap(6),
          _Row(label: 'Sistema', value: loan.loanType),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
      ],
    );
  }
}
