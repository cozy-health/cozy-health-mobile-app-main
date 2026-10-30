import 'package:cozy_health/core/services/legal_documents.dart';
import 'package:cozy_health/features/settings/presentation/screens/legal_hub_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/terms_policies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Map<String, dynamic>> bundledDocuments;
  setUpAll(() async {
    bundledDocuments = await LegalDocuments.load();
  });
  test(
    'legal online routes use the build environment and reject foreign hosts',
    () {
      const environment = String.fromEnvironment(
        'COZY_ENVIRONMENT',
        defaultValue: 'development',
      );
      final host = environment == 'production'
          ? 'cozyhealth.org'
          : 'dev.cozyhealth.org';
      expect(LegalDocuments.documentUrl('/privacy'), 'https://$host/privacy');
      for (final route in [
        '//evil.test/privacy',
        'https://evil.test/privacy',
        'privacy',
      ]) {
        expect(LegalDocuments.documentUrl(route), isNull);
      }
      expect(
        LegalDocuments.trustedUrl(
          'https://dev.cozyhealth.org.evil.test/privacy',
        ),
        isNull,
      );
      expect(
        LegalDocuments.trustedUrl('https://user@dev.cozyhealth.org/privacy'),
        isNull,
      );
      expect(
        LegalDocuments.trustedUrl('https://dev.cozyhealth.org:444/privacy'),
        isNull,
      );
    },
  );

  testWidgets('Settings legal catalog exposes every bundled consumer notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LegalHubScreen(loadDocuments: () async => bundledDocuments),
      ),
    );
    await tester.pumpAndSettle();
    final documents = bundledDocuments;
    final consumer = documents.where((doc) => doc['audience'] == 'consumer');
    expect(consumer.length, 8);
    expect(consumer.any((doc) => doc['id'] == 'guardians'), isFalse);
    for (final doc in consumer) {
      final isTerms = doc['id'] == 'tos';
      expect(doc['version'], isTerms ? '1.2' : '1.1');
      expect(doc['effective_date'], isTerms ? '2026-10-30' : '2026-10-29');
      expect(doc['published'], isTrue);
      final row = find.byKey(ValueKey('legal-document-${doc['id']}'));
      await tester.scrollUntilVisible(
        row,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(row, findsOneWidget);
    }
    expect(find.text('Data Processing Agreement'), findsNothing);
    expect(find.text('Last updated: October 1, 2026'), findsNothing);
    expect(
      find.byKey(const ValueKey('legal-document-guardians')),
      findsNothing,
    );
    final privacy = find.byKey(const ValueKey('legal-document-privacy_policy'));
    await tester.scrollUntilVisible(
      privacy,
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(privacy), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(privacy);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Version 1.1 · Effective 29 October 2026'),
      findsOneWidget,
    );
    expect(
      find.textContaining('not yet effective or available for acceptance'),
      findsNothing,
    );
    expect(find.byType(SelectableText), findsWidgets);
    expect(find.text('Accept'), findsNothing);
  });

  testWidgets('failed document load can retry without leaving the screen', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TermsPoliciesScreen(
          title: 'Terms',
          loadDocuments: () async {
            if (++attempts == 1) throw StateError('fixture failure');
            return bundledDocuments;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('legal-retry')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('legal-retry')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.textContaining('Document updated:'), findsOneWidget);
    expect(find.byKey(const ValueKey('legal-retry')), findsNothing);
  });

  testWidgets(
    'failed browser launch keeps the bundled copy and explains recovery',
    (tester) async {
      String? openedUrl;
      await tester.pumpWidget(
        MaterialApp(
          home: TermsPoliciesScreen(
            title: 'Terms',
            loadDocuments: () async => bundledDocuments,
            openLink: (url) async {
              openedUrl = url;
              return false;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('legal-tos'));
      await tester.scrollUntilVisible(
        button,
        600,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(button);
      await tester.pump();
      expect(openedUrl, LegalDocuments.documentUrl('/terms'));
      expect(
        find.textContaining('The online document could not be opened.'),
        findsOneWidget,
      );
      expect(find.byType(SelectableText), findsWidgets);
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
    },
  );
}
