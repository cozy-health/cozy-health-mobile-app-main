import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class JournalService {
  final ApiClient _apiClient;

  JournalService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getJournals({
    int page = 1,
    int perPage = 20,
  }) async {
    return _apiClient.get(
      ApiConstants.journals,
      query: {
        'page': page,
        'per_page': perPage,
      },
    );
  }

  Future<Map<String, dynamic>> createJournal({
    String? title,
    required String content,
    int? momentId,
  }) async {
    return _apiClient.post(
      ApiConstants.journals,
      body: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'content': content.trim(),
        if (momentId != null) 'moment_id': momentId,
      },
    );
  }

  Future<Map<String, dynamic>> updateJournal({
    required int journalId,
    String? title,
    required String content,
  }) async {
    return _apiClient.put(
      '${ApiConstants.journals}/$journalId',
      body: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'content': content.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> deleteJournal({
    required int journalId,
  }) async {
    return _apiClient.delete(
      '${ApiConstants.journals}/$journalId',
    );
  }
}