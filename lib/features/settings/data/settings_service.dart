import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/api/response_data.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/services/network_status.dart';

class SettingsService {
  final ApiClient _apiClient;

  SettingsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  void _requireOnline() {
    if (networkOffline.value == true) throw ApiNetworkException();
  }

  Future<void> _invalidateProviderCache(String? owner) async {
    final local = LocalDbService();
    if (owner != local.activeUserId ||
        !local.isBoxOpen(LocalDbService.userSettingsBoxName)) {
      return;
    }
    final settings = await local.settingsBox();
    if (owner != local.activeUserId) return;
    await settings.deleteAll(
      settings.keys
          .where(
            (key) =>
                key == 'linked_provider_v1' ||
                key == 'provider_conversations_v1' ||
                key.toString().startsWith('provider_resources_v1:'),
          )
          .toList(),
    );
  }

  Future<Map<String, dynamic>> _providerRead(
    String path,
    String cacheKey, {
    Map<String, dynamic>? query,
  }) async {
    final local = LocalDbService();
    final owner = local.activeUserId;
    final settings = local.isBoxOpen(LocalDbService.userSettingsBoxName)
        ? await local.settingsBox()
        : null;
    Map<String, dynamic>? cached() {
      if (owner != local.activeUserId) return null;
      final value = settings?.get(cacheKey);
      return value is Map
          ? Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map)
          : null;
    }

    if (networkOffline.value == true) {
      return cached() ?? (throw ApiNetworkException());
    }
    try {
      final value = responseMap(
        await _apiClient.get(path, queryParameters: query),
      );
      if (owner != local.activeUserId) throw StateError('Account changed');
      await settings?.put(cacheKey, value);
      return value;
    } on ApiNetworkException {
      final value = cached();
      if (value == null) rethrow;
      return value;
    } on ApiTimeoutException {
      final value = cached();
      if (value == null) rethrow;
      return value;
    }
  }

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
    return _providerRead(ApiConstants.provider, 'linked_provider_v1');
  }

  Future<Map<String, dynamic>> requestProvider({
    required String providerEmail,
    String? providerName,
    Map<String, bool>? consentFlags,
  }) async {
    _requireOnline();
    return responseMap(
      await _apiClient.post(
        ApiConstants.providerRequest,
        body: {
          'provider_email': providerEmail,
          if (consentFlags != null) ...{
            'verification_actor': 'provider',
            'consent_flags': consentFlags,
          },
          if (providerName != null) 'provider_name': providerName,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> verifyProvider({required String code}) async {
    _requireOnline();
    return responseMap(
      await _apiClient.post(ApiConstants.providerVerify, body: {'code': code}),
    );
  }

  Future<Map<String, dynamic>> removeProvider() async {
    _requireOnline();
    final owner = LocalDbService().activeUserId;
    final result = responseMap(await _apiClient.delete(ApiConstants.provider));
    await _invalidateProviderCache(owner);
    return result;
  }

  Future<void> cancelProviderInvitation(String linkId) async {
    _requireOnline();
    await _apiClient.delete(
      '/provider/invitations/${Uri.encodeComponent(linkId)}',
    );
  }

  Future<void> updateConsent({
    required String linkId,
    required String consentType,
    required bool value,
  }) async {
    _requireOnline();
    final owner = LocalDbService().activeUserId;
    await _apiClient.patch(
      '/me/provider/${Uri.encodeComponent(linkId)}/consent',
      body: {'consent_type': consentType, 'value': value},
    );
    await _invalidateProviderCache(owner);
  }

  Future<void> revokeProviderAccess(String linkId) async {
    _requireOnline();
    final owner = LocalDbService().activeUserId;
    await _apiClient.delete('/me/provider/${Uri.encodeComponent(linkId)}');
    await _invalidateProviderCache(owner);
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

  Future<Map<String, dynamic>> getProviderResources({int page = 1}) async {
    return _providerRead(
      '/me/resources',
      'provider_resources_v1:$page',
      query: {'page': page},
    );
  }

  Future<Map<String, dynamic>> updateProviderResource({
    required String assignmentId,
    required String status,
  }) async {
    _requireOnline();
    return responseMap(
      await _apiClient.patch(
        '/me/resources/${Uri.encodeComponent(assignmentId)}',
        body: {'status': status},
      ),
    );
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
