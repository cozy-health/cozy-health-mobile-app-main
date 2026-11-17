import '../api/api_client.dart';
import '../models/affirmation_assignment.dart';
import '../services/local_db_service.dart';
import 'endpoint_cache.dart';

class AffirmationRepository {
  Future<void> markRead() async {
    final scope = await owner();
    if (scope == null) return;
    final local = LocalDbService();
    final settings = await local.settingsBox();
    final now = local.accountTime(_now());
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (scope != await owner() ||
        settings.get('affirmation_read_date') == date) {
      return;
    }
    await local.enqueueSync(
      type: 'affirmation_read',
      action: 'upsert',
      recordId: date,
      payload: {'id': date, 'read_at': now.toUtc().toIso8601String()},
    );
    await settings.put('affirmation_read_date', date);
    if (scope == await owner()) await local.processSyncQueue();
  }

  AffirmationRepository({EndpointCache? cache, DateTime Function()? now})
    : _cache = cache ?? EndpointCache(),
      _now = now ?? DateTime.now;
  static const cacheKey = 'affirmation_assignment_v1';
  final EndpointCache _cache;
  final DateTime Function() _now;
  Future<String?> owner() async {
    if (LocalDbService().activeUserId?.startsWith('guest_') == true) {
      return null;
    }
    return _cache.owner();
  }

  Future<AffirmationAssignment?> cached({bool allowExpired = false}) async {
    final scope = await owner();
    if (scope == null) return null;
    final data = await _cache.read(cacheKey, allowStale: true);
    if (scope != await owner() || data?['assignment'] == null) {
      return null;
    }
    try {
      final assignment = AffirmationAssignment.fromJson(data!['assignment']);
      return allowExpired || !assignment.isExpired(_now()) ? assignment : null;
    } on FormatException {
      return null;
    }
  }

  Future<AffirmationAssignment?> fetchCurrent({bool force = false}) async {
    final scope = await owner();
    if (scope == null) return null;
    if (!force) {
      final saved = await cached();
      if (scope != await owner()) throw StateError('Session changed');
      if (saved != null) return saved;
    }
    final response = await (() async {
      try {
        return await ApiClient.instance.get('/affirmations/today');
      } catch (_) {
        if (scope != await owner()) throw StateError('Session changed');
        rethrow;
      }
    })();
    if (scope != await owner()) throw StateError('Session changed');
    final envelope = response.data;
    if (envelope is! Map || !envelope.containsKey('data')) {
      throw const FormatException('Invalid affirmation response');
    }
    final assignment = envelope['data'] == null
        ? null
        : AffirmationAssignment.fromJson(envelope['data']);
    await _cache.write(cacheKey, {'assignment': assignment?.toJson()}, scope);
    if (scope != await owner()) throw StateError('Session changed');
    return assignment;
  }
}
