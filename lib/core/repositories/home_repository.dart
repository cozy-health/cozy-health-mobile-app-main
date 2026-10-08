import '../api/api_client.dart';
import 'endpoint_cache.dart';

class DashboardData {
  DashboardData({
    required this.todayMood,
    required this.streakDays,
    required this.weeklyMoods,
    required this.recentEntries,
    required this.timezone,
  });
  final Map<String, dynamic>? todayMood;
  final int streakDays;
  final List<Map<String, dynamic>> weeklyMoods;
  final List<Map<String, dynamic>> recentEntries;
  final String timezone;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    todayMood: json['today_mood'] is Map
        ? Map<String, dynamic>.from(json['today_mood'])
        : null,
    streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
    weeklyMoods: _rows(json['weekly_moods']),
    recentEntries: _rows(json['recent_entries']),
    timezone: json['timezone'] as String? ?? 'UTC',
  );
  static List<Map<String, dynamic>> _rows(dynamic value) =>
      (value as List? ?? [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
}

class HomeRepository {
  HomeRepository({EndpointCache? cache}) : _cache = cache ?? EndpointCache();
  final EndpointCache _cache;

  Future<DashboardData> fetchDashboard() async {
    final scope = await _cache.owner();
    final response = await ApiClient.instance.get('/dashboard');
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    final dashboard = DashboardData.fromJson(data);
    await _cache.write('home_dashboard', data, scope);
    return dashboard;
  }

  Future<DashboardData?> getCachedDashboard({bool allowStale = false}) async {
    final data = await _cache.read('home_dashboard', allowStale: allowStale);
    return data == null ? null : DashboardData.fromJson(data);
  }
}
