import '../../../core/constants/api_constants.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/response_data.dart';

class SettingsService {
  final ApiClient _apiClient;

  SettingsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getProfile() async {
    return responseMap(await _apiClient.get(ApiConstants.me));
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstname,
    required String lastname,
    String? username,
  }) async {
    return responseMap(
      await _apiClient.put(
        ApiConstants.me,
        body: {
          'firstname': firstname,
          'lastname': lastname,
          if (username != null) 'username': username,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getProvider() async {
    return responseMap(await _apiClient.get(ApiConstants.provider));
  }

  Future<Map<String, dynamic>> requestProvider({
    required String providerEmail,
    String? providerName,
  }) async {
    return responseMap(
      await _apiClient.post(
        ApiConstants.providerRequest,
        body: {
          'provider_email': providerEmail,
          if (providerName != null) 'provider_name': providerName,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> verifyProvider({required String code}) async {
    return responseMap(
      await _apiClient.post(ApiConstants.providerVerify, body: {'code': code}),
    );
  }

  Future<Map<String, dynamic>> removeProvider() async {
    return responseMap(await _apiClient.delete(ApiConstants.provider));
  }

  Future<void> updateConsent({
    required String linkId,
    required String consentType,
    required bool value,
  }) async {
    await _apiClient.patch(
      '/me/provider/${Uri.encodeComponent(linkId)}/consent',
      body: {'consent_type': consentType, 'value': value},
    );
  }

  Future<void> revokeProviderAccess(String linkId) async {
    await _apiClient.delete('/me/provider/${Uri.encodeComponent(linkId)}');
  }

  Future<Map<String, dynamic>> getProviderAccessLog({int page = 1}) async {
    return responseMap(
      await _apiClient.get(
        '/me/provider-access-log',
        queryParameters: {'page': page},
      ),
    );
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
    return responseMap(
      await _apiClient.post(
        ApiConstants.subscriptionActivate,
        body: {'package_id': packageId},
      ),
    );
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    return responseMap(await _apiClient.post(ApiConstants.subscriptionCancel));
  }
}
