class Insight {
  const Insight({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.urgency,
    required this.data,
    required this.actionLabel,
    required this.actionUrl,
    required this.isRead,
  });

  final String id;
  final String type;
  final String title;
  final String body;

  /// 'low' | 'medium' | 'high'
  final String urgency;
  final Map<String, dynamic> data;
  final String actionLabel;
  final String actionUrl;
  final bool isRead;

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      urgency: json['urgency'] as String? ?? 'low',
      data: json['data'] as Map<String, dynamic>? ?? {},
      actionLabel: json['action_label'] as String? ?? 'Ver detalhes',
      actionUrl: json['action_url'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'urgency': urgency,
        'data': data,
        'action_label': actionLabel,
        'action_url': actionUrl,
        'is_read': isRead,
      };

  Insight copyWith({bool? isRead}) {
    return Insight(
      id: id,
      type: type,
      title: title,
      body: body,
      urgency: urgency,
      data: data,
      actionLabel: actionLabel,
      actionUrl: actionUrl,
      isRead: isRead ?? this.isRead,
    );
  }
}
