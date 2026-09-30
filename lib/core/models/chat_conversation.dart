import 'package:hive/hive.dart';



@HiveType(typeId: 4)
class ChatConversation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? title;

  @HiveField(2)
  final String? lastMessagePreview;

  @HiveField(3)
  final int messageCount;

  @HiveField(4)
  final bool isArchived;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    this.title,
    this.lastMessagePreview,
    required this.messageCount,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'title': title,
      'message_count': messageCount,
      'is_archived': isArchived,
      'client_updated_at': updatedAt.toUtc().toIso8601String(),
    };
    if (lastMessagePreview != null) json['last_message_preview'] = lastMessagePreview;
    return json;
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      lastMessagePreview: json['last_message_preview'] as String?,
      messageCount: json['message_count'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['client_created_at'] != null ? DateTime.parse(json['client_created_at']) : DateTime.now(),
      updatedAt: json['client_updated_at'] != null ? DateTime.parse(json['client_updated_at']) : DateTime.now(),
    );
  }
}

class ChatConversationAdapter extends TypeAdapter<ChatConversation> {
  @override
  final int typeId = 4;

  @override
  ChatConversation read(BinaryReader reader) {
    return ChatConversation(
      id: reader.readString(),
      title: reader.readString(),
      lastMessagePreview: reader.readString(),
      messageCount: reader.readInt(),
      isArchived: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, ChatConversation obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title ?? '');
    writer.writeString(obj.lastMessagePreview ?? '');
    writer.writeInt(obj.messageCount);
    writer.writeBool(obj.isArchived);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }




}
