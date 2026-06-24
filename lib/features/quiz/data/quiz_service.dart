import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class QuizService {
  final ApiClient _apiClient;

  QuizService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getQuizzes() async {
    return _apiClient.get(
      ApiConstants.quizzes,
      withAuth: false,
    );
  }

  Future<Map<String, dynamic>> getQuiz({
    required int quizId,
  }) async {
    return _apiClient.get(
      '${ApiConstants.quizzes}/$quizId',
      withAuth: false,
    );
  }

  Future<Map<String, dynamic>> submitQuiz({
    required int quizId,
    required List<Map<String, int>> answers,
  }) async {
    return _apiClient.post(
      '${ApiConstants.quizzes}/$quizId/submit',
      body: {
        'answers': answers,
      },
    );
  }

  Future<Map<String, dynamic>> getMyResults({
    int page = 1,
    int perPage = 20,
  }) async {
    return _apiClient.get(
      ApiConstants.quizResults,
      query: {
        'page': page,
        'per_page': perPage,
      },
    );
  }
}