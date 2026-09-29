

enum ChatRole { user, assistant, system }
enum MessageStatus { sending, sent, failed }

class Conversation {
  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory Conversation.empty() {
    final now = DateTime.now();
    return Conversation(
      id: 'conversation-${now.microsecondsSinceEpoch}',
      title: 'New conversation',
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }

  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<ChatMessage> messages;

  int get messageCount => messages.length;

  String get lastMessagePreview => messages.isEmpty ? '' : messages.last.text;

  Conversation copy() {
    return Conversation(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messages: messages.map((message) => message.copy()).toList(),
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.isCrisisFlagged = false,
    this.metadata = const {},
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  MessageStatus status;
  final bool isCrisisFlagged;
  final Map<String, Object?> metadata;

  ChatMessage copy() {
    return ChatMessage(
      id: id,
      role: role,
      text: text,
      createdAt: createdAt,
      status: status,
      isCrisisFlagged: isCrisisFlagged,
      metadata: Map.from(metadata),
    );
  }
}
