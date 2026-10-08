import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../routing/app_router.dart';
import '../services/app_version.dart';
import '../services/feature_flags_service.dart';
import '../services/local_db_service.dart';
import 'app_button.dart';

typedef VersionLoader = Future<String> Function();
typedef StoreLauncher = Future<bool> Function(Uri url);
typedef DateTimeReader = DateTime Function();

class AppAvailabilityGate extends StatefulWidget {
  const AppAvailabilityGate({
    super.key,
    required this.child,
    this.flags,
    this.router,
    this.versionLoader,
    this.launchStore,
    this.platform,
    this.now,
    this.loadSoftUpdateDismissedAt,
    this.saveSoftUpdateDismissedAt,
    this.pollInterval = const Duration(seconds: 30),
  });

  final Widget child;
  final FeatureFlagsService? flags;
  final GoRouter? router;
  final VersionLoader? versionLoader;
  final StoreLauncher? launchStore;
  final TargetPlatform? platform;
  final DateTimeReader? now;
  final Future<DateTime?> Function()? loadSoftUpdateDismissedAt;
  final Future<void> Function(DateTime dismissedAt)? saveSoftUpdateDismissedAt;
  final Duration pollInterval;

  @override
  State<AppAvailabilityGate> createState() => _AppAvailabilityGateState();
}

class _AppAvailabilityGateState extends State<AppAvailabilityGate>
    with WidgetsBindingObserver {
  static const _dismissKey = 'soft_update_dismissed_at';
  late FeatureFlagsService _flags;
  late GoRouter _router;
  late final DateTimeReader _now;
  String? _currentVersion;
  DateTime? _softUpdateDismissedAt;
  bool _launchingStore = false;
  String? _storeError;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _flags = widget.flags ?? FeatureFlagsService.instance;
    _router = widget.router ?? AppRouter.router;
    _now = widget.now ?? DateTime.now;
    WidgetsBinding.instance.addObserver(this);
    _flags.addListener(_refreshView);
    _router.routeInformationProvider.addListener(_refreshView);
    _loadVersion();
    _loadSoftUpdateDismissal();
    _syncMaintenancePolling();
  }

  @override
  void didUpdateWidget(covariant AppAvailabilityGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flags != widget.flags && widget.flags != null) {
      _flags.removeListener(_refreshView);
      _flags = widget.flags!;
      _flags.addListener(_refreshView);
    }
    if (oldWidget.router != widget.router && widget.router != null) {
      _router.routeInformationProvider.removeListener(_refreshView);
      _router = widget.router!;
      _router.routeInformationProvider.addListener(_refreshView);
    }
    _syncMaintenancePolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncMaintenancePolling();
      unawaited(_flags.refresh());
    } else {
      _pollTimer?.cancel();
    }
  }

  Future<void> _loadVersion() async {
    final loader = widget.versionLoader ?? _defaultVersionLoader;
    var version = '1.0.0';
    try {
      version = await loader();
    } catch (_) {
      // Fail open if the native package info plugin is unavailable.
    }
    if (mounted) setState(() => _currentVersion = version);
  }

  static Future<String> _defaultVersionLoader() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<void> _loadSoftUpdateDismissal() async {
    final loader = widget.loadSoftUpdateDismissedAt ?? _defaultLoadDismissal;
    DateTime? dismissedAt;
    try {
      dismissedAt = await loader();
    } catch (_) {
      dismissedAt = null;
    }
    if (mounted) setState(() => _softUpdateDismissedAt = dismissedAt);
  }

  Future<DateTime?> _defaultLoadDismissal() async {
    if (!LocalDbService().isBoxOpen(LocalDbService.userSettingsBoxName)) {
      return null;
    }
    try {
      final value = (await LocalDbService().settingsBox()).get(_dismissKey);
      if (value is String) return DateTime.tryParse(value);
    } catch (_) {
      // Availability checks should never crash because local settings are unavailable.
    }
    return null;
  }

  Future<void> _dismissSoftUpdate() async {
    final dismissedAt = _now();
    setState(() => _softUpdateDismissedAt = dismissedAt);
    final saver = widget.saveSoftUpdateDismissedAt ?? _defaultSaveDismissal;
    await saver(dismissedAt);
  }

  Future<void> _defaultSaveDismissal(DateTime dismissedAt) async {
    if (!LocalDbService().isBoxOpen(LocalDbService.userSettingsBoxName)) {
      return;
    }
    try {
      await (await LocalDbService().settingsBox()).put(
        _dismissKey,
        dismissedAt.toIso8601String(),
      );
    } catch (_) {
      // A missed dismissal is better than blocking the app with a local storage error.
    }
  }

  void _refreshView() {
    if (!mounted) return;
    setState(() {});
    _syncMaintenancePolling();
  }

  void _syncMaintenancePolling() {
    _pollTimer?.cancel();
    if (!_flags.configuration.maintenanceMode) return;
    _pollTimer = Timer.periodic(
      widget.pollInterval,
      (_) => unawaited(_flags.refresh()),
    );
  }

  bool get _isCrisisRoute {
    final path = _router.routeInformationProvider.value.uri.path;
    return {
      AppRouter.crisisHub,
      AppRouter.crisisOverlay,
      AppRouter.crisisContact,
      AppRouter.safetyPlan,
      AppRouter.safetyPlanView,
      AppRouter.grounding,
      AppRouter.breathing,
      AppRouter.professionalHelp,
      AppRouter.crisisFollowUp,
    }.contains(path);
  }

  _AvailabilityState get _availability {
    if (_isCrisisRoute) return _AvailabilityState.available;
    final current = AppVersion.tryParse(_currentVersion ?? '1.0.0');
    final min = AppVersion.tryParse(_flags.configuration.minAppVersion);
    if (current != null && min != null && current < min) {
      return _AvailabilityState.forceUpdate;
    }
    if (_flags.configuration.maintenanceMode) {
      return _AvailabilityState.maintenance;
    }
    return _AvailabilityState.available;
  }

  bool get _showSoftUpdate {
    if (_availability != _AvailabilityState.available || _isCrisisRoute) {
      return false;
    }
    final current = AppVersion.tryParse(_currentVersion ?? '1.0.0');
    final latest = AppVersion.tryParse(_flags.configuration.latestAppVersion);
    if (current == null || latest == null || current.compareTo(latest) >= 0) {
      return false;
    }
    final dismissedAt = _softUpdateDismissedAt;
    return dismissedAt == null || _now().difference(dismissedAt).inHours >= 24;
  }

  Uri? get _storeUrl {
    final platform = widget.platform ?? defaultTargetPlatform;
    final raw = platform == TargetPlatform.iOS
        ? _flags.configuration.updateIosUrl
        : _flags.configuration.updateAndroidUrl;
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'https') return null;
    return uri;
  }

  Future<void> _openStore() async {
    final uri = _storeUrl;
    if (uri == null) {
      setState(() {
        _storeError = 'The update link is not available yet. Please try again.';
      });
      return;
    }
    setState(() {
      _launchingStore = true;
      _storeError = null;
    });
    final launcher = widget.launchStore ?? _defaultLaunchStore;
    final launched = await launcher(uri);
    if (!mounted) return;
    setState(() {
      _launchingStore = false;
      _storeError = launched ? null : 'We could not open the store.';
    });
  }

  static Future<bool> _defaultLaunchStore(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  void _openCrisisResources() {
    if (_router.routeInformationProvider.value.uri.path !=
        AppRouter.crisisHub) {
      _router.push(AppRouter.crisisHub);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flags.removeListener(_refreshView);
    _router.routeInformationProvider.removeListener(_refreshView);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availability = _availability;
    final blocked = availability != _AvailabilityState.available;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: blocked,
          child: ExcludeFocus(
            excluding: blocked,
            child: Column(
              children: [
                _SoftUpdateBanner(
                  visible: _showSoftUpdate,
                  onUpdate: _openStore,
                  onDismiss: _dismissSoftUpdate,
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ),
        if (blocked)
          _BlockingAvailabilityScreen(
            state: availability,
            message: _flags.configuration.maintenanceMessage,
            storeError: _storeError,
            launchingStore: _launchingStore,
            onUpdate: _openStore,
            onRetry: () => unawaited(_flags.refresh()),
            onCrisis: _openCrisisResources,
          ),
      ],
    );
  }
}

enum _AvailabilityState { available, forceUpdate, maintenance }

class _SoftUpdateBanner extends StatelessWidget {
  const _SoftUpdateBanner({
    required this.visible,
    required this.onUpdate,
    required this.onDismiss,
  });

  final bool visible;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final reduce =
        MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).accessibleNavigation;
    final banner = Material(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.system_update_alt, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('New version available.')),
              TextButton(onPressed: onUpdate, child: const Text('Update')),
              Semantics(
                label: 'Dismiss update banner',
                button: true,
                child: IconButton(
                  key: const Key('soft_update_dismiss'),
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 250),
      child: visible ? banner : const SizedBox.shrink(),
    );
  }
}

