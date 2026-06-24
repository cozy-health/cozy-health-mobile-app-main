import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class MoodService {
  final ApiClient _apiClient;

  MoodService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getFeelings() async {
    return _apiClient.get(ApiConstants.feelings, withAuth: false);
  }

  Future<Map<String, dynamic>> getFeelingExpressions() async {
    return _apiClient.get(ApiConstants.feelingExpressions, withAuth: false);
  }

  Future<Map<String, dynamic>> getFeelingCauses() async {
    return _apiClient.get(ApiConstants.feelingCauses, withAuth: false);
  }

  Future<Map<String, dynamic>> getCopingMechanisms() async {
    return _apiClient.get(ApiConstants.copingMechanisms, withAuth: false);
  }

  Future<Map<String, dynamic>> getTodayCheckin() async {
    return _apiClient.get(ApiConstants.moodCheckinToday);
  }

  Future<Map<String, dynamic>> submitMoodCheckin({
    required int feelingExpId,
    required int intensity,
    required List<int> reasonIds,
    required List<int> copingMechanismIds,
    String? journal,
  }) async {
    return _apiClient.post(
      ApiConstants.moodCheckins,
      body: {
        'feeling_exp_id': feelingExpId,
        'intensity': intensity,
        'reason_ids': reasonIds,
        'coping_mechanism_ids': copingMechanismIds,
        if (journal != null && journal.trim().isNotEmpty)
          'journal': journal.trim(),
      },
    );
  }
}