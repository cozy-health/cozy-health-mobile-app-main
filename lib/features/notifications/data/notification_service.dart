import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    return _apiClient.get(
      ApiConstants.notifications,
      query: {
        'page': page,
        'per_page': perPage,
      },
    );
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    return _apiClient.get(ApiConstants.notificationUnreadCount);
  }

  Future<Map<String, dynamic>> markAsRead(String id) async {
    return _apiClient.post('/notifications/$id/read');
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    return _apiClient.post('/notifications/read-all');
  }

  Future<Map<String, dynamic>> deleteNotification(String id) async {
    return _apiClient.delete('/notifications/$id');
  }
}