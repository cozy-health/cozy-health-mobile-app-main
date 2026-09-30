import 'package:hive/hive.dart';



@HiveType(typeId: 3)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String conversationId;

  @HiveField(2)
  final String role; // 'user', 'assistant', 'system'

  @HiveField(3)
  final String content;

  @HiveField(4)
  final String status; // 'sending', 'sent', 'failed'

  @HiveField(5)
  final bool isCrisisFlagged;

  @HiveField(6)
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.status,
    required this.isCrisisFlagged,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'status': status,
      'is_crisis_flagged': isCrisisFlagged,
      'client_created_at': createdAt.toUtc().toIso8601String(),
    };
    if (modelUsed != null) json['model_used'] = modelUsed;
    if (tokensUsed != null) json['tokens_used'] = tokensUsed;
    if (latencyMs != null) json['latency_ms'] = latencyMs;
    return json;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      status: json['status'] as String? ?? 'sent',
      isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
      modelUsed: json['model_used'] as String?,
      tokensUsed: json['tokens_used'] as int?,
      latencyMs: json['latency_ms'] as int?,
      createdAt: json['client_created_at'] != null ? DateTime.parse(json['client_created_at']) : DateTime.now(),
    );
  }
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 3;

  @override
  ChatMessage read(BinaryReader reader) {
    return ChatMessage(
      id: reader.readString(),
      conversationId: reader.readString(),
      role: reader.readString(),
      content: reader.readString(),
      status: reader.readString(),
      isCrisisFlagged: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.conversationId);
    writer.writeString(obj.role);
    writer.writeString(obj.content);
    writer.writeString(obj.status);
    writer.writeBool(obj.isCrisisFlagged);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }




}
