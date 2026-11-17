import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../storage/token_storage.dart';
import 'feature_flags_service.dart';
import 'local_db_service.dart';

class PlanAccessException extends ApiException {
  PlanAccessException(super.message) : super(statusCode: 403);
}

/// Per-account permissions from the server. Offline use is bounded by
/// the last verified subscription expiry; it never creates a plan.
class PlanAccessService {
  static final instance = PlanAccessService();
  Future<void> require(String feature) async {
    await requireUntil(feature);
  }

  /// Verified expiry lets a mounted premium screen close when access ends.
  Future<DateTime?> requireUntil(String feature) async {
    if (!FeatureFlagsService.instance.isEnabled('plan_access')) return null;
    final local = LocalDbService();
    final owner = local.activeUserId;
    final generation = TokenStorage.generation;
    final settings = await local.settingsBox();
    Map<String, dynamic>? permissions;
    try {
      final response = await ApiClient().get('/me/plan-access');
      final data = response.data['data'];
      if (data is! Map ||
          data['features'] is! List ||
          data['enforcement_enabled'] is! bool) {
        throw const FormatException('Invalid plan permissions');
      }
      permissions = Map<String, dynamic>.from(data);
      if (owner != local.activeUserId ||
          generation != TokenStorage.generation) {
        throw StateError('Account changed');
      }
      await settings.put('plan_access_v1', {
        'data': permissions,
        'checked_at': DateTime.now().toUtc().toIso8601String(),
      });
    } on ApiNetworkException {
      permissions = _cached(settings.get('plan_access_v1'));
    } on ApiTimeoutException {
      permissions = _cached(settings.get('plan_access_v1'));
    }
    if (owner != local.activeUserId || generation != TokenStorage.generation) {
      throw StateError('Account changed');
    }
    if (permissions == null) {
      throw PlanAccessException(
        'Connect to the internet to check your plan, then try again. Your existing records remain available.',
      );
    }
    if (permissions['enforcement_enabled'] == false) return null;
    final expiry = DateTime.tryParse('${permissions['expires_at']}');
    if ((expiry == null || expiry.isAfter(DateTime.now())) &&
        (permissions['features'] as List).contains(feature)) {
      return expiry;
    }
    throw PlanAccessException(
      const {
            'written_journal',
            'mood_checkin',
            'community_read',
          }.contains(feature)
          ? 'An active plan is needed for this action. Your existing records and emergency help remain available.'
          : 'This action needs an active Student or Premium plan. Your existing records remain available.',
    );
  }

  Map<String, dynamic>? _cached(dynamic cached) {
    if (cached is! Map || cached['data'] is! Map) return null;
    final checked = DateTime.tryParse('${cached['checked_at']}');
    if (checked == null) return null;
    final age = DateTime.now().difference(checked);
    if (age.isNegative) return null;
    final data = Map<String, dynamic>.from(cached['data'] as Map);
    final expiry = DateTime.tryParse('${data['expires_at']}');
    // Offline creation needs a finite verified entitlement. Missing or expired
    // permission never blocks reading existing records or emergency help.
    if (expiry == null || !expiry.isAfter(DateTime.now())) return null;
    return data;
  }
}
