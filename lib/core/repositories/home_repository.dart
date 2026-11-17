import '../api/api_client.dart';
import 'endpoint_cache.dart';
import '../services/local_db_service.dart';
import '../models/mood_entry.dart';

class DashboardData {
  DashboardData({
    required this.todayMood,
    required this.streakDays,
    required this.weeklyMoods,
    required this.recentEntries,
    required this.timezone,
    this.accountId,
  });
  final Map<String, dynamic>? todayMood;
  final int streakDays;
  final List<Map<String, dynamic>> weeklyMoods;
  final List<Map<String, dynamic>> recentEntries;
  final String timezone;
  final String? accountId;

  List<MoodEntry> recentMoods(List<MoodEntry> local, {int limit = 3}) {
    final merged = {for (final entry in local) entry.id: entry};
    for (final row in recentEntries) {
      final timestamp = row['client_created_at'] ?? row['created_at'];
      if (timestamp == null || merged.containsKey(row['id'])) continue;
      final entry = MoodEntry.fromJson({
        ...row,
        'client_created_at': timestamp,
        'client_updated_at': row['client_updated_at'] ?? timestamp,
      });
      merged[entry.id] = entry;
    }
    final ordered = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ordered.take(limit).toList();
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    todayMood: json['today_mood'] is Map
        ? Map<String, dynamic>.from(json['today_mood'])
        : null,
    streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
    weeklyMoods: _rows(json['weekly_moods']),
    recentEntries: _rows(json['recent_entries']),
    timezone: json['timezone'] as String? ?? 'UTC',
    accountId: json['account_id']?.toString(),
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

  Future<dynamic> _ownedRequest(
    String path,
    String? scope,
    String? account,
  ) async {
    try {
      return await ApiClient.instance.get(path);
    } catch (_) {
      if (scope != await _cache.owner() ||
          account != LocalDbService().activeUserId) {
        throw StateError('The signed-in account changed.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchStreak() async {
    final scope = await _cache.owner();
    final account = LocalDbService().activeUserId;
    if (scope == null) throw StateError('Sign in to view your streak.');
    final response = await _ownedRequest('/wellness/streak', scope, account);
    if (scope != await _cache.owner() ||
        account != LocalDbService().activeUserId) {
      throw StateError('The signed-in account changed.');
    }
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    if (account != null && data['account_id']?.toString() != account) {
      throw StateError('The streak belongs to a different account.');
    }
    await _cache.write('streak_progress', data, scope);
    if (scope != await _cache.owner() ||
        account != LocalDbService().activeUserId) {
      throw StateError('The signed-in account changed.');
    }
    return data;
  }

  Future<Map<String, dynamic>?> getCachedStreak() async {
    final account = LocalDbService().activeUserId;
    final data = await _cache.read('streak_progress', allowStale: true);
    if (account != LocalDbService().activeUserId) return null;
    if (account != null && data?['account_id']?.toString() != account) {
      return null;
    }
    return data;
  }

  Future<DashboardData> fetchDashboard() async {
    final scope = await _cache.owner();
    final account = LocalDbService().activeUserId;
    final response = await _ownedRequest('/dashboard', scope, account);
    if (scope != await _cache.owner() ||
        account != LocalDbService().activeUserId) {
      throw StateError('The signed-in account changed.');
    }
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    final dashboard = DashboardData.fromJson(data);
    if (account != null && dashboard.accountId != account) {
      throw StateError('The dashboard belongs to a different account.');
    }
    await _cache.write('home_dashboard', data, scope);
    if (scope != await _cache.owner() ||
        account != LocalDbService().activeUserId) {
      throw StateError('The signed-in account changed.');
    }
    return dashboard;
  }

  Future<DashboardData?> getCachedDashboard({bool allowStale = false}) async {
    final account = LocalDbService().activeUserId;
    final data = await _cache.read('home_dashboard', allowStale: allowStale);
    if (account != LocalDbService().activeUserId) return null;
    if (account != null && data?['account_id']?.toString() != account) {
      return null;
    }
    return data == null ? null : DashboardData.fromJson(data);
  }
}
