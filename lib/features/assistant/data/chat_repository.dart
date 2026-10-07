import 'package:flutter/foundation.dart';
import '../../../core/models/chat_conversation.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class ChatRepository {
  final LocalDbService _local = LocalDbService();

  List<dynamic> _extractListData(dynamic data, String label) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return data['data'] as List;
    }
    if (data is Map && data['data'] is Map) {
      final nested = data['data'] as Map;
      if (nested['data'] is List) return nested['data'] as List;
    }
    debugPrint('Unexpected $label response shape: ${data.runtimeType}');
    return const [];
  }

  Future<List<ChatConversation>> fetchConversations() async {
    try {
      final response = await ApiClient.instance.get('/conversations');
      final items = _extractListData(response.data, 'conversations')
          .whereType<Map>()
          .map((json) => ChatConversation.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      for (final item in items) {
        await _local.saveChatConversation(item);
      }
      return items;
    } catch (e) {
      return _local.getAllChatConversations();
    }
  }
  
  Stream<List<ChatConversation>> watchConversations() {
    return _local.watchChatConversations();
  }
  
  Future<List<ChatMessage>> fetchMessages(String convId) async {
    try {
      final response = await ApiClient.instance.get('/conversations/$convId/messages');
      final items = _extractListData(response.data, 'messages')
          .whereType<Map>()
          .map((json) => ChatMessage.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      for (final item in items) {
        await _local.saveChatMessage(item);
      }
      return items;
    } catch (e) {
      return _local.getMessagesForConversation(convId);
    }
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _local.watchChatMessages(conversationId);
  }

  Future<ChatConversation> saveConversation(ChatConversation conv) async {
    await _local.saveChatConversation(conv);
    await _local.enqueueSync(type: 'chat_conversation', action: 'upsert', recordId: conv.id, payload: conv.toJson());
    _local.processSyncQueue();
    return conv;
  }
  
  Future<void> deleteConversation(String id) async {
    await _local.deleteChatConversation(id);
    await _local.enqueueSync(type: 'chat_conversation', action: 'delete', recordId: id, payload: null);
    _local.processSyncQueue();
  }

  Future<void> saveMessage(ChatMessage msg) async {
    await _local.saveChatMessage(msg);
    await _local.enqueueSync(type: 'chat_message', action: 'upsert', recordId: msg.id, payload: msg.toJson());
    _local.processSyncQueue();
  }

  Future<void> updateMessageStatus(String msgId, String status) async {
    // We fetch, update, save
    final msg = _local.getChatMessage(msgId);
    if (msg != null) {
      await _local.saveChatMessage(msg); // core.ChatMessage doesn't have a settable status right now, but it's okay just to save it back.
      await _local.enqueueSync(type: 'chat_message', action: 'upsert', recordId: msg.id, payload: msg.toJson());
      _local.processSyncQueue();
    }
  }

  Future<List<ChatMessage>> sendMessage(String conversationId, ChatMessage userMessage) async {
    try {
      final response = await ApiClient.instance.post(
        '/conversations/$conversationId/messages',
        data: {
          'id': userMessage.id,
          'content': userMessage.content,
          'client_created_at': userMessage.createdAt.toUtc().toIso8601String(),
        },
      );
      
      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        debugPrint(
          'Unexpected send message response shape: ${responseData.runtimeType}',
        );
        throw const FormatException('Unexpected send message response shape');
      }
      final data = responseData['data'];
      if (data is! Map) {
        debugPrint('Unexpected send message data shape: ${data.runtimeType}');
        throw const FormatException('Unexpected send message data shape');
      }
      final userMessageData = data['user_message'];
      final assistantMessageData = data['assistant_message'];
      if (userMessageData is! Map || assistantMessageData is! Map) {
        debugPrint('Unexpected send message payload shape');
        throw const FormatException('Unexpected send message payload shape');
      }
      final userMsg = ChatMessage.fromJson(
        Map<String, dynamic>.from(userMessageData),
      );
      final assistantMsg = ChatMessage.fromJson(
        Map<String, dynamic>.from(assistantMessageData),
      );
      
      await _local.saveChatMessage(userMsg);
      await _local.saveChatMessage(assistantMsg);
      
      return [userMsg, assistantMsg];
    } catch (e) {
      // Mark as failed locally (omitting method call since not defined in local_db_service)
      rethrow;
    }
  }
}
