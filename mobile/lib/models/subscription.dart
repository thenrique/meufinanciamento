import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription.g.dart';

/// Status da assinatura do usuário
enum SubscriptionStatus {
  active,
  expired,
  cancelled,
}

/// Plano de assinatura
enum SubscriptionPlan {
  trial,
  premium,
}

extension SubscriptionStatusExt on SubscriptionStatus {
  String get value => name;
  
  bool get isActive => this == SubscriptionStatus.active;
  bool get isExpired => this == SubscriptionStatus.expired;
  bool get isCancelled => this == SubscriptionStatus.cancelled;
}

extension SubscriptionPlanExt on SubscriptionPlan {
  String get value => name;
  
  bool get isTrial => this == SubscriptionPlan.trial;
  bool get isPremium => this == SubscriptionPlan.premium;
}

/// Modelo de assinatura do usuário
@JsonSerializable()
class UserSubscription {
  /// ID único da assinatura
  final String id;

  /// ID do usuário
  final String userId;

  /// Status da assinatura
  final SubscriptionStatus status;

  /// Plano da assinatura
  final SubscriptionPlan plan;

  /// Data de início
  final DateTime startedAt;

  /// Data de expiração (para trial)
  final DateTime expiresAt;

  /// Se o trial foi estendido
  final bool trialExtended;

  /// ID do cliente no Mercado Pago (opcional)
  final String? mercadoPagoCustomerId;

  /// Data de cancelamento (se cancelado)
  final DateTime? cancelledAt;

  /// Data de criação
  final DateTime createdAt;

  /// Data da última atualização
  final DateTime updatedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.status,
    required this.plan,
    required this.startedAt,
    required this.expiresAt,
    required this.trialExtended,
    this.stripeCustomerId,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$UserSubscriptionToJson(this);

  @override
  String toString() =>
      'UserSubscription(id: $id, userId: $userId, status: ${status.value}, plan: ${plan.value})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSubscription &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          status == other.status &&
          plan == other.plan;

  @override
  int get hashCode =>
      id.hashCode ^ userId.hashCode ^ status.hashCode ^ plan.hashCode;
}

/// Status calculado da assinatura
@JsonSerializable()
class SubscriptionStatusInfo {
  /// Dados da assinatura
  final UserSubscription subscription;

  /// Dias restantes (para trial)
  final int daysRemaining;

  /// Se é trial
  final bool isTrial;

  /// Se está ativa
  final bool isActive;

  /// Se expirou
  final bool isExpired;

  /// Data de expiração formatada
  final String expiresAtFormatted;

  SubscriptionStatusInfo({
    required this.subscription,
    required this.daysRemaining,
    required this.isTrial,
    required this.isActive,
    required this.isExpired,
    required this.expiresAtFormatted,
  });

  factory SubscriptionStatusInfo.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatusInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionStatusInfoToJson(this);

  @override
  String toString() =>
      'SubscriptionStatusInfo(plan: ${subscription.plan.value}, status: ${subscription.status.value}, daysRemaining: $daysRemaining)';
}

/// Resposta de requisição de inscrição
@JsonSerializable()
class SubscriptionResponse {
  /// Dados da assinatura
  final UserSubscription subscription;

  /// Status calculado
  final SubscriptionStatusInfo status;

  SubscriptionResponse({
    required this.subscription,
    required this.status,
  });

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionResponseToJson(this);
}

/// Requisição para estender trial
@JsonSerializable()
class TrialExtendRequest {
  /// Se vai estender
  final bool extend;

  TrialExtendRequest({
    this.extend = true,
  });

  factory TrialExtendRequest.fromJson(Map<String, dynamic> json) =>
      _$TrialExtendRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TrialExtendRequestToJson(this);
}
