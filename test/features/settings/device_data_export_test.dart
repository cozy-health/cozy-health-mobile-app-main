import 'dart:async';
import 'dart:convert';

import 'package:cozy_health/core/models/chat_conversation.dart';
import 'package:cozy_health/core/models/chat_message.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/settings/presentation/screens/data_export_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

class ExportBox<T> extends Fake implements Box<T> {
  final writes = <dynamic, dynamic>{};
  @override
  Iterable<T> get values => <T>[];
  @override
  Future<void> put(dynamic key, dynamic value) async {
    writes[key] = value;
  }
}

class ExportLocal extends Fake implements LocalDbService {
  String? owner = 'synthetic-export-A';
  final settings = ExportBox<dynamic>();
  final storageReady = Completer<Box<dynamic>>();
  bool delayStorage = false, waitingForStorage = false;
  @override
  String? get activeUserId => owner;
  @override
  UserProfile? getUserProfile() => null;
  @override
  List<MoodEntry> getAllMoodEntries() => [];
  @override
  List<JournalEntry> getAllJournalEntries() => [
    JournalEntry(
      id: 'synthetic-journal',
      type: 'voice',
      body: 'Synthetic reflection',
      localVoicePath: '/private/synthetic-recording.m4a',
      wordCount: 2,
      createdAt: DateTime.utc(2026, 11, 22),
      updatedAt: DateTime.utc(2026, 11, 22),
    ),
  ];
  @override
  List<ChatConversation> getAllChatConversations() => [];
  @override
  Box<ChatMessage> get chatMessageBox => ExportBox<ChatMessage>();
  @override
  Future<Box<dynamic>> settingsBox() {
    waitingForStorage = true;
    return delayStorage ? storageReady.future : Future.value(settings);
  }
}

class ExportTokens extends Fake implements TokenStorage {
  int reads = 0;
  Future<String?> Function()? read;
  @override
  Future<String?> getToken() {
    reads++;
    return read?.call() ?? Future.value('fixture-token');
  }
}

class ExportSharing extends Fake implements SharePlus {
  final params = <ShareParams>[];
  Completer<ShareResult>? pending;
  bool fail = false;
  ShareResultStatus status = ShareResultStatus.dismissed;
  @override
  Future<ShareResult> share(ShareParams value) {
    params.add(value);
    if (fail) return Future.error(StateError('synthetic share failure'));
    return pending?.future ?? Future.value(ShareResult('fixture', status));
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  Future<void> mount(
    WidgetTester tester,
    ExportLocal local,
    ExportTokens tokens,
    ExportSharing sharing,
  ) => tester.pumpWidget(
    MaterialApp(
      home: DataExportScreen(local: local, tokens: tokens, sharing: sharing),
    ),
  );
  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }
  }

  VoidCallback action(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!;

  testWidgets(
    'device export rejects duplicate activation while token lookup waits',
    (tester) async {
      final local = ExportLocal(),
          tokens = ExportTokens(),
          sharing = ExportSharing();
      final token = Completer<String?>();
      tokens.read = () => token.future;
      await mount(tester, local, tokens, sharing);
      final start = action(tester);
      start();
      start();
      final reads = tokens.reads;
      token.complete(null);
      await flush(tester);
      expect(reads, 1);
      expect(sharing.params, isEmpty);
      expect(find.text('Sign in to export your account data.'), findsOneWidget);
    },
  );

  testWidgets(
    'device export never opens sharing after an account changes during storage preparation',
    (tester) async {
      final local = ExportLocal()..delayStorage = true,
          tokens = ExportTokens(),
          sharing = ExportSharing();
      await mount(tester, local, tokens, sharing);
      action(tester)();
      await flush(tester);
      expect(local.waitingForStorage, isTrue);
      local.owner = 'synthetic-export-B';
      local.storageReady.complete(local.settings);
      await flush(tester);
      expect(sharing.params, isEmpty);
      expect(local.settings.writes, isEmpty);
    },
  );

  testWidgets(
    'device export rejects a replaced session of the same account before sharing',
    (tester) async {
      final local = ExportLocal()..delayStorage = true,
          tokens = ExportTokens(),
          sharing = ExportSharing();
      await mount(tester, local, tokens, sharing);
      action(tester)();
      await flush(tester);
      await TokenStorage().saveSession(
        'replacement-fixture',
        stayLoggedIn: false,
      );
      local.storageReady.complete(local.settings);
      await flush(tester);
      expect(sharing.params, isEmpty);
      expect(local.settings.writes, isEmpty);
    },
  );

  testWidgets(
    'late share success cannot mark a replacement session as exported',
    (tester) async {
      final local = ExportLocal(),
          tokens = ExportTokens(),
          sharing = ExportSharing()..pending = Completer<ShareResult>();
      await mount(tester, local, tokens, sharing);
      action(tester)();
      await flush(tester);
      expect(sharing.params, hasLength(1));
      await TokenStorage().saveSession(
        'another-fixture-session',
        stayLoggedIn: false,
      );
      sharing.pending!.complete(
        const ShareResult('fixture', ShareResultStatus.success),
      );
      await flush(tester);
      expect(local.settings.writes, isEmpty);
      expect(find.text('Export shared.'), findsNothing);
    },
  );

  testWidgets(
    'cancelled device export is truthful and omits private local audio paths',
    (tester) async {
      final local = ExportLocal(),
          tokens = ExportTokens(),
          sharing = ExportSharing();
      await mount(tester, local, tokens, sharing);
      action(tester)();
      await flush(tester);
      final params = sharing.params.single;
      final payload =
          jsonDecode(await params.files!.single.readAsString())
              as Map<String, dynamic>;
      expect(
        payload['scope'],
        contains('Cloud-only records and audio files are not included'),
      );
      expect(payload['journals'], hasLength(1));
      expect(
        (payload['journals'] as List).single,
        isNot(contains('local_voice_path')),
      );
      expect(local.settings.writes, isEmpty);
      expect(
        find.text(
          'The share sheet closed. No download or delivery has been confirmed.',
        ),
        findsOneWidget,
      );
      expect(params.fileNameOverrides, ['cozy-device-data.json']);
    },
  );

  testWidgets(
    'failed device export permits retry and records confirmed share success',
    (tester) async {
      final local = ExportLocal(),
          tokens = ExportTokens(),
          sharing = ExportSharing()..fail = true;
      await mount(tester, local, tokens, sharing);
      action(tester)();
      await flush(tester);
      expect(
        find.text('Could not create or share the export. Please retry.'),
        findsOneWidget,
      );
      sharing.fail = false;
      sharing.status = ShareResultStatus.success;
      action(tester)();
      await flush(tester);
      expect(sharing.params, hasLength(2));
      expect(local.settings.writes['last_device_export'], isA<String>());
      expect(find.text('Export shared.'), findsOneWidget);
    },
  );
}
