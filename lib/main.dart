import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/services/local_db_service.dart';
import 'core/models/user_profile.dart';
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
        
        // Default theme values
        ThemeMode themeMode = ThemeMode.system;
        Color accentColor = const Color(0xFF0460D8);
        double textScaleFactor = 1.0;
        
        if (profile != null) {
          switch (profile.theme.toLowerCase()) {
            case 'light':
              themeMode = ThemeMode.light;
              break;
            case 'dark':
              themeMode = ThemeMode.dark;
              break;
            default:
              themeMode = ThemeMode.system;
          }
          
          if (profile.accentColor != 'lavender' && int.tryParse(profile.accentColor) != null) {
            accentColor = Color(int.parse(profile.accentColor));
          }
          
          textScaleFactor = profile.textSize;
        }

        return MaterialApp.router(
          title: 'Cozy Health',
          themeMode: themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: accentColor, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: accentColor, brightness: Brightness.dark),
            useMaterial3: true,
          ),
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
      }
    );
  }
}
