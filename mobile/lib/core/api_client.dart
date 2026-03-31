import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/loan_history.dart';
import '../models/payment_record.dart';
import 'constants.dart';

class ApiClient {
  ApiClient._() {
    _dio = _buildDio();
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  Dio get dio => _dio;

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (o) => debugPrint('[API] $o'),
      ));
    }

    return dio;
  }

  // Loan history endpoints
  Future<LoanHistory> getLoanHistory(String loanId) async {
    final response = await _dio.get('/loans/$loanId/history');
    return LoanHistory.fromJson(response.data as Map<String, dynamic>);
  }

  // Payment endpoints
  Future<List<PaymentRecord>> getPayments(String loanId) async {
    final response = await _dio.get('/loans/$loanId/payments');
    return (response.data as List)
        .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentRecord> createPayment(
    String loanId,
    PaymentCreate payment,
  ) async {
    final response = await _dio.post(
      '/loans/$loanId/payments',
      data: payment.toJson(),
    );
    return PaymentRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaymentRecord> updatePayment(
    String loanId,
    String paymentId,
    PaymentCreate payment,
  ) async {
    final response = await _dio.put(
      '/loans/$loanId/payments/$paymentId',
      data: payment.toJson(),
    );
    return PaymentRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePayment(String loanId, String paymentId) async {
    await _dio.delete('/loans/$loanId/payments/$paymentId');
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expirado — sign out silencioso
      Supabase.instance.client.auth.signOut();
    }
    handler.next(err);
  }
}

/// Mensagem amigável de erro de rede em PT-BR
String friendlyNetworkError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'A conexão demorou demais. Verifique sua internet.';
      case DioExceptionType.connectionError:
        return 'Sem conexão com a internet. Tente novamente.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Recurso não encontrado.';
        if (code != null && code >= 500) {
          return 'Erro no servidor. Tente novamente em instantes.';
        }
        return 'Erro inesperado (código $code).';
      default:
        return 'Erro de rede. Tente novamente.';
    }
  }
  return 'Erro inesperado. Tente novamente.';
}
