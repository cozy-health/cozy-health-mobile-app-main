import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'local_db_service.dart';

/// Explicit, content-free PostHog events. No SDK autocapture, replay or retry queue.
class UsageAnalytics {
  UsageAnalytics._();
  static final instance = UsageAnalytics._();
  static const key = String.fromEnvironment('POSTHOG_KEY');
  static const host = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://eu.i.posthog.com',
  );
  static const events = {
    'app_active',
    'signup_completed',
    'signup_started',
    'onboarding_started',
    'onboarding_completed',
    'feature_opened',
  };
  static const features = {
    'home',
    'assessments',
    'journals',
    'community',
    'resources',
    'settings',
  };
  final Dio _http = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  CancelToken _requests = CancelToken();
  StreamSubscription<void>? _accounts;
  String _route = '';
  String? _lastFeature;

  void initialize() {
    _accounts ??= LocalDbService().accountChanges.listen((_) => reset());
  }

  void reset() {
    _requests.cancel('Analytics context changed');
    _requests = CancelToken();
    _lastFeature = null;
  }

  Future<void> preferenceChanged(bool enabled) async {
    reset();
    if (!enabled) {
      final box = await LocalDbService().settingsBox();
      await box.delete('posthog_distinct_id');
      await box.delete('posthog_active_day');
    }
  }

  void routeChanged(String route) {
    final previousRoute = _route;
    _route = route;
    if (route == '/onboarding') {
      unawaited(track('onboarding_started'));
    }
    if (previousRoute == '/onboarding' && route == '/home') {
      unawaited(track('onboarding_completed'));
    }
    const routes = {
      '/home': 'home',
      '/quiz-selection': 'assessments',
      '/journal': 'journals',
      '/community': 'community',
      '/content': 'resources',
      '/settings': 'settings',
    };
    final feature = routes[route];
    if (feature == null) {
      _lastFeature = null;
      return;
    }
    unawaited(track('app_active'));
    if (_lastFeature != feature) {
      _lastFeature = feature;
      unawaited(track('feature_opened', feature: feature));
    }
  }

  Future<void> track(String event, {String? feature}) async {
    if (key.isEmpty ||
        !{
          'https://eu.i.posthog.com',
          'https://us.i.posthog.com',
        }.contains(host) ||
        !events.contains(event) ||
        (feature != null && !features.contains(feature))) {
      return;
    }
    // Never emit analytics from a crisis, health-detail or private-message route.
    if (!{
      '/home',
      '/quiz-selection',
      '/journal',
      '/community',
      '/content',
      '/settings',
      '/onboarding',
      '/create-account',
    }.contains(_route)) {
      return;
    }
    final owner = LocalDbService().activeUserId;
    final route = _route;
    final cancel = _requests;
    if (owner == null) return;
    try {
      final box = await LocalDbService().settingsBox();
      final preferences = box.get('privacy_preferences');
      if (preferences is! Map ||
          preferences['analytics'] != true ||
          owner != LocalDbService().activeUserId) {
        return;
      }
      final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      if (event == 'app_active' && box.get('posthog_active_day') == day) return;
      var id = box.get('posthog_distinct_id') as String?;
      if (id == null) {
        id = List.generate(
          24,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
        await box.put('posthog_distinct_id', id);
      }
      final package = await PackageInfo.fromPlatform();
      if (owner != LocalDbService().activeUserId ||
          cancel.isCancelled ||
          route != _route) {
        return;
      }
      final current = box.get('privacy_preferences');
      if (current is! Map || current['analytics'] != true) return;
      await _http.post(
        '$host/i/v0/e/',
        cancelToken: cancel,
        data: {
          'api_key': key,
          'event': event,
          'properties': {
            'distinct_id': id,
            'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'app_version': package.version,
            if (feature != null) 'feature': feature,
            r'$process_person_profile': false,
            r'$geoip_disable': true,
          },
        },
      );
      if (event == 'app_active' &&
          owner == LocalDbService().activeUserId &&
          !cancel.isCancelled) {
        await box.put('posthog_active_day', day);
      }
    } catch (_) {
      /* Optional analytics never blocks a user action. */
    }
  }
}
