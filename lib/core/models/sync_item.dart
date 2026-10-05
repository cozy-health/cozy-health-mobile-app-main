import 'dart:convert';

class SyncItem {
  final String id;
  final String type;
  final String action;
  final String recordId;
  final Map<String, dynamic>? payload;
  final int retryCount;
  final DateTime? nextRetryAt;
  final DateTime createdAt;

  SyncItem({
    required this.id,
    required this.type,
    required this.action,
    required this.recordId,
    this.payload,
    required this.retryCount,
    this.nextRetryAt,
    required this.createdAt,
  });

  SyncItem copyWith({
    int? retryCount,
    DateTime? nextRetryAt,
  }) {
    return SyncItem(
      id: id,
      type: type,
      action: action,
      recordId: recordId,
      payload: payload,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'action': action,
      'recordId': recordId,
      'payload': payload,
      'retryCount': retryCount,
      'nextRetryAt': nextRetryAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncItem.fromMap(Map<String, dynamic> map) {
    return SyncItem(
      id: map['id'],
      type: map['type'],
      action: map['action'],
      recordId: map['recordId'],
      payload: map['payload'] != null ? Map<String, dynamic>.from(map['payload']) : null,
      retryCount: map['retryCount'] ?? 0,
      nextRetryAt: map['nextRetryAt'] != null ? DateTime.parse(map['nextRetryAt']) : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());
  factory SyncItem.fromJson(String source) => SyncItem.fromMap(json.decode(source));
}
