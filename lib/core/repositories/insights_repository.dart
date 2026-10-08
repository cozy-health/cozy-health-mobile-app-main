import '../api/api_client.dart';
import 'endpoint_cache.dart';

class InsightsRepository {
  InsightsRepository({EndpointCache? cache})
    : _cache = cache ?? EndpointCache();
  final EndpointCache _cache;

  Future<List<Map<String, dynamic>>> fetchWeekly({int weeks = 1}) =>
      _fetch('weekly', 'weeks', 'weeks', weeks);
  Future<List<Map<String, dynamic>>> fetchTriggers({int days = 30}) =>
      _fetch('triggers', 'triggers', 'days', days);
  Future<List<Map<String, dynamic>>> fetchSleepMood({int days = 30}) =>
      _fetch('sleep-mood', 'points', 'days', days);

  Future<List<Map<String, dynamic>>?> getCachedWeekly({
    int weeks = 1,
    bool allowStale = false,
  }) => _read('weekly', 'weeks', weeks, allowStale);
  Future<List<Map<String, dynamic>>?> getCachedTriggers({
    int days = 30,
    bool allowStale = false,
  }) => _read('triggers', 'triggers', days, allowStale);
  Future<List<Map<String, dynamic>>?> getCachedSleepMood({
    int days = 30,
    bool allowStale = false,
  }) => _read('sleep-mood', 'points', days, allowStale);

  Future<List<Map<String, dynamic>>> _fetch(
    String path,
    String field,
    String param,
    int value,
  ) async {
    final scope = await _cache.owner();
    final response = await ApiClient.instance.get(
      '/insights/$path',
      queryParameters: {param: value},
    );
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    final rows = _rows(data[field]);
    await _cache.write('insights_${path}_$value', data, scope);
    return rows;
  }

  Future<List<Map<String, dynamic>>?> _read(
    String path,
    String field,
    int value,
    bool stale,
  ) async {
    final data = await _cache.read(
      'insights_${path}_$value',
      allowStale: stale,
    );
    return data == null ? null : _rows(data[field]);
  }

  List<Map<String, dynamic>> _rows(dynamic rows) => (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
}
