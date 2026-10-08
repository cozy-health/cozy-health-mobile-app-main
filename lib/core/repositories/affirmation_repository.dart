import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;
import '../api/api_client.dart';
import 'endpoint_cache.dart';

class AffirmationRepository {
  AffirmationRepository({EndpointCache? cache, DateTime Function()? now})
    : _cache = cache ?? EndpointCache(),
      _now = now ?? DateTime.now {
    if (!_initialized) {
      timezone_data.initializeTimeZones();
      _initialized = true;
    }
  }
  static bool _initialized = false;
  final EndpointCache _cache;
  final DateTime Function() _now;

  Future<DateTime> _localNow() async {
    final dashboard = await _cache.read('home_dashboard', allowStale: true);
    final name = dashboard?['timezone'] as String?;
    if (name != null) {
      try {
        return tz.TZDateTime.from(_now(), tz.getLocation(name));
      } on tz.LocationNotFoundException {
        /* Use device date until dashboard refreshes. */
      }
    }
    return _now().toLocal();
  }

  String _date(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>?> _today() async {
    final date = _date(await _localNow());
    final data = await _cache.read('affirmation_$date', allowStale: true);
    return data?['date'] == date ? data : null;
  }

  Future<String?> getCachedToday() async =>
      (await _today())?['body'] as String?;

  Future<String?> fetchToday() async {
    final cached = await _today();
    if (cached != null) return cached['body'] as String?;
    final scope = await _cache.owner();
    final response = await ApiClient.instance.get('/affirmations/today');
    final payload = response.data['data'];
    final date = payload == null
        ? _date(await _localNow())
        : payload['date'] as String;
    final body = payload == null ? null : payload['body'] as String;
    await _cache.write('affirmation_$date', {
      'date': date,
      'body': body,
    }, scope);
    return body;
  }

  /// Computes the next calendar midnight rather than assuming every day is 24 hours.
  Future<Duration> untilNextDay() async {
    final local = await _localNow();
    final midnight = local is tz.TZDateTime
        ? tz.TZDateTime(local.location, local.year, local.month, local.day + 1)
        : DateTime(local.year, local.month, local.day + 1);
    return midnight.difference(local);
  }
}
