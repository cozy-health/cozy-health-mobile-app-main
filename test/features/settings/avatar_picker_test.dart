import 'package:cozy_health/core/widgets/wellness_panel.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/profile_avatar.dart';
import 'package:cozy_health/features/settings/data/avatar_repository.dart';
import 'package:cozy_health/features/settings/presentation/widgets/avatar_picker_sheet.dart';
import 'package:cozy_health/features/settings/services/avatar_photo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/local_fonts.dart';
import '../../support/surface_capture.dart';

class FakeAvatarRepository extends AvatarRepository {
  int saves = 0;
  bool fail = false;
  String? selected;
  bool removed = false;
  Uint8List? uploaded;
  @override
  UserProfile? get profile => UserProfile(
    id: 'profile',
    name: 'Person',
    email: 'person@example.test',
    avatarUrl: 'asset:open-peeps-01',
    updatedAt: DateTime.utc(2026),
  );
  @override
  Future<void> save({
    String? presetId,
    Uint8List? photo,
    bool remove = false,
  }) async {
    saves++;
    if (fail) throw StateError('Offline');
    selected = presetId;
    uploaded = photo;
    removed = remove;
  }
}

class FakePhotoPicker extends AvatarPhotoPicker {
  bool? camera;
  PlatformException? error;
  Uint8List? bytes;
  @override
  Future<String?> recover() async => null;
  @override
  Future<Uint8List?> pick(BuildContext context, {required bool camera}) async {
    this.camera = camera;
    if (error != null) throw error!;
    return bytes;
  }
}

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);

  Future<void> mount(
    WidgetTester tester,
    FakeAvatarRepository repo, {
    FakePhotoPicker? picker,
    bool guest = false,
    bool dark = false,
    bool contrast = false,
    bool landscape = false,
  }) async {
    tester.view.physicalSize = landscape
        ? const Size(667, 375)
        : const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final theme = dark ? AppTheme.dark : AppTheme.light;
    await tester.pumpWidget(
      MaterialApp(
        theme: contrast ? AppTheme.highContrast(theme) : theme,
        builder: (context, child) => RepaintBoundary(
          key: surfaceCaptureKey,
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => AvatarPickerSheet(
                  repository: repo,
                  picker: picker ?? FakePhotoPicker(),
                  isGuest: guest,
                ),
              ),
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('model explicitly clears an avatar and keeps its revision', () {
    final profile = FakeAvatarRepository().profile!;
    final cleared = profile.copyWith(clearAvatarUrl: true, avatarRevision: 2);
    expect(cleared.avatarUrl, isNull);
    expect(UserProfile.fromJson(cleared.toJson()).avatarRevision, 2);
    expect(
      UserProfile.fromJson({...profile.toJson(), 'avatar_url': ''}).avatarUrl,
      isNull,
    );
  });

  testWidgets(
    'selecting a preset previews it and saves only after confirmation',
    (tester) async {
      final repo = FakeAvatarRepository();
      await mount(tester, repo);
      await tap(tester, find.text('Choose a built-in avatar'));
      expect(find.byType(ProfileAvatar), findsNWidgets(24));
      await tap(tester, find.bySemanticsLabel('Open Peeps avatar 2'));
      expect(repo.saves, 0);
      await tap(tester, find.text('Save picture'));
      expect(repo.selected, 'open-peeps-02');
      expect(find.text('Open picker'), findsOneWidget);
    },
  );

  testWidgets('canceling the system picker changes nothing', (tester) async {
    final repo = FakeAvatarRepository(), picker = FakePhotoPicker();
    await mount(tester, repo, picker: picker);
    await tap(tester, find.text('Choose from gallery'));
    expect(picker.camera, false);
    expect(repo.saves, 0);
    await tap(tester, find.text('Take a photo'));
    expect(picker.camera, true);
    expect(repo.saves, 0);
  });

  testWidgets('failed save retains the selection and allows retry', (
    tester,
  ) async {
    final repo = FakeAvatarRepository()..fail = true;
    await mount(tester, repo);
    await tap(tester, find.text('Choose a built-in avatar'));
    await tap(tester, find.bySemanticsLabel('Open Peeps avatar 3'));
    await tap(tester, find.text('Save picture'));
    expect(find.textContaining('Could not save'), findsOneWidget);
    expect(find.text('Save picture'), findsOneWidget);
    repo.fail = false;
    await tap(tester, find.text('Save picture'));
    expect(repo.selected, 'open-peeps-03');
  });

  testWidgets('guests can browse avatars but cannot save', (tester) async {
    final repo = FakeAvatarRepository();
    await mount(tester, repo, guest: true);
    await tap(tester, find.text('Choose a built-in avatar'));
    await tap(tester, find.bySemanticsLabel('Open Peeps avatar 4'));
    expect(
      tester
          .widget<WellnessAction>(
            find.byWidgetPredicate(
              (w) => w is WellnessAction && w.label == 'Save picture',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(repo.saves, 0);
  });

  testWidgets('removal requires confirmation', (tester) async {
    final repo = FakeAvatarRepository();
    await mount(tester, repo);
    await tap(tester, find.text('Remove photo'));
    await tap(tester, find.text('Cancel'));
    expect(repo.saves, 0);
    await tap(tester, find.text('Remove photo'));
    await tap(tester, find.text('Remove'));
    expect(repo.removed, true);
  });

  testWidgets(
    'permission denial offers device settings and preserves the current picture',
    (tester) async {
      final repo = FakeAvatarRepository();
      await mount(
        tester,
        repo,
        picker: FakePhotoPicker()
          ..error = PlatformException(code: 'camera_access_denied'),
      );
      await tap(tester, find.text('Take a photo'));
      expect(find.text('Open device settings'), findsOneWidget);
      expect(repo.saves, 0);
    },
  );

  for (final dark in [false, true]) {
    for (final contrast in [false, true]) {
      for (final landscape in [false, true]) {
        testWidgets(
          'avatar grid dark=$dark contrast=$contrast landscape=$landscape',
          (tester) async {
            await mount(
              tester,
              FakeAvatarRepository(),
              dark: dark,
              contrast: contrast,
              landscape: landscape,
            );
            final prefix =
                'avatar_${dark ? 'dark' : 'light'}_${contrast ? 'contrast' : 'normal'}_${landscape ? 'landscape' : 'portrait'}';
            await captureSurface(tester, '${prefix}_options');
            await tap(tester, find.text('Choose a built-in avatar'));
            await captureSurface(tester, '${prefix}_grid');
            await tap(tester, find.bySemanticsLabel('Open Peeps avatar 1'));
            await captureSurface(tester, '${prefix}_preview');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
