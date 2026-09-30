import '../../../core/constants/api_constants.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/response_data.dart';

class ActivityService {
  final ApiClient _apiClient;

  ActivityService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getOverview() async {
    return responseMap(await _apiClient.get(ApiConstants.activityOverview));
  }

  Future<Map<String, dynamic>> getMoodChart({int days = 7}) async {
    return responseMap(await _apiClient.get(
      ApiConstants.activityMoodChart,
      query: {'days': days},
    ));
  }

  Future<Map<String, dynamic>> getCommonTriggers() async {
    return responseMap(await _apiClient.get(ApiConstants.activityCommonTriggers));
  }

  Future<Map<String, dynamic>> getJournalStats() async {
    return responseMap(await _apiClient.get(ApiConstants.activityJournalStats));
  }

  Future<Map<String, dynamic>> getRecommendations() async {
    return responseMap(await _apiClient.get(ApiConstants.activityRecommendations));
  }
}
