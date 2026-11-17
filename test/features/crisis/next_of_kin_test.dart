import 'package:cozy_health/core/models/next_of_kin_contact.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/crisis/data/next_of_kin_repository.dart';
import 'package:cozy_health/features/crisis/presentation/widgets/next_of_kin_panel.dart';
import 'package:cozy_health/features/crisis/services/crisis_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/surface_capture.dart';
import '../../support/local_fonts.dart';

const contact = NextOfKinContact(
  name: 'Trusted Person',
  phone: '+2348031234567',
  relationship: 'Sibling',
);

class FakeRepository extends NextOfKinRepository {
  FakeRepository(this.contact);
  NextOfKinContact? contact;
  int saves = 0;
  bool fail = false;
  @override
  Future<NextOfKinContact?> load() async => contact;
  @override
  Future<void> refresh() async {}
  @override
  Future<void> save(NextOfKinContact? value) async {
    if (fail) throw StateError('Storage unavailable');
    saves++;
    contact = value;
  }
}

class FakeLauncher extends CrisisLauncher {
  int sms = 0, calls = 0;
  String? number, body;
  LaunchResult result = LaunchResult.success;
  @override
  Future<LaunchResult> sendSms(String value, {String? body}) async {
    sms++;
    number = value;
    this.body = body;
    return result;
  }

  @override
  Future<LaunchResult> callPhone(String value) async {
    calls++;
    number = value;
    return result;
  }
}

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  test(
    'international phone normalization rejects local and malformed numbers',
    () {
      expect(
        NextOfKinContact.normalizePhone('+234 (803) 123-4567'),
        contact.phone,
      );
      for (final value in [
        '08031234567',
        '+0123456789',
        '+23',
        '+234803abc4567',
      ]) {
        expect(NextOfKinContact.validPhone(value), false);
      }
      expect(NextOfKinContact.validPhone(contact.phone), true);
    },
  );

  Future<void> mount(
    WidgetTester tester,
    FakeRepository repo,
    FakeLauncher launcher, {
    bool dark = false,
    bool contrast = false,
    double scale = 1,
    Size size = const Size(430, 932),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: contrast
            ? AppTheme.highContrast(dark ? AppTheme.dark : AppTheme.light)
            : dark
            ? AppTheme.dark
            : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(key: surfaceCaptureKey, child: child!),
        ),
        home: NextOfKinPanel(repository: repo, launcher: launcher),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label).last);
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('missing contact validates and saves without contacting anyone', (
    tester,
  ) async {
    final repo = FakeRepository(null), launcher = FakeLauncher();
    await mount(tester, repo, launcher);
    await tap(tester, 'Save next of kin');
    expect(find.text('Enter their name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Trusted Person');
    await tester.enterText(find.byType(TextFormField).at(1), 'Sibling');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      '+234 803 123 4567',
    );
    await tap(tester, 'Save next of kin');
    expect(repo.contact?.phone, contact.phone);
    expect(find.text('Prepare help message'), findsOneWidget);
    expect(launcher.sms + launcher.calls, 0);
  });

  testWidgets('review and cancellation perform no external action', (
    tester,
  ) async {
    final launcher = FakeLauncher();
    await mount(tester, FakeRepository(contact), launcher);
    await tap(tester, 'Prepare help message');
    expect(find.text('Review your help request'), findsOneWidget);
    await tap(tester, 'Cancel');
    expect(launcher.sms + launcher.calls, 0);
  });

  testWidgets('reviewed text and correct recipient are handed to Messages', (
    tester,
  ) async {
    final launcher = FakeLauncher();
    await mount(tester, FakeRepository(contact), launcher);
    await tap(tester, 'Prepare help message');
    await tester.enterText(
      find.byType(TextField),
      'Please call me & check in.',
    );
    await tap(tester, 'Open Messages');
    expect(launcher.sms, 1);
    expect(launcher.number, contact.phone);
    expect(launcher.body, 'Please call me & check in.');
    expect(
      find.textContaining('Delivery cannot be confirmed here.'),
      findsOneWidget,
    );
  });

  testWidgets('failed SMS keeps reviewed text and exposes recovery actions', (
    tester,
  ) async {
    final launcher = FakeLauncher()..result = LaunchResult.noApp;
    await mount(tester, FakeRepository(contact), launcher);
    await tap(tester, 'Prepare help message');
    await tester.enterText(find.byType(TextField), 'Keep this request');
    await tap(tester, 'Open Messages');
    expect(find.text('Keep this request'), findsOneWidget);
    expect(find.text('Copy number'), findsOneWidget);
    expect(find.text('Copy message'), findsOneWidget);
    await tap(tester, 'Try again');
    expect(launcher.sms, 2);
    expect(launcher.body, 'Keep this request');
  });

  testWidgets('calls require confirmation and can be canceled', (tester) async {
    final launcher = FakeLauncher();
    await mount(tester, FakeRepository(contact), launcher);
    await tap(tester, 'Call next of kin');
    expect(launcher.calls, 0);
    await tap(tester, 'Cancel');
    expect(launcher.calls, 0);
    await tap(tester, 'Call next of kin');
    await tap(tester, 'Call');
    expect(launcher.calls, 1);
  });

  testWidgets('removal requires confirmation and returns to setup', (
    tester,
  ) async {
    final repo = FakeRepository(contact), launcher = FakeLauncher();
    await mount(tester, repo, launcher);
    await tap(tester, 'Remove next of kin');
    await tap(tester, 'Cancel');
    expect(repo.saves, 0);
    await tap(tester, 'Remove next of kin');
    await tap(tester, 'Remove');
    expect(repo.contact, isNull);
    expect(find.text('Add your next of kin'), findsOneWidget);
    expect(launcher.sms + launcher.calls, 0);
  });

  testWidgets('failed saves keep entered contact details and show an error', (
    tester,
  ) async {
    final repo = FakeRepository(contact)..fail = true;
    await mount(tester, repo, FakeLauncher());
    await tap(tester, 'Edit next of kin');
    await tester.enterText(find.byType(TextFormField).first, 'Updated');
    await tap(tester, 'Save next of kin');
    expect(find.text('Updated'), findsOneWidget);
    expect(find.textContaining('Could not save'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    for (final contrast in [false, true]) {
      for (final landscape in [false, true]) {
        testWidgets(
          'next of kin surfaces dark=$dark contrast=$contrast landscape=$landscape',
          (tester) async {
            await mount(
              tester,
              FakeRepository(contact),
              FakeLauncher(),
              dark: dark,
              contrast: contrast,
              scale: 2,
              size: landscape ? const Size(667, 375) : const Size(375, 667),
            );
            final prefix =
                'next_of_kin_${dark ? 'dark' : 'light'}_${contrast ? 'contrast' : 'normal'}_${landscape ? 'landscape' : 'portrait'}';
            await captureSurface(tester, '${prefix}_contact');
            await tap(tester, 'Prepare help message');
            await captureSurface(tester, '${prefix}_review');
            await tap(tester, 'Cancel');
            await tap(tester, 'Call next of kin');
            await captureSurface(tester, '${prefix}_call_confirmation');
            await tap(tester, 'Cancel');
            await tap(tester, 'Edit next of kin');
            await captureSurface(tester, '${prefix}_edit');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
    testWidgets(
      'large text with keyboard remains usable in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        await mount(
          tester,
          FakeRepository(contact),
          FakeLauncher(),
          dark: dark,
          scale: 2,
        );
        await tap(tester, 'Prepare help message');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tap(tester, 'Open Messages');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
