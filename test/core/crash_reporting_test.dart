import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:cozy_health/core/services/crash_reporting.dart';

void main() {
  tearDown(() => CrashReporting.feature = 'app');
  test(
    'event redaction removes content, identities, requests and breadcrumbs',
    () {
      const secret = 'PRIVATE_JOURNAL_AND_EMAIL';
      final input = SentryEvent.fromJson({
        'event_id': '0123456789abcdef0123456789abcdef',
        'timestamp': '2026-10-08T12:00:00Z',
        'message': {'formatted': secret},
        'user': {'email': secret, 'username': secret},
        'request': {'url': 'https://example.com/$secret', 'data': secret},
        'extra': {'notes': secret},
        'contexts': {
          'content': {'body': secret},
        },
        'tags': {'feature': 'journal', 'name': secret},
        'breadcrumbs': [
          {
            'message': secret,
            'data': {'chat': secret},
          },
        ],
        'exception': {
          'values': [
            {
              'type': 'StateError',
              'value': secret,
              'stacktrace': {
                'frames': [
                  {
                    'filename': 'package:cozy_health/main.dart',
                    'lineno': 12,
                    'abs_path': secret,
                    'function': secret,
                    'vars': {'body': secret},
                    'context_line': secret,
                  },
                ],
              },
            },
          ],
        },
      });
      final clean = CrashReporting.sanitize(input)!;
      expect(jsonEncode(clean.toJson()), isNot(contains(secret)));
      expect(clean.tags, {'feature': 'journal'});
      expect(clean.exceptions!.single.type, 'StateError');
      expect(clean.exceptions!.single.stackTrace!.frames.single.lineNo, 12);
      expect(clean.user, isNull);
      expect(clean.request, isNull);
      expect(clean.breadcrumbs, isNull);
    },
  );
  test('unknown exception names, filenames and tags cannot carry content', () {
    final clean = CrashReporting.sanitize(
      SentryEvent(
        tags: {'feature': 'private text'},
        exceptions: [
          SentryException(
            type: 'private text',
            value: 'private text',
            stackTrace: SentryStackTrace(
              frames: [SentryStackFrame(fileName: '/user/private text.dart')],
            ),
          ),
        ],
      ),
    )!;
    expect(jsonEncode(clean.toJson()), isNot(contains('private text')));
    expect(clean.tags, {'feature': 'app'});
  });
  test('crisis route events are discarded', () {
    CrashReporting.tagRoute('/crisis-support');
    expect(CrashReporting.sanitize(SentryEvent()), isNull);
  });
  test(
    'private overlay suppresses events and restores reporting after dismissal',
    () async {
      await CrashReporting.privateOverlay(() async {
        expect(CrashReporting.sanitize(SentryEvent()), isNull);
      });
      expect(CrashReporting.sanitize(SentryEvent()), isNotNull);
    },
  );
  test(
    'feature tags use a fixed vocabulary and never include routes or IDs',
    () {
      expect(CrashReporting.featureForRoute('/journal/123'), 'journal');
      expect(CrashReporting.featureForRoute('/mood-checkin'), 'mood_checkin');
      expect(CrashReporting.featureForRoute('/assistant/123'), 'chat');
      expect(CrashReporting.featureForRoute('/provider'), 'provider');
      expect(CrashReporting.featureForRoute('/login'), 'auth');
    },
  );
  test(
    'telemetry configuration blocks user interaction and native bypasses',
    () {
      final options = SentryFlutterOptions();
      CrashReporting.configure(options);
      expect(options.sendDefaultPii, isFalse);
    expect(options.enableNativeCrashHandling, isFalse);
    expect(options.enableAppHangTracking, isFalse);
    expect(options.anrEnabled, isFalse);
      expect(options.attachScreenshot, isFalse);
      expect(options.attachViewHierarchy, isFalse);
      expect(options.enablePrintBreadcrumbs, isFalse);
      expect(options.enableUserInteractionBreadcrumbs, isFalse);
      expect(options.tracesSampleRate, 0.2);
      expect(options.beforeSend, isNotNull);
    },
  );
  test('missing DSN runs app without initializing telemetry', () async {
    var called = false;
    await CrashReporting.run(() async => called = true);
    expect(called, isTrue);
  });
}
