import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/features/home/presentation/screens/home_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/settings_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/profile_view_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/profile_avatar.dart';
import 'package:cozy_health/features/settings/data/avatar_repository.dart';
import 'package:cozy_health/features/settings/presentation/screens/edit_profile_screen.dart';
import 'package:cozy_health/features/settings/presentation/widgets/avatar_picker_sheet.dart';
import '../../support/local_fonts.dart';
import '../../support/repository_fixture.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/chat_message.dart';
import 'package:cozy_health/core/models/chat_conversation.dart';
import 'package:cozy_health/core/models/safety_plan.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/models/saved_article.dart';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/models/subscription_status.dart';
import 'package:cozy_health/core/models/user_preferences.dart';

class AvatarTransport implements HttpClientAdapter {
  dynamic body = {
    'data': {'avatar_url': 'asset:open-peeps-02', 'avatar_revision': 1},
  };
  int status = 200;
  Completer<void>? delay;
  final requests = <RequestOptions>[];
  final requested = Completer<void>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    if (!requested.isCompleted) requested.complete();
    if (delay != null) await delay!.future;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class ObservedAvatarRepository extends AvatarRepository {
  Future<void>? operation;
  @override
  Future<void> save({String? presetId, Uint8List? photo, bool remove = false}) {
    return operation = super.save(
      presetId: presetId,
      photo: photo,
      remove: remove,
    );
  }
}

class RecordingCacheRepository extends AvatarRepository {
  final urls = <String?>[];
  @override
  Future<Uint8List?> cachedPhoto(UserProfile profile) async {
    urls.add(profile.avatarUrl);
    return null;
  }

