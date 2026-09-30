import '../../../core/constants/api_constants.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/response_data.dart';

class MoodService {
  final ApiClient _apiClient;

  MoodService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getFeelings() async {
    return responseMap(await _apiClient.get(ApiConstants.feelings, withAuth: false));
  }

  Future<Map<String, dynamic>> getFeelingExpressions() async {
    return responseMap(
      await _apiClient.get(ApiConstants.feelingExpressions, withAuth: false),
    );
  }

  Future<Map<String, dynamic>> getFeelingCauses() async {
    return responseMap(
      await _apiClient.get(ApiConstants.feelingCauses, withAuth: false),
    );
  }

  Future<Map<String, dynamic>> getCopingMechanisms() async {
    return responseMap(
      await _apiClient.get(ApiConstants.copingMechanisms, withAuth: false),
    );
  }

  Future<Map<String, dynamic>> getTodayCheckin() async {
    return responseMap(await _apiClient.get(ApiConstants.moodCheckinToday));
  }

  Future<Map<String, dynamic>> submitMoodCheckin({
    required int feelingExpId,
    required int intensity,
    required List<int> reasonIds,
    required List<int> copingMechanismIds,
    String? journal,
  }) async {
    return responseMap(await _apiClient.post(
      ApiConstants.moodCheckins,
      body: {
        'feeling_exp_id': feelingExpId,
        'intensity': intensity,
        'reason_ids': reasonIds,
        'coping_mechanism_ids': copingMechanismIds,
        if (journal != null && journal.trim().isNotEmpty)
          'journal': journal.trim(),
      },
    ));
  }
}
