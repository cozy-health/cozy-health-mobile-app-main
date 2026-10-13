import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/storage/token_storage.dart';

class QuizInvitationService {
  QuizInvitationService._();
  static final instance = QuizInvitationService._();
  static const _storage = FlutterSecureStorage();
  static const _key = 'cozy_pending_quiz_invitation';
  bool _draining = false;
  bool _presented = false;
  static String? invitationToken(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.host != Uri.parse(ApiConstants.baseUrl).host ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    if (uri.pathSegments.length != 2 ||
        uri.pathSegments.first != 'quiz-invite') {
      return null;
    }
    final token = uri.pathSegments.last;
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(token) ? token : null;
  }

  Future<void> initialize() async {
    final links = AppLinks();
    links.uriLinkStream.listen((uri) {
      unawaited(_capture(uri));
    });
    final initial = await links.getInitialLink();
    if (initial != null) await _capture(initial);
    AppRouter.router.routeInformationProvider.addListener(drain);
    drain();
  }

  Future<void> _capture(Uri uri) async {
    final token = invitationToken(uri);
    if (token == null) return;
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'token': token,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    _presented = false;
    drain();
  }

  Future<String?> pending() async {
    final value = await _storage.read(key: _key);
    if (value == null) return null;
    try {
      final data = jsonDecode(value) as Map;
      final date = DateTime.parse(data['captured_at'] as String);
      if (DateTime.now().toUtc().difference(date) > const Duration(days: 7)) {
        await clear();
        return null;
      }
      return data['token'] as String;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    _presented = false;
  }

  void drain() async {
    if (_draining ||
        _presented ||
        AppRouter.navigatorKey.currentState == null) {
      return;
    }
    final path = AppRouter.router.routeInformationProvider.value.uri.path;
    if (const [
      '/',
      '/login',
      '/welcome',
      '/restore',
      '/onboarding',
      '/create-account',
      '/personalization',
      '/preparing-cozy',
      '/quiz-invitation',
    ].contains(path)) {
      return;
    }
    _draining = true;
    try {
      final owner = LocalDbService().activeUserId;
      if (owner == null ||
          await TokenStorage().getToken() == null ||
          await pending() == null) {
        return;
      }
      await LocalDbService().processSyncQueue(force: true);
      final response = await ApiClient.instance.get('/user/profile');
      if (owner != LocalDbService().activeUserId ||
          response.data['data']['onboarding_completed_at'] == null) {
        return;
      }
      _presented = true;
      AppRouter.router.push('/quiz-invitation');
    } catch (_) {
      /* Keep invitation for an authenticated retry. */
    } finally {
      _draining = false;
    }
  }
}
