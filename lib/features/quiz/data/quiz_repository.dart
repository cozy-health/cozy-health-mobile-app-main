import 'package:flutter/foundation.dart';
import '../../../core/models/quiz_attempt.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class QuizRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<QuizAttempt>> fetchAttempts() async {
    try {
      final response = await ApiClient.instance.get('/quiz-attempts');
      final items = (response.data['data'] as List).map((json) => QuizAttempt.fromJson(json)).toList();
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
