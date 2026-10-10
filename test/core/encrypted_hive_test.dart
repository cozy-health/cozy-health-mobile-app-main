import 'dart:convert';
import 'dart:io';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/chat_conversation.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const secure = FlutterSecureStorage();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await EncryptedHive.prepareInstall(markerSet: true, hasLocalFiles: false);
    directory = await Directory.systemTemp.createTemp('cozy_crypto_');
    Hive.init(directory.path);
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(ChatConversationAdapter());
  });
  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  test(
    'empty reinstall reuses retained keys without deleting secure metadata',
    () async {
      final original = await EncryptedHive.openBox<String>('queue');
      await original.close();
      final before = await secure.readAll();
      await Hive.deleteBoxFromDisk(EncryptedHive.physicalName('queue'));
      await EncryptedHive.prepareInstall(
        markerSet: false,
        hasLocalFiles: false,
      );
      expect((await EncryptedHive.openBox<String>('queue')).isEmpty, isTrue);
      expect(await secure.readAll(), before);
    },
  );

  for (final hasFiles in [false, true]) {
    test(
      'missing box blocks when marker or other local files exist: $hasFiles',
      () async {
        await secure.write(key: 'hive_migrated_v1_queue', value: '1');
        await EncryptedHive.prepareInstall(
          markerSet: !hasFiles,
          hasLocalFiles: hasFiles,
        );
        await expectLater(
          EncryptedHive.openBox<String>('queue'),
          throwsStateError,
        );
        expect(await secure.read(key: 'hive_migrated_v1_queue'), '1');
      },
    );
  }

  test(
    'account boxes reopen after reinstall then restart before login',
    () async {
      final base = await EncryptedHive.openBox<String>('queue');
      final account = await EncryptedHive.openBox<String>('queue_user_31');
      await base.close();
      await account.close();
      final retained = await secure.readAll();
      await Hive.deleteBoxFromDisk(EncryptedHive.physicalName('queue'));
      await Hive.deleteBoxFromDisk(EncryptedHive.physicalName('queue_user_31'));
      await EncryptedHive.prepareInstall(
        markerSet: false,
        hasLocalFiles: false,
      );
      await (await EncryptedHive.openBox<String>('queue')).close();
      // A later launch has an install marker and base files, but the account
      // databases have not been recreated yet because login has not happened.
      await EncryptedHive.prepareInstall(markerSet: true, hasLocalFiles: true);
      final recreated = await EncryptedHive.openBox<String>('queue_user_31');
      await recreated.put('pending', 'new local data');
      await recreated.close();
      expect(await secure.readAll(), retained);
      await EncryptedHive.prepareInstall(markerSet: true, hasLocalFiles: true);
      expect(
        (await EncryptedHive.openBox<String>('queue_user_31')).get('pending'),
        'new local data',
      );
      await Hive.close();
      await Hive.deleteBoxFromDisk(EncryptedHive.physicalName('queue_user_31'));
      await expectLater(
        EncryptedHive.openBox<String>('queue_user_31'),
        throwsStateError,
      );
    },
  );

  test(
    'legacy drafts and queue payloads migrate with keys and content intact',
    () async {
      final legacy = await Hive.openBox<JournalEntry>('journals_user_31');
      final draft = JournalEntry(
        id: 'draft',
        type: 'free',
        body: 'private unsynced words',
        wordCount: 3,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        isDraft: true,
      );
      await legacy.put('draft', draft);
      await legacy.close();
      final persisted = await Hive.openBox<JournalEntry>('journals_user_31');
      final expected = jsonEncode(persisted.get('draft')!.toJson());
      await persisted.close();
      final queue = await Hive.openBox<String>('sync_queue_user_31');
      await queue.put(7, 'private queued health payload');
      await queue.close();
      final encrypted = await EncryptedHive.openBox<JournalEntry>(
        'journals_user_31',
      );
      expect(jsonEncode(encrypted.get('draft')!.toJson()), expected);
      expect(encrypted.get('draft')!.isDraft, isTrue);
      final encryptedQueue = await EncryptedHive.openBox<String>(
        'sync_queue_user_31',
      );
      expect(encryptedQueue.get(7), 'private queued health payload');
      expect(await Hive.boxExists('journals_user_31'), isFalse);
      expect(await Hive.boxExists('sync_queue_user_31'), isFalse);
      await encrypted.flush();
      final bytes = await File(encrypted.path!).readAsBytes();
      expect(latin1.decode(bytes), isNot(contains('private unsynced words')));
      final encoded = await secure.read(key: 'hive_key_v1_journals_user_31');
      expect(base64Decode(encoded!).length, 32);
      await encrypted.close();
      final reopened = await EncryptedHive.openBox<JournalEntry>(
        'journals_user_31',
      );
      expect(jsonEncode(reopened.get('draft')!.toJson()), expected);
    },
  );

  test('missing key blocks access and preserves encrypted bytes', () async {
    final box = await EncryptedHive.openBox<String>('sync_queue');
    await box.put(1, 'unsynced health data');
    await box.flush();
    final file = File(box.path!);
    final before = await file.readAsBytes();
    await box.close();
    await secure.delete(key: 'hive_key_v1_sync_queue');
    await expectLater(
      EncryptedHive.openBox<String>('sync_queue'),
      throwsStateError,
    );
    expect(await file.readAsBytes(), before);
  });

  test('adapter migration preserves fields absent from API JSON', () async {
    final created = DateTime.utc(2020, 2, 3);
    final source = await Hive.openBox<ChatConversation>('chat_conversations');
    await source.put(
      'conversation',
      ChatConversation(
        id: 'conversation',
        title: 'Private',
        lastMessagePreview: 'Preview',
        messageCount: 3,
        isArchived: true,
        createdAt: created,
        updatedAt: DateTime.utc(2026),
      ),
    );
    await source.close();
    final target = await EncryptedHive.openBox<ChatConversation>(
      'chat_conversations',
    );
    final actual = target.get('conversation')!;
    expect(actual.createdAt.toUtc(), created);
    expect(actual.isArchived, isTrue);
    expect(actual.messageCount, 3);
    expect(actual.lastMessagePreview, 'Preview');
  });

  test('wrong key never triggers Hive truncation recovery', () async {
    final box = await EncryptedHive.openBox<String>('journals');
    await box.put('draft', 'unsynced draft');
    await box.flush();
    final file = File(box.path!);
    final before = await file.readAsBytes();
    await box.close();
    await secure.write(
      key: 'hive_key_v1_journals',
      value: base64Encode(Hive.generateSecureKey()),
    );
    await expectLater(
      EncryptedHive.openBox<String>('journals'),
      throwsA(anything),
    );
    expect(await file.readAsBytes(), before);
  });

  test('interrupted copy resumes from untouched legacy source', () async {
    final source = await Hive.openBox<String>('sync_queue');
    await source.putAll({1: 'one', 2: 'two'});
    await source.close();
    final key = Hive.generateSecureKey();
    await secure.write(key: 'hive_key_v1_sync_queue', value: base64Encode(key));
    await secure.write(
      key: 'hive_key_digest_v1_sync_queue',
      value: sha256.convert(key).toString(),
    );
    final partial = await Hive.openBox<String>(
      EncryptedHive.physicalName('sync_queue'),
      encryptionCipher: HiveAesCipher(key),
    );
    await partial.put(1, 'partial stale value');
    await partial.close();
    final result = await EncryptedHive.openBox<String>('sync_queue');
    expect(result.toMap(), {1: 'one', 2: 'two'});
    expect(await Hive.boxExists('sync_queue'), isFalse);
  });

  test(
    'completed migration never overwrites later writes with a legacy backup',
    () async {
      final original = await Hive.openBox<String>('sync_queue');
      await original.put(1, 'stale');
      await original.close();
      final box = await EncryptedHive.openBox<String>('sync_queue');
      await box.put(1, 'newest');
      await box.close();
      final leftover = await Hive.openBox<String>('sync_queue');
      await leftover.put(1, 'stale');
      await leftover.close();
      expect(
        (await EncryptedHive.openBox<String>('sync_queue')).get(1),
        'newest',
      );
      expect(await Hive.boxExists('sync_queue'), isFalse);
    },
  );

  test(
    'new legacy writes after a downgrade are preserved with the encrypted copy',
    () async {
      final box = await EncryptedHive.openBox<String>('sync_queue');
      await box.put(1, 'encrypted pending write');
      await box.flush();
      final file = File(box.path!);
      final before = await file.readAsBytes();
      await box.close();
      final legacy = await Hive.openBox<String>('sync_queue');
      await legacy.put(2, 'new downgraded-app pending write');
      await legacy.close();
      await expectLater(
        EncryptedHive.openBox<String>('sync_queue'),
        throwsStateError,
      );
      expect(await file.readAsBytes(), before);
      expect(
        Hive.box<String>('sync_queue').get(2),
        'new downgraded-app pending write',
      );
    },
  );

  test('concurrent opens share one encrypted box and key', () async {
    final boxes = await Future.wait(
      List.generate(5, (_) => EncryptedHive.openBox<String>('queue')),
    );
    expect(boxes.every((box) => identical(box, boxes.first)), isTrue);
    await boxes.first.put(9, 'pending');
    expect(boxes.last.get(9), 'pending');
  });

  test(
    'late opener waits until migration is verified instead of seeing a partial box',
    () async {
      final source = await Hive.openBox<String>('sync_queue');
      await source.putAll({for (var i = 0; i < 50; i++) i: 'queued-$i'});
      await source.close();
      final first = EncryptedHive.openBox<String>('sync_queue');
      while (!Hive.isBoxOpen(EncryptedHive.physicalName('sync_queue'))) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(EncryptedHive.isBoxOpen('sync_queue'), isFalse);
      final second = EncryptedHive.openBox<String>('sync_queue');
      final migrated = await second;
      expect(migrated, same(await first));
      expect(migrated.length, 50);
      expect(migrated.get(49), 'queued-49');
    },
  );
}
