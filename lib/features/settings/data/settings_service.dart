import '../../../core/constants/api_constants.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/response_data.dart';

class SettingsService {
  final ApiClient _apiClient;

  SettingsService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getProfile() async {
    return responseMap(await _apiClient.get(ApiConstants.me));
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstname,
    required String lastname,
    String? username,
  }) async {
    return responseMap(await _apiClient.put(
      ApiConstants.me,
      body: {
        'firstname': firstname,
        'lastname': lastname,
        if (username != null) 'username': username,
      },
    ));
  }

  Future<Map<String, dynamic>> getSubscription() async {
    return responseMap(await _apiClient.get(ApiConstants.subscription));
  }

  Future<Map<String, dynamic>> getPackages() async {
    return responseMap(await _apiClient.get(ApiConstants.subscriptionPackages));
  }

  Future<Map<String, dynamic>> activateSubscription({
    required int packageId,
  }) async {
    return responseMap(await _apiClient.post(
      ApiConstants.subscriptionActivate,
      body: {
        'package_id': packageId,
      },
    ));
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    return responseMap(await _apiClient.post(ApiConstants.subscriptionCancel));
  }
}
