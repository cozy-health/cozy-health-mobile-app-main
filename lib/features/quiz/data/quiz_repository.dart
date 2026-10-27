import '../../../core/api/api_exceptions.dart';
import '../../../core/models/quiz_attempt.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/user_data_fetcher.dart';
import '../../../core/services/plan_access_service.dart';
import '../domain/clinical_assessment.dart';

class QuizRepository {
  final LocalDbService _local = LocalDbService();
  Future<List<ClinicalAssessment>> catalog() async {
    final owner = _local.activeUserId;
    final settings = await _local.settingsBox();
    try {
      final rows = <Map<String, dynamic>>[];
      var page = 1;
      var lastPage = 1;
      do {
        final response = await ApiClient.instance.get(
          '/quizzes',
          queryParameters: {'page': page, 'per_page': 50},
        );
        if (owner != _local.activeUserId) return [];
        final data = response.data['data'] as Map;
        rows.addAll(
          (data['data'] as List).map(
            (row) => Map<String, dynamic>.from(row as Map),
          ),
        );
        lastPage = (data['last_page'] as num).toInt();
        page++;
      } while (page <= lastPage && page <= 100);
      await settings.put('quiz_definitions_v1', rows);
      return rows.map(ClinicalAssessment.fromDefinition).toList();
    } catch (error) {
      // Only cached, previously approved definitions can be taken offline.
      if (owner != _local.activeUserId) return [];
      if (error is ApiAuthException ||
          error is ApiServerException ||
          (error is ApiException && error.statusCode != null)) {
        rethrow;
      }
      final cached = settings.get('quiz_definitions_v1') as List?;
      if (cached == null || cached.isEmpty) rethrow;
      return (settings.get('quiz_definitions_v1') as List? ?? [])
          .map(
            (row) => ClinicalAssessment.fromDefinition(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    }
  }

  Future<List<QuizAttempt>> fetchAttempts() async {
    await UserDataFetcher().fetchQuizAttempts();
    return _local.getAllQuizAttempts();
  }

  Stream<List<QuizAttempt>> watchAttempts() {
    return _local.watchQuizAttempts();
  }

  Future<QuizAttempt> saveAttempt(QuizAttempt attempt) async {
    final owner = _local.activeUserId;
    await PlanAccessService.instance.require('assessments');
    if (owner != _local.activeUserId) throw StateError('Account changed');
    await _local.saveQuizAttempt(attempt);
    await _local.enqueueSync(
      type: 'quiz_attempt',
      action: 'upsert',
      recordId: attempt.id,
      payload: attempt.toJson(),
    );
    _local.processSyncQueue();
    return attempt;
  }

  Future<void> deleteAttempt(String id) async {
    await _local.enqueueSync(
      type: 'quiz_attempt',
      action: 'delete',
      recordId: id,
      payload: {'id': id},
    );
    await _local.quizAttemptBox.delete(id);
    _local.processSyncQueue();
  }
}
