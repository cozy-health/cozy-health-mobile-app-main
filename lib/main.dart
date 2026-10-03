import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/routing/app_router.dart';
import 'core/services/install_marker_service.dart';
import 'core/services/local_db_service.dart';
import 'core/models/user_profile.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDbService().init();
  await InstallMarkerService().clearLingeringSessionOnFreshInstall();
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
              child: child!,
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
