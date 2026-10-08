import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Telemetry accepts diagnostics, never user-authored text or interaction data.
class CrashReporting {
  static const dsn = String.fromEnvironment('SENTRY_DSN');
  static String feature = 'app';
  static int _privateOverlays = 0;
  static Future<T> privateOverlay<T>(Future<T> Function() show) async {
    _privateOverlays++;
    try {
      return await show();
    } finally {
      _privateOverlays--;
    }
  }

  static const features = {
    'app',
    'auth',
    'mood_checkin',
    'journal',
    'crisis',
    'chat',
    'provider',
  };

  static Future<void> run(Future<void> Function() appRunner) async {
    if (dsn.isEmpty) {
      await appRunner();
      return;
    }
    await SentryFlutter.init(configure, appRunner: appRunner);
  }

  static void configure(SentryFlutterOptions options) {
    options.dsn = dsn;
    options.tracesSampleRate = 0.2;
    options.enableAutoSessionTracking = true;
    options.sendDefaultPii = false;
    options.enablePrintBreadcrumbs = false;
    options.enableAutoNativeBreadcrumbs = false;
    options.enableAppLifecycleBreadcrumbs = false;
    options.enableWindowMetricBreadcrumbs = false;
    options.enableBrightnessChangeBreadcrumbs = false;
    options.enableTextScaleChangeBreadcrumbs = false;
    options.enableMemoryPressureBreadcrumbs = false;
    options.enableUserInteractionBreadcrumbs = false;
    options.enableUserInteractionTracing = false;
    options.recordHttpBreadcrumbs = false;
    options.captureFailedRequests = false;
    options.attachScreenshot = false;
    // Explicitly disable the SDK's experimental view capture for privacy.
    // ignore: experimental_member_use
    options.attachViewHierarchy = false;
    options.enableScopeSync = false;
    options.enableNdkScopeSync = false;
    // Native events do not pass through Dart beforeSend. Keep them disabled
    // until native redaction has been configured and verified on devices.
    options.enableNativeCrashHandling = false;
    options.enableAppHangTracking = false;
    options.anrEnabled = false;
    options.enableWatchdogTerminationTracking = false;
    options.enableAutoPerformanceTracing = false;
    options.beforeBreadcrumb = (_, __) => null;
    options.beforeSend = (event, _) => sanitize(event);
    // Transaction descriptions/spans can contain URLs and arbitrary content.
    // Error reporting is enabled; performance uploads wait for a safe schema.
    options.beforeSendTransaction = (_) => null;
    options.beforeSendFeedback = (_, __) => null;
  }

  static void tagRoute(String path) {
    feature = featureForRoute(path);
    Sentry.configureScope((scope) => scope.setTag('feature', feature));
  }

  static String featureForRoute(String path) {
    if (path.contains('crisis') || path.contains('safety-plan')) {
      return 'crisis';
    }
    if (path.contains('mood')) return 'mood_checkin';
    if (path.contains('journal') || path.contains('voice-recording')) {
      return 'journal';
    }
    if (path.contains('assistant') || path.contains('chat')) return 'chat';
    if (path.contains('provider')) return 'provider';
    if (RegExp(
      'login|sign-up|create-account|password|auth|onboarding',
    ).hasMatch(path)) {
      return 'auth';
    }
    return 'app';
  }

  static SentryEvent? sanitize(SentryEvent event) {
    final candidate = event.tags?['feature'] ?? feature;
    final tag = features.contains(candidate) ? candidate : 'app';
    if (_privateOverlays > 0 || feature == 'crisis' || tag == 'crisis') {
      return null;
    }
    // Reconstruct rather than copyWith: omitted fields must be removed.
    return SentryEvent(
      eventId: event.eventId,
      timestamp: event.timestamp,
      level: event.level,
      platform: event.platform,
      tags: {'feature': tag},
      exceptions: event.exceptions
          ?.map(
            (exception) => SentryException(
              type: _exceptionType(exception.type),
              value: 'Error details withheld for privacy.',
              stackTrace: exception.stackTrace == null
                  ? null
                  : SentryStackTrace(
                      frames: exception.stackTrace!.frames
                          .map(
                            (frame) => SentryStackFrame(
                              fileName: _sourceFile(frame.fileName),
                              lineNo: frame.lineNo,
                              colNo: frame.colNo,
                              inApp: frame.inApp,
                            ),
                          )
                          .toList(),
                    ),
            ),
          )
          .toList(),
    );
  }

  static String _exceptionType(String? type) =>
      const {
        'Exception',
        'StateError',
        'ArgumentError',
        'TypeError',
        'RangeError',
        'FormatException',
        'SocketException',
        'TimeoutException',
        'FlutterError',
        'PlatformException',
        'AssertionError',
        'FileSystemException',
      }.contains(type)
      ? type!
      : 'ApplicationError';

  static String? _sourceFile(String? file) {
    if (file == null || !file.startsWith('package:')) return null;
    return RegExp(
          r'^package:[a-zA-Z0-9_]+/[a-zA-Z0-9_/.]+\.dart$',
        ).hasMatch(file)
        ? file
        : null;
  }

  /// Explicit debug-only probe; never called during normal startup.
  static Future<void> debugProbe() async {
    if (kDebugMode && dsn.isNotEmpty) {
      await Sentry.captureException(Exception('Sentry test'));
    }
  }
}