class _BlockingAvailabilityScreen extends StatelessWidget {
  const _BlockingAvailabilityScreen({
    required this.state,
    required this.onUpdate,
    required this.onRetry,
    required this.onCrisis,
    required this.launchingStore,
    this.message,
    this.storeError,
  });

  final _AvailabilityState state;
  final VoidCallback onUpdate;
  final VoidCallback onRetry;
  final VoidCallback onCrisis;
  final bool launchingStore;
  final String? message;
  final String? storeError;

  @override
  Widget build(BuildContext context) {
    final forceUpdate = state == _AvailabilityState.forceUpdate;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    forceUpdate
                        ? Icons.system_update_alt
                        : Icons.construction_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    forceUpdate
                        ? 'Cozy Health has been updated.'
                        : "We're doing some quick maintenance.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    forceUpdate
                        ? 'Please update to continue.'
                        : (message?.trim().isNotEmpty == true
                              ? message!.trim()
                              : 'Back in a moment.'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (storeError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      storeError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (forceUpdate)
                    AppButton(
                      text: 'Update now',
                      isLoading: launchingStore,
                      onPressed: onUpdate,
                      trailingIcon: Icons.open_in_new,
                    )
                  else
                    AppButton(
                      text: 'Retry',
                      onPressed: onRetry,
                      trailingIcon: Icons.refresh,
                    ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Crisis resources',
                    isOutlined: true,
                    onPressed: onCrisis,
                    trailingIcon: Icons.favorite_outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
