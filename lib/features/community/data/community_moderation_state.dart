import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/data/demo_mode.dart';
import '../../../core/services/local_db_service.dart';

class CommunityModerationState extends ChangeNotifier {
  @visibleForTesting
  CommunityModerationState.testing();
  CommunityModerationState._() {
    LocalDbService().accountChanges.listen((_) {
      _generation++;
      data = null;
      error = null;
      notifyListeners();
    });
  }
  static final instance = CommunityModerationState._();
  int _generation = 0;
  Map<String, dynamic>? data;
  String? error;
  bool get restricted =>
      !DemoMode.instance.enabled && data?['active_ban'] is Map;

  Future<void> refresh() async {
    if (DemoMode.instance.enabled) return;
    final generation = _generation;
    final owner = LocalDbService().activeUserId;
    try {
      final response = await ApiClient().get('/community/moderation');
      if (generation != _generation || owner != LocalDbService().activeUserId) {
        return;
      }
      final envelope = response is Response ? response.data : response;
      final value = envelope is Map ? envelope['data'] : null;
      if (value is! Map) {
        throw const FormatException('Invalid moderation status');
      }
      data = Map<String, dynamic>.from(value);
      error = null;
    } catch (_) {
      if (generation != _generation || owner != LocalDbService().activeUserId) {
        return;
      }
      error =
          'Community moderation status could not be refreshed. Try again online.';
    }
    notifyListeners();
  }

  Future<void> appeal(String decision, String message) async {
    final generation = _generation;
    final owner = LocalDbService().activeUserId;
    await ApiClient().post(
      '/community/decisions/$decision/appeal',
      data: {'message': message},
    );
    if (generation != _generation || owner != LocalDbService().activeUserId) {
      return;
    }
    await refresh();
  }
}
