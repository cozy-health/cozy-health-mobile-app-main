import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/services/local_db_service.dart';
import 'core/models/user_profile.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDbService().init();
  runApp(const CozyHealthApp());
}

class CozyHealthApp extends StatelessWidget {
  const CozyHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: ProfileRepository().watchProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final themeMode = _themeModeFromString(profile?.theme ?? 'system');
        final textScaleFactor = profile?.textSize ?? 1.0;

        return MaterialApp.router(
          title: 'Cozy Health',
          themeMode: themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
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
}
