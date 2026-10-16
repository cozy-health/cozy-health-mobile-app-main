import '../api/api_client.dart';
import '../models/affirmation_assignment.dart';
import '../services/local_db_service.dart';
import 'endpoint_cache.dart';

class AffirmationRepository {
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
    final response = await ApiClient.instance.get('/affirmations/today');
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
