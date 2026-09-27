import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ActivityService {
  final ApiClient _apiClient;

  ActivityService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getOverview() async {
    return _apiClient.get(ApiConstants.activityOverview);
  }

  Future<Map<String, dynamic>> getMoodChart({int days = 7}) async {
    return _apiClient.get(
      ApiConstants.activityMoodChart,
      query: {'days': days},
    );
  }

  Future<Map<String, dynamic>> getCommonTriggers() async {
    return _apiClient.get(ApiConstants.activityCommonTriggers);
  }

  Future<Map<String, dynamic>> getJournalStats() async {
    return _apiClient.get(ApiConstants.activityJournalStats);
  }

  Future<Map<String, dynamic>> getRecommendations() async {
    return _apiClient.get(ApiConstants.activityRecommendations);
  }
}