import '../storage/encrypted_hive.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import '../api/api_client.dart';

typedef ConfigFetcher = Future<Map<String, dynamic>> Function();

class AppConfiguration {
  const AppConfiguration({
    this.flags = defaults,
    this.minAppVersion = '1.0.0',
    this.latestAppVersion = '1.0.0',
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.updateIosUrl,
    this.updateAndroidUrl,
  });

  static const defaults = <String, bool>{
    'ai_assistant': true,
    'push_notifications': true,
    'community': false,
    'content_feed': false,
    'quiz': true,
    'widgets': false,
    'analytics': false,
  };
  final Map<String, bool> flags;
  final String minAppVersion;
  final String latestAppVersion;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final String? updateIosUrl;
  final String? updateAndroidUrl;

  factory AppConfiguration.fromJson(Map<String, dynamic> json) {
    final rawFlags = json['flags'];
    if (rawFlags is! Map || rawFlags.values.any((value) => value is! bool)) {
      throw const FormatException('Invalid feature configuration');
    }
    String version(String key) {
      final value = json[key] ?? '1.0.0';
      if (value is! String || !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(value)) {
        throw const FormatException('Invalid version configuration');
      }
      return value;
    }

    if (json['maintenance_mode'] != null && json['maintenance_mode'] is! bool) {
      throw const FormatException('Invalid maintenance configuration');
    }
    return AppConfiguration(
      flags: Map.unmodifiable({
        for (final entry in defaults.entries)
          entry.key: rawFlags[entry.key] as bool? ?? entry.value,
      }),
      minAppVersion: version('min_app_version'),
      latestAppVersion: version('latest_app_version'),
      maintenanceMode: json['maintenance_mode'] == true,
      maintenanceMessage: json['maintenance_message'] as String?,
      updateIosUrl: json['update_ios_url'] as String?,
      updateAndroidUrl: json['update_android_url'] as String?,
    );
  }

  bool isEnabled(String key) {
    if (const {
      'crisis',
      'crisis_hub',
      'breathing',
      'grounding',
      'safety_plan',
    }.contains(key)) {
      return true;
    }
    return flags[key] ?? false;
  }
}

class FeatureFlagsService extends ChangeNotifier with WidgetsBindingObserver {
  FeatureFlagsService({
    ConfigFetcher? fetch,
    DateTime Function()? now,
    Box<dynamic>? cache,
  }) : _fetch = fetch ?? _fetchConfig,
       _now = now ?? DateTime.now,
       _cache = cache;

  static final instance = FeatureFlagsService();
  static const cacheTtl = Duration(minutes: 60);
  static const refreshInterval = Duration(minutes: 10);
  final ConfigFetcher _fetch;
  final DateTime Function() _now;
  Box<dynamic>? _cache;
  AppConfiguration _configuration = const AppConfiguration();
  AppConfiguration get configuration => _configuration;
  bool isEnabled(String key) => _configuration.isEnabled(key);
  String get minAppVersion => _configuration.minAppVersion;
  bool get maintenanceMode => _configuration.maintenanceMode;
  bool ready = false;
  bool _disposed = false;
  bool _observing = false;
  Timer? _timer;
  Future<void>? _inFlight;

  static Future<Map<String, dynamic>> _fetchConfig() async {
    final response = await ApiClient().get('/config', withAuth: false);
    final data = response is Response ? response.data : response;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> initialize({bool poll = true}) async {
    _cache ??= await EncryptedHive.openBox<dynamic>('app_config');
    try {
      final stored = _cache!.get('configuration');
      if (stored is Map) {
        final fetched = DateTime.parse(stored['fetched_at'] as String);
        final age = _now().difference(fetched);
        if (!age.isNegative && age < cacheTtl) {
          _configuration = AppConfiguration.fromJson(
            Map<String, dynamic>.from(stored['payload'] as Map),
          );
          ready = true;
        }
      }
    } catch (_) {
      /* Ignore malformed cache; never block access to support. */
    }
    if (poll && !_disposed) {
      _observing = true;
      WidgetsBinding.instance.addObserver(this);
      _startTimer();
    }
    if (!_disposed) notifyListeners();
    unawaited(refresh());
  }

  Future<void> refresh() =>
      _inFlight ??= _refresh().whenComplete(() => _inFlight = null);

  Future<void> _refresh() async {
    try {
      final payload = await _fetch();
      final parsed = AppConfiguration.fromJson(payload);
      if (_disposed) return;
      _configuration = parsed;
      await _cache?.put('configuration', {
        'payload': payload,
        'fetched_at': _now().toIso8601String(),
      });
    } catch (_) {
      /* Keep valid cache or defaults during network failure. */
    }
    ready = true;
    if (!_disposed) notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      unawaited(refresh());
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class FeatureFlags {
  static bool isEnabled(String key) =>
      FeatureFlagsService.instance.isEnabled(key);
  static String get minAppVersion => FeatureFlagsService.instance.minAppVersion;
  static bool get maintenanceMode =>
      FeatureFlagsService.instance.maintenanceMode;
}
