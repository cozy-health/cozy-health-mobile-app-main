import 'package:flutter/foundation.dart';
import '../../../core/models/chat_conversation.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class ChatRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<ChatConversation>> fetchConversations() async {
    try {
      final response = await ApiClient.instance.get('/conversations');
      final items = (response.data['data'] as List).map((json) => ChatConversation.fromJson(json)).toList();
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
      final items = (response.data['data'] as List).map((json) => ChatMessage.fromJson(json)).toList();
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
    return conv;
  }
  
  Future<void> deleteConversation(String id) async {
    await _local.deleteChatConversation(id);
    await _local.enqueueSync(type: 'chat_conversation', action: 'delete', recordId: id);
    try {
      await ApiClient.instance.delete('/conversations/$id');
    } catch (e) {}
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
      
      final data = response.data['data'];
      final userMsg = ChatMessage.fromJson(data['user_message']);
      final assistantMsg = ChatMessage.fromJson(data['assistant_message']);
      
      await _local.saveChatMessage(userMsg);
      await _local.saveChatMessage(assistantMsg);
      
      return [userMsg, assistantMsg];
    } catch (e) {
      // Mark as failed locally (omitting method call since not defined in local_db_service)
      rethrow;
    }
  }
}