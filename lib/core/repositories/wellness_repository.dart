import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../data/demo_mode.dart';

class WellnessRepository {
  Future<Map<String, dynamic>?> catalog() async {
    SharedPreferences? preferences;
    String? cached;
    try {
      preferences = await SharedPreferences.getInstance();
      cached = preferences.getString('cozy.wellness.catalog.v1');
    } catch (_) {
      /* Network remains usable if cache cannot be read. */
    }
    Map<String, dynamic>? fallback;
    try {
      if (cached != null) {
        fallback = Map<String, dynamic>.from(jsonDecode(cached) as Map);
      }
    } catch (_) {
      /* Ignore obsolete cache. */
    }
    if (DemoMode.instance.enabled) return null;
    try {
      final response = await ApiClient.instance.get('/wellness/catalog');
      final payload = Map<String, dynamic>.from(response.data['data'] as Map);
      try {
        await preferences?.setString(
          'cozy.wellness.catalog.v1',
          jsonEncode(payload),
        );
      } catch (_) {
        /* A cache failure must not hide fresh content. */
      }
      return payload;
    } catch (_) {
      return fallback;
    }
  }

  Future<List<Map<String, dynamic>>> challenges() async {
    final response = await ApiClient.instance.get('/wellness/challenges');
    return (response.data['data'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> enroll(int id) async {
    await ApiClient.instance.post('/wellness/challenges/$id/enroll', data: {});
  }

  Future<void> complete(int id, int day) async {
    await ApiClient.instance.post(
      '/wellness/challenges/$id/complete',
      data: {'day': day},
    );
  }
}
