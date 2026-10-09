import '../../../core/api/api_client.dart';
import '../../../core/api/response_data.dart';

class SessionRepository {
  final ApiClient _api;
  SessionRepository({ApiClient? api}) : _api = api ?? ApiClient();
  Future<List<Map<String, dynamic>>> list() async {
    final response = responseMap(await _api.get('/me/sessions'));
    return (response['data'] as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> revoke(String id) async {
    await _api.delete('/me/sessions/$id');
  }

  Future<void> revokeAll() async {
    await _api.delete('/me/sessions');
  }
}