  @override
  Future<void> refresh() async {}
}

void iosTestWidgets(String name, WidgetTesterCallback callback) => testWidgets(
  name,
  callback,
  variant: TargetPlatformVariant.only(TargetPlatform.iOS),
);

void main() {
  final local = LocalDbService();
  late RepositoryFixture<UserProfile> fixture;
  late AvatarTransport transport;
  UserProfile profile() => UserProfile(
    id: 'profile-1',
    name: 'Person',
    email: 'person@example.test',
    updatedAt: DateTime.utc(2026),
  );
  setUpAll(() async {
    await installLocalTestFonts();
    SharedPreferences.setMockInitialValues({});
    fixture = RepositoryFixture(
      LocalDbService.userProfileBoxName,
      UserProfileAdapter(),
    );
    await fixture.open();
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(ChatConversationAdapter());
    Hive.registerAdapter(SafetyPlanAdapter());
    Hive.registerAdapter(QuizAttemptAdapter());
    Hive.registerAdapter(SavedArticleAdapter());
    Hive.registerAdapter(AppNotificationAdapter());
    Hive.registerAdapter(SubscriptionStatusAdapter());
    Hive.registerAdapter(UserPreferencesAdapter());
    local.syncPaused = true;
    await local.activateAccount('1');
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await local.activateAccount('1');
    await local.userProfileBox.clear();
    await local.saveUserProfile(profile());
    await TokenStorage().saveToken('test-session');
    transport = AvatarTransport();
    ApiClient().transportForTesting = transport;
  });
  tearDown(() {
    DemoMode.instance.enabled = false;
  });
  tearDownAll(() async {
    await fixture.close();
    resetLocalTestFonts();
  });

  Future<void> mount(
    WidgetTester tester, {
    Future<bool> Function()? lookup,
    AvatarRepository? repository,
    bool realLookup = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: EditProfileScreen(
          guestLookup: realLookup ? null : (lookup ?? () async => false),
          avatarRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester) async {
    await tap(tester, find.text('Choose a built-in avatar'));
    await tap(tester, find.bySemanticsLabel('Open Peeps avatar 2'));
  }

  iosTestWidgets(
    'real Change photo opens before guest lookup and blocks duplicate taps',
    (tester) async {
      final waiting = Completer<bool>();
      await mount(tester, lookup: () => waiting.future);
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Change photo'),
      );
      button.onPressed!();
      button.onPressed!();
      await tester.pumpAndSettle();
      expect(find.byType(AvatarPickerSheet), findsOneWidget);
      expect(find.textContaining('Checking your account'), findsOneWidget);
      await select(tester);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save picture'),
            )
            .onPressed,
        isNull,
      );
      waiting.complete(false);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save picture'),
            )
            .onPressed,
        isNotNull,
      );
      expect(transport.requests, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  iosTestWidgets(
    'picture tap opens with keyboard and cancellation preserves text',
    (tester) async {
      await mount(tester);
      await tester.enterText(find.byType(TextField).first, 'Unsaved name');
      await tap(tester, find.byKey(const Key('edit-profile-picture')));
      expect(tester.testTextInput.isVisible, isFalse);
      await select(tester);
      await tap(tester, find.text('Cancel selection'));
      await tap(tester, find.byTooltip('Close'));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Unsaved name',
      );
      expect(transport.requests, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  iosTestWidgets(
    'session failure and timeout allow browsing, retry, and closing',
    (tester) async {
      var attempts = 0;
      await mount(
        tester,
        lookup: () {
          attempts++;
          if (attempts == 1) return Future.error(StateError('Unavailable'));
          return Completer<bool>().future;
        },
      );
      await tap(tester, find.text('Change photo'));
      expect(find.text('Retry account check'), findsOneWidget);
      await select(tester);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save picture'),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, find.text('Retry account check'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Retry account check'), findsOneWidget);
      await tap(tester, find.byTooltip('Close'));
      expect(find.byType(AvatarPickerSheet), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  iosTestWidgets('disposing screen during guest lookup is safe', (
    tester,
  ) async {
    final waiting = Completer<bool>();
    await mount(tester, lookup: () => waiting.future);
    await tap(tester, find.text('Change photo'));
    await tester.pumpWidget(const SizedBox.shrink());
    waiting.complete(false);
    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
  });

  iosTestWidgets(
    'actual save updates Edit Profile without discarding unsaved text',
    (tester) async {
      final repository = ObservedAvatarRepository();
      await mount(tester, repository: repository);
      await tester.enterText(find.byType(TextField).first, 'Unsaved name');
      await tap(tester, find.text('Change photo'));
      await select(tester);
      await tester.runAsync(() async {
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save picture'),
            )
            .onPressed!();
        await repository.operation!.timeout(const Duration(seconds: 15));
      });
      await tester.pumpAndSettle();
      expect(find.byType(AvatarPickerSheet), findsNothing);
      expect(local.getUserProfile()!.avatarUrl, 'asset:open-peeps-02');
      expect(
        tester
            .widget<ProfileAvatar>(find.byType(ProfileAvatar))
            .profile!
            .avatarUrl,
        'asset:open-peeps-02',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Unsaved name',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  iosTestWidgets(
    'account switch closes an in-flight picker and ignores its response',
    (tester) async {
      final repository = ObservedAvatarRepository();
      await mount(tester, repository: repository);
      await tap(tester, find.text('Change photo'));
      await select(tester);
      await tester.runAsync(() async {
        transport.delay = Completer<void>();
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save picture'),
            )
            .onPressed!();
        await transport.requested.future.timeout(const Duration(seconds: 15));
        await local.activateAccount('2');
      });
      await tester.pumpAndSettle();
      expect(find.byType(AvatarPickerSheet), findsNothing);
      await tester.runAsync(() async {
        transport.delay!.complete();
        await expectLater(repository.operation!, throwsStateError);
      });
      await tester.pumpAndSettle();
      expect(local.getUserProfile(), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'real PUT applies selection and survives reopening encrypted profile box',
    () async {
      await AvatarRepository().save(presetId: 'open-peeps-02');
      expect(transport.requests.single.method, 'PUT');
      expect(transport.requests.single.path, '/user/profile/avatar');
      expect(transport.requests.single.data, {
        'preset_id': 'open-peeps-02',
        'expected_user_id': '1',
      });
      await local.userProfileBox.close();
      await local.activateAccount('1');
      expect(local.getUserProfile()!.avatarUrl, 'asset:open-peeps-02');
      expect(local.getUserProfile()!.avatarRevision, 1);
    },
  );

  test(
    'malformed and stale success responses never report a successful selection',
    () async {
      for (final body in [
        null,
        {'data': {}},
        {
          'data': {'avatar_url': 'asset:unknown', 'avatar_revision': 1},
        },
      ]) {
        transport.body = body;
        await expectLater(
          AvatarRepository().save(presetId: 'open-peeps-02'),
          throwsFormatException,
        );
        expect(local.getUserProfile()!.avatarUrl, isNull);
      }
      await local.saveUserProfile(
        profile().copyWith(avatarUrl: 'asset:open-peeps-03', avatarRevision: 3),
      );
      transport.body = {
        'data': {'avatar_url': 'asset:open-peeps-02', 'avatar_revision': 2},
      };
      await expectLater(
        AvatarRepository().save(presetId: 'open-peeps-02'),
        throwsStateError,
      );
      expect(local.getUserProfile()!.avatarRevision, 3);
    },
  );

  test('missing profile and guest session cannot send a mutation', () async {
    await local.userProfileBox.clear();
    await expectLater(
      AvatarRepository().save(presetId: 'open-peeps-02'),
      throwsStateError,
    );
    await local.saveUserProfile(profile());
    SharedPreferences.setMockInitialValues({'is_guest_session': true});
    await expectLater(
      AvatarRepository().save(presetId: 'open-peeps-02'),
      throwsStateError,
    );
    expect(transport.requests, isEmpty);
  });

  test('rejected PUT preserves the current selection', () async {
    transport.status = 422;
    transport.body = {
      'message': 'Invalid selection',
      'errors': {
        'preset_id': ['Invalid selection'],
      },
    };
    await expectLater(
      AvatarRepository().save(presetId: 'open-peeps-02'),
      throwsA(isA<ApiValidationException>()),
    );
    expect(local.getUserProfile()!.avatarUrl, isNull);
  });
  iosTestWidgets(
    'renewed signed URL retries cache download at the same revision',
    (tester) async {
      final repository = RecordingCacheRepository();
      Future<void> show(String url) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProfileAvatar(
                profile: profile().copyWith(avatarUrl: url, avatarRevision: 1),
                repository: repository,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show('https://storage.example.test/avatar.jpg?signature=old');
      await show('https://storage.example.test/avatar.jpg?signature=new');
      expect(repository.urls, [
        'https://storage.example.test/avatar.jpg?signature=old',
        'https://storage.example.test/avatar.jpg?signature=new',
      ]);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  iosTestWidgets('guest can open actual entry and browse without a mutation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'is_guest_session': true});
    await mount(tester, realLookup: true);
    await tap(tester, find.text('Change photo'));
    await select(tester);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save picture'),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Create account'), findsOneWidget);
    expect(transport.requests, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  iosTestWidgets('all bundled avatars render through the real entry', (
    tester,
  ) async {
    await mount(tester);
    await tap(tester, find.text('Change photo'));
    await tap(tester, find.text('Choose a built-in avatar'));
    expect(find.byType(ProfileAvatar), findsNWidgets(25));
    for (var index = 1; index <= 24; index++) {
      expect(find.bySemanticsLabel('Open Peeps avatar $index'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final screen in <String, Widget Function()>{
    'Home': () => const HomeScreen(),
    'Settings': () => const SettingsScreen(),
    'Profile': () => const ProfileViewScreen(),
  }.entries) {
    iosTestWidgets('saved avatar propagates to ${screen.key}', (tester) async {
      DemoMode.instance.enabled = true;
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: screen.value()),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await local.saveUserProfile(
          profile().copyWith(
            avatarUrl: 'asset:open-peeps-02',
            avatarRevision: 1,
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ProfileAvatar>(find.byType(ProfileAvatar))
            .profile!
            .avatarUrl,
        'asset:open-peeps-02',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  iosTestWidgets(
    'account switch closes removal confirmation as well as picker',
    (tester) async {
      await tester.runAsync(
        () => local.saveUserProfile(
          profile().copyWith(
            avatarUrl: 'asset:open-peeps-02',
            avatarRevision: 1,
          ),
        ),
      );
      await mount(tester);
      await tap(tester, find.text('Change photo'));
      await tap(tester, find.text('Remove photo'));
      expect(find.text('Remove profile picture?'), findsOneWidget);
      await tester.runAsync(() => local.activateAccount('2'));
      await tester.pumpAndSettle();
      expect(find.byType(AvatarPickerSheet), findsNothing);
      expect(find.text('Remove profile picture?'), findsNothing);
      expect(transport.requests, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  iosTestWidgets(
    'grid and preview reset their scroll position at large text sizes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: EditProfileScreen(guestLookup: () async => false),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('Change photo'));
      await tap(tester, find.text('Choose a built-in avatar'));
      ScrollController controller() => tester
          .widget<SingleChildScrollView>(
            find.descendant(
              of: find.byType(AvatarPickerSheet),
              matching: find.byType(SingleChildScrollView),
            ),
          )
          .controller!;
      expect(controller().offset, 0);
      await tap(tester, find.bySemanticsLabel('Open Peeps avatar 24'));
      expect(controller().offset, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
