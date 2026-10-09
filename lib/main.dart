import 'core/widgets/network_observer.dart';
import 'core/widgets/security_blur.dart';
import 'core/widgets/app_availability_gate.dart';
import 'core/services/crash_reporting.dart';
import 'core/security_gate.dart';
import 'core/services/install_marker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/routing/app_router.dart';
import 'core/services/local_db_service.dart';
import 'core/services/feature_flags_service.dart';
import 'core/models/user_profile.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/profile_repository.dart';
import 'utils/screen_util.dart';

Future<void> main() => CrashReporting.run(_startApp);

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDbService().init();
  await FeatureFlagsService.instance.initialize();
  await InstallMarkerService().clearLingeringSessionOnFreshInstall();
  AppRouter.router.routeInformationProvider.addListener(() {
    CrashReporting.tagRoute(
      AppRouter.router.routeInformationProvider.value.uri.path,
    );
  });
  CrashReporting.tagRoute(
    AppRouter.router.routeInformationProvider.value.uri.path,
  );
  runApp(const CozyHealthApp());
}

class CozyHealthApp extends StatefulWidget {
  const CozyHealthApp({super.key});

  @override
  State<CozyHealthApp> createState() => _CozyHealthAppState();
}

class _CozyHealthAppState extends State<CozyHealthApp> {
  late final ProfileRepository _profileRepository;
  late final Stream<UserProfile?> _profileStream;

  @override
  void initState() {
    super.initState();
    _profileRepository = ProfileRepository();
    _profileStream = _profileRepository.watchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _profileStream,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final themeMode = _themeModeFromString(profile?.theme ?? 'system');
        final textScaleFactor = profile?.textSize ?? 1.0;
        final accent = _accentColorFromString(profile?.accentColor);
        final lightTheme = _themeWithAccent(AppTheme.light, accent);
        final darkTheme = _themeWithAccent(AppTheme.dark, accent);

        return MaterialApp.router(
          title: 'Cozy Health',
          themeMode: themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            ScreenUtil.init(context);
            final brightness = Theme.of(context).brightness;
            final isDark = brightness == Brightness.dark;
            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: brightness,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
              ),
            );
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScaleFactor),
                boldText: profile?.highContrast ?? false,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: NotificationListener<ScrollStartNotification>(
                  onNotification: (notification) {
                    if (notification.dragDetails != null) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    }
                    return false;
                  },
                  child: NetworkObserver(
                    child: AppAvailabilityGate(
                      child: SecurityCaptureOverlay(
                        child: SecurityGate(child: child!),
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

  ThemeData _themeWithAccent(ThemeData theme, Color accent) {
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(primary: accent),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            theme.elevatedButtonTheme.style?.copyWith(
              backgroundColor: WidgetStateProperty.all(accent),
              foregroundColor: WidgetStateProperty.all(Colors.white),
            ) ??
            ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            theme.textButtonTheme.style?.copyWith(
              foregroundColor: WidgetStateProperty.all(accent),
            ) ??
            TextButton.styleFrom(foregroundColor: accent),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            theme.outlinedButtonTheme.style?.copyWith(
              foregroundColor: WidgetStateProperty.all(accent),
              side: WidgetStateProperty.all(BorderSide(color: accent)),
            ) ??
            OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent),
            ),
      ),
      switchTheme: theme.switchTheme.copyWith(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return null;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return null;
        }),
      ),
      checkboxTheme: theme.checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return null;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      radioTheme: theme.radioTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return null;
        }),
      ),
      sliderTheme: theme.sliderTheme.copyWith(
        activeTrackColor: accent,
        thumbColor: accent,
      ),
      chipTheme: theme.chipTheme.copyWith(
        selectedColor: accent.withValues(alpha: 0.15),
        side: BorderSide(color: accent),
      ),
      bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
        selectedItemColor: accent,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: accent),
      ),
      textSelectionTheme: theme.textSelectionTheme.copyWith(
        cursorColor: accent,
      ),
      snackBarTheme: theme.snackBarTheme.copyWith(actionTextColor: accent),
      tabBarTheme: theme.tabBarTheme.copyWith(
        indicatorColor: accent,
        labelColor: accent,
      ),
      listTileTheme: theme.listTileTheme.copyWith(
        selectedTileColor: accent.withValues(alpha: 0.12),
      ),
      floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
        backgroundColor: accent,
      ),
      progressIndicatorTheme: theme.progressIndicatorTheme.copyWith(
        color: accent,
      ),
    );
  }

  Color _accentColorFromString(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty || raw == 'lavender') {
      return const Color(0xFF0460D8);
    }

    if (raw.startsWith('#') && raw.length == 7) {
      return Color(int.parse('FF${raw.substring(1)}', radix: 16));
    }

    final parsed = int.tryParse(raw);
    if (parsed != null) return Color(parsed);

    return const Color(0xFF0460D8);
  }
}
