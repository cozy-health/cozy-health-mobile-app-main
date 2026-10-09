import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as font_test;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/features/home/presentation/screens/main_screen.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/features/home/presentation/widgets/feature_tour.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box<dynamic> settings;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    // Use Flutter's bundled font for font aliases; tests never fetch fonts.
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = <String, ByteData>{};
    for (final path in manifest.listAssets()) {
      assets[path] = await rootBundle.load(path);
    }
    final font = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    font_test.assetManifest = _TourFontManifest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final path = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          return path.startsWith('test-fonts/') ? font : assets[path];
        });
    directory = await Directory.systemTemp.createTemp('cozy_tour_test_');
    Hive.init(directory.path);
    settings = await LocalDbService().settingsBox();
    GoogleFonts.config.allowRuntimeFetching = false;
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(AppNotificationAdapter());
    await EncryptedHive.openBox<MoodEntry>(LocalDbService.moodBoxName);
    await EncryptedHive.openBox<JournalEntry>(LocalDbService.journalBoxName);
    await EncryptedHive.openBox<UserProfile>(LocalDbService.userProfileBoxName);
    await EncryptedHive.openBox<AppNotification>(
      LocalDbService.appNotificationBoxName,
    );
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await settings.clear();
  });
  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    font_test.assetManifest = null;
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  Future<void> mount(
    WidgetTester tester, {
    bool reduceMotion = true,
    double textScale = 1,
  }) async {
    final targets = FeatureTourTargets();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduceMotion,
            size: tester.view.physicalSize / tester.view.devicePixelRatio,
            textScaler: TextScaler.linear(textScale),
          ),
          child: FeatureTour(
            targets: targets,
            child: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    key: targets.hero,
                    width: 300,
                    height: 150,
                    child: const Center(child: Text('Mood hero')),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        key: targets.journal,
                        onPressed: () {},
                        tooltip: 'Quick actions',
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        key: targets.assistant,
                        onPressed: () {},
                        tooltip: 'Assistant',
                        icon: const Icon(Icons.chat),
                      ),
                      SizedBox(
                        key: targets.crisis,
                        width: 56,
                        height: 56,
                        child: const Icon(Icons.favorite_border),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.runAsync(() => tester.tap(find.text(text)));
    await tester.pumpAndSettle();
  }

  Future<void> flush(WidgetTester tester) async {
    // Let real file I/O and the widget test's fake microtask queue both progress.
    // Checking the in-memory flag alone does not await Hive's disk write.
    var closed = false;
    settings.close().then((_) => closed = true);
    for (var i = 0; i < 100 && !closed; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(closed, isTrue);
    await tester.runAsync(
      () async => settings = await LocalDbService().settingsBox(),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Unseen tour offers an optional introduction on first Home', (
    tester,
  ) async {
    await tester.runAsync(() => settings.put('has_seen_tour', false));
    await mount(tester);
    expect(find.text('Want a quick look around?'), findsOneWidget);
    expect(find.text('Show me'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Seen tour shows no offer or coach marks', (tester) async {
    await tester.runAsync(() => settings.put('has_seen_tour', true));
    await mount(tester);
    expect(find.text('Want a quick look around?'), findsNothing);
    expect(find.text("Log how you're feeling"), findsNothing);
  });

  testWidgets('Declining introduction persists has_seen_tour', (tester) async {
    await mount(tester);
    await tap(tester, 'Skip');
    await flush(tester);
    expect(settings.get('has_seen_tour'), isTrue);
    expect(find.text('Want a quick look around?'), findsNothing);
  });

  testWidgets('Skipping coach marks persists has_seen_tour', (tester) async {
    await mount(tester);
    await tap(tester, 'Show me');
    expect(find.text("Log how you're feeling"), findsOneWidget);
    await tap(tester, 'Skip tour');
    await flush(tester);
    expect(settings.get('has_seen_tour'), isTrue);
    expect(find.text("Log how you're feeling"), findsNothing);
  });

  testWidgets('All four targets and completion render in order', (
    tester,
  ) async {
    await mount(tester);
    await tap(tester, 'Show me');
    final messages = [
      "Log how you're feeling",
      'Keep a private journal',
      'Talk to your assistant',
      'Get help when you need it',
      "You're all set",
    ];
    for (var i = 0; i < messages.length; i++) {
      expect(find.text(messages[i]), findsOneWidget);
      expect(find.text('Tour ${i + 1} of 5'), findsOneWidget);
      await tap(tester, i == messages.length - 1 ? 'Done' : 'Next');
    }
    await flush(tester);
    expect(settings.get('has_seen_tour'), isTrue);
    expect(find.text("You're all set"), findsNothing);
  });

  testWidgets('Completed tour stays hidden on next visit', (tester) async {
    await mount(tester);
    await tap(tester, 'Skip');
    await flush(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester);
    expect(find.text('Want a quick look around?'), findsNothing);
  });

  testWidgets('Card entrance settles without repeating animation', (
    tester,
  ) async {
    await mount(tester, reduceMotion: false);
    await tap(tester, 'Show me');
    expect(find.text("Log how you're feeling"), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tap(tester, 'Skip tour');
    await flush(tester);
  });

  testWidgets('Disposing active tour removes its overlay', (tester) async {
    await mount(tester);
    await tap(tester, 'Show me');
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Another screen'))),
    );
    await tester.pumpAndSettle();
    expect(find.text("Log how you're feeling"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coach marks remain usable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, textScale: 2);
    await tap(tester, 'Show me');
    expect(find.text("Log how you're feeling"), findsOneWidget);
    await tap(tester, 'Skip tour');
    await flush(tester);
    expect(settings.get('has_seen_tour'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Real Home provides all four spotlight targets after loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const MainScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Want a quick look around?'), findsOneWidget);
    await tap(tester, 'Show me');
    for (final message in [
      "Log how you're feeling",
      'Keep a private journal',
      'Talk to your assistant',
      'Get help when you need it',
    ]) {
      expect(find.text(message), findsOneWidget);
      await tap(tester, 'Next');
    }
    expect(find.text("You're all set"), findsOneWidget);
    await tap(tester, 'Done');
    await flush(tester);
    expect(settings.get('has_seen_tour'), isTrue);
  });
}

class _TourFontManifest implements AssetManifest {
  @override
  List<String> listAssets() => [
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'test-fonts/Outfit-$weight.ttf',
  ];

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}
