import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/community/data/community_moderation_state.dart';
import '../../support/repository_fixture.dart';
import '../../support/mobile_sync_contract.dart';

class DelayedModeration implements HttpClientAdapter {
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancelFuture,
  ) async {
    entered.complete();
    await release.future;
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'active_ban': {'reason': 'Account A private moderation'},
          'decisions': [],
          'appeals': [],
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  final fixture = RepositoryFixture<MoodEntry>(
    LocalDbService.moodBoxName,
    MoodEntryAdapter(),
  );
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await fixture.open();
    registerSyncAdapters();
    local.syncPaused = true;
  });
  tearDownAll(() async {
    await fixture.close();
  });
  test(
    'late moderation response cannot populate the next account and status clears immediately on account switch',
    () async {
      await local.activateAccount('moderation-A');
      await TokenStorage().saveToken('moderation-token-A');
      final state = CommunityModerationState.instance;
      final transport = ApiClient().transportForTesting;
      final delayed = DelayedModeration();
      ApiClient().transportForTesting = delayed;
      state.data = {
        'active_ban': {'reason': 'Previously loaded account A'},
        'decisions': [],
        'appeals': [],
      };
      final pending = state.refresh();
      await delayed.entered.future;
      await local.activateAccount('moderation-B');
      await TokenStorage().saveToken('moderation-token-B');
      expect(state.data, isNull);
      delayed.release.complete();
      await pending;
      expect(state.data, isNull);
      ApiClient().transportForTesting = transport;
      fixture.body = {
        'data': {'active_ban': null, 'decisions': [], 'appeals': []},
      };
      await state.refresh();
      expect(state.data?['active_ban'], isNull);
      expect(state.data?['decisions'], isEmpty);
    },
  );
}
