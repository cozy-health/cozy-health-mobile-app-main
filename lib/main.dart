import 'core/services/usage_analytics.dart';
import 'core/widgets/network_observer.dart';
import 'features/quiz/data/quiz_invitation_service.dart';
import 'features/quiz/presentation/widgets/quiz_share_actions.dart';
import 'dart:async';
import 'core/services/push_notification_service.dart';
import 'core/services/background_restore_service.dart';
import 'features/notifications/presentation/widgets/push_notification_host.dart';
import 'core/widgets/security_blur.dart';
import 'core/widgets/app_availability_gate.dart';
import 'core/services/crash_reporting.dart';
import 'core/security_gate.dart';
import 'core/services/install_marker_service.dart';
import 'core/storage/token_storage.dart';
import 'core/widgets/device_integrity_notice.dart';
import 'core/widgets/consent_gate.dart';
import 'core/widgets/startup_cover.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'core/routing/app_router.dart';
import 'core/services/local_db_service.dart';
import 'core/services/feature_flags_service.dart';
import 'core/models/user_profile.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/appearance_preferences.dart';
import 'core/utils/motion.dart';
import 'features/settings/data/profile_repository.dart';
import 'utils/screen_util.dart';

Future<void> main() => CrashReporting.run(_startApp);

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppBootstrap());
}

Future<void> _prepareApp() async {
  await LocalDbService().init();
  await FeatureFlagsService.instance.initialize();
  await InstallMarkerService().clearLingeringSessionOnFreshInstall();
  UsageAnalytics.instance.initialize();
  AppRouter.router.routeInformationProvider.addListener(() {
    unawaited(
      UsageAnalytics.instance.routeChanged(
        AppRouter.router.routeInformationProvider.value.uri.path,
      ),
    );
    CrashReporting.tagRoute(
      AppRouter.router.routeInformationProvider.value.uri.path,
    );
  });
  CrashReporting.tagRoute(
    AppRouter.router.routeInformationProvider.value.uri.path,
  );
  BackgroundRestoreService.instance.initialize();
  unawaited(PushNotificationService.instance.initialize());
  unawaited(QuizInvitationService.instance.initialize());
  unawaited(cleanupQuizExports());
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();
  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  bool _ready = false, _working = false, _failed = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 8), () {
      if (mounted && !_ready) setState(() => _failed = true);
    });
    if (_working) {
      setState(() => _failed = false);
      return;
    }
    _working = true;
    if (_failed) setState(() => _failed = false);
    _prepareApp()
        .then((_) {
          if (mounted) setState(() => _ready = true);
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        })
        .whenComplete(() {
          _working = false;
          _timeout?.cancel();
        });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ready
      ? const CozyHealthApp()
      : MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StartupIcon(),
                      if (_failed) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'We couldn’t open your saved information securely. '
                          'Your files have been kept. Try again or contact support.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: _start,
                          child: const Text('Try again'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
}

class CozyHealthApp extends StatefulWidget {
  const CozyHealthApp({super.key});

  @override
  State<CozyHealthApp> createState() => _CozyHealthAppState();
}

class _CozyHealthAppState extends State<CozyHealthApp> {
  late final ProfileRepository _profileRepository;
  late final Stream<UserProfile?> _profileStream;
  UserProfile? _cachedProfile;

  @override
  void initState() {
    super.initState();
    _profileRepository = ProfileRepository();
    try {
      _cachedProfile = LocalDbService().getUserProfile();
    } catch (_) {
      // Lightweight widget tests can start without initialized profile storage.
    }
    _profileStream = _profileRepository.watchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _profileStream,
      initialData: _cachedProfile,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final themeMode = _themeModeFromString(profile?.theme ?? 'system');
        final textScaleFactor = profile?.textSize ?? 1.0;
        final accent = _accentColorFromString(profile?.accentColor);
        final lightTheme = AppTheme.withAccent(AppTheme.light, accent);
        final darkTheme = AppTheme.withAccent(AppTheme.dark, accent);
        final lightHighContrast = AppTheme.highContrast(lightTheme);
        final darkHighContrast = AppTheme.highContrast(darkTheme);
        final highContrast = profile?.highContrast ?? false;

        return MaterialApp.router(
          title: 'Cozy Health',
          themeMode: themeMode,
          theme: highContrast ? lightHighContrast : lightTheme,
          darkTheme: highContrast ? darkHighContrast : darkTheme,
          highContrastTheme: lightHighContrast,
          highContrastDarkTheme: darkHighContrast,
          themeAnimationDuration: (profile?.reduceMotion ?? false)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final media = appearanceMediaQuery(
              MediaQuery.of(context),
              textMultiplier: textScaleFactor,
              highContrast: highContrast,
              reduceMotion: profile?.reduceMotion ?? false,
            );
            final currentTheme = motionTheme(
              Theme.of(context),
              media.disableAnimations,
            );
            ScreenUtil.init(context);
            final brightness = Theme.of(context).brightness;
            final isDark = brightness == Brightness.dark;
            final overlayStyle = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: brightness,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            );
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlayStyle,
              child: MediaQuery(
                data: media,
                child: Theme(
                  data: currentTheme,
                  child: LiveAppearanceTheme(
                    theme: currentTheme,
                    child: HeroMode(
                      enabled: !media.disableAnimations,
                      child: Listener(
                        onPointerDown: (_) {
                          if (WidgetsBinding.instance.lifecycleState ==
                              AppLifecycleState.resumed) {
                            TokenStorage().recordActivity();
                          }
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          child: NotificationListener<ScrollStartNotification>(
                            onNotification: (notification) {
                              if (notification.dragDetails != null) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              }
                              return false;
                            },
                            child: StartupCover(
                              child: NetworkObserver(
                                child: AppAvailabilityGate(
                                  child: SecurityCaptureOverlay(
                                    child: SecurityGate(
                                      child: ConsentGate(
                                        child: PushNotificationHost(
                                          child: DeviceIntegrityNotice(
                                            child: ListenableBuilder(
                                              listenable: AppRouter
                                                  .router
                                                  .routeInformationProvider,
                                              builder: (context, _) =>
                                                  StartupDestination(
                                                    ready:
                                                        !{
                                                          AppRouter.splash,
                                                          AppRouter.home,
                                                        }.contains(
                                                          AppRouter
                                                              .router
                                                              .routeInformationProvider
                                                              .value
                                                              .uri
                                                              .path,
                                                        ),
                                                    child: child!,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          routerConfig: AppRouter.router,
        );
      },
    );
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Color _accentColorFromString(String? value) => AppColors.resolveAccent(value);
}
