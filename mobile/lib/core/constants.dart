import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const green = Color(0xFF10B981);
  static const navy = Color(0xFF1E3A5F);
  static const surface = Color(0xFFF8FAFC);
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const greenLight = Color(0xFFD1FAE5);
  static const navyLight = Color(0xFFE8EEF7);
  static const white = Color(0xFFFFFFFF);
}

class AppStrings {
  AppStrings._();

  static const appName = 'Amortizador Pro';
  static const tagline = 'Economize nos juros do seu financiamento';
}

class ApiEndpoints {
  ApiEndpoints._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const loans = '/loans';
  static const simulate = '/simulate';
  static const insights = '/advisor/insights';
  static const reportGenerate = '/report/generate';

  static String loanById(String id) => '/loans/$id';
  static String simulateLoan(String loanId) => '/simulate/$loanId';
  static String loanHistory(String loanId) => '/loans/$loanId/history';
  static String loanPayments(String loanId) => '/loans/$loanId/payments';
  static String paymentById(String loanId, String paymentId) =>
      '/loans/$loanId/payments/$paymentId';
}

class EnvConfig {
  EnvConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );
}
