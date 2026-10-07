import 'package:flutter/foundation.dart';
import '../../../core/models/quiz_attempt.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class QuizRepository {
  final LocalDbService _local = LocalDbService();

  List<dynamic> _extractListData(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return data['data'] as List;
    }
    if (data is Map && data['data'] is Map) {
      final nested = data['data'] as Map;
      if (nested['data'] is List) return nested['data'] as List;
    }
    debugPrint('Unexpected quiz attempts response shape: ${data.runtimeType}');
    return const [];
  }

  Future<List<QuizAttempt>> fetchAttempts() async {
    try {
      final response = await ApiClient.instance.get('/quiz-attempts');
      final items = _extractListData(response.data)
          .whereType<Map>()
          .map((json) => QuizAttempt.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      for (final item in items) {
        await _local.saveQuizAttempt(item);
      }
      return items;
    } catch (e) {
      return _local.getAllQuizAttempts();
    }
  }

  Stream<List<QuizAttempt>> watchAttempts() {
    return _local.watchQuizAttempts();
  }

  Future<QuizAttempt> saveAttempt(QuizAttempt attempt) async {
    await _local.saveQuizAttempt(attempt);
    await _local.enqueueSync(type: 'quiz_attempt', action: 'upsert', recordId: attempt.id, payload: attempt.toJson());
    _local.processSyncQueue();
    return attempt;
  }
}
