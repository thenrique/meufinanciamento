import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../../core/constants.dart';
import '../../../shared/extensions/currency_extension.dart';

class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({super.key, required this.totalBalance});

  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF2D5487)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              const Gap(10),
              Text(
                'Saldo devedor total',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Gap(16),
          Text(
            totalBalance.toCurrency(),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Gap(8),
          Text(
            'Soma de todos os seus financiamentos',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

