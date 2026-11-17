import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const green = Color(0xFF10B981);
  static const navy = Color(0xFF1E3A5F);
  static const surface = Color(0xFFF8FAFC);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
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
  static const userSubscription = '/api/user/subscription';
  static const extendTrial = '/api/subscription/extend-trial';
  static const cancelSubscription = '/api/subscription';

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
    defaultValue: 'https://cpncjeeegxrwbwbdzdwe.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwbmNqZWVlZ3hyd2J3YmR6ZHdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzODU0NDUsImV4cCI6MjA4OTk2MTQ0NX0.mMohf3YsVu_A0ncAzue8jmbOidjGmawkNghaO5RJIeY',
  );
}
