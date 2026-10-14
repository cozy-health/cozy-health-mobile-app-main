// Diagnostic audit: records rendering exceptions; it does not certify a screen.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/models/subscription_status.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/utils/screen_util.dart';
import 'package:cozy_health/features/settings/presentation/screens/accessibility_settings_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/appearance_settings_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/notification_preferences_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/email_settings_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/phone_settings_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/two_factor_auth_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/connected_apps_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/billing_history_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/referral_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/feedback_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/report_problem_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/reminder_times_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/blocked_users_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/data_export_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/data_export_status_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/download_my_data_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/account_deletion_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/legal_hub_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/terms_policies_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/edit_profile_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/change_password_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/monthly_report_screen.dart';
import 'package:cozy_health/features/journal/presentation/screens/voice_recording_screen.dart';
import 'package:cozy_health/features/notifications/presentation/widgets/notification_permission_sheet.dart';
import 'package:cozy_health/features/notifications/presentation/widgets/notification_denied_sheet.dart';
import 'package:cozy_health/features/community/presentation/widgets/report_sheet.dart';
import '../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final observations = <Map<String, Object?>>[];
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await installLocalTestFonts();
    directory = await Directory.systemTemp.createTemp('cozy_full_audit_');
    Hive.init(directory.path);
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(SubscriptionStatusAdapter());
    await EncryptedHive.openBox<UserProfile>(LocalDbService.userProfileBoxName);
    await EncryptedHive.openBox<SubscriptionStatus>(
      LocalDbService.subscriptionStatusBoxName,
    );
    await LocalDbService().settingsBox();
  });
  tearDownAll(() async {
    await File(
      'docs/ui-review/full-app-probe-results.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(observations));
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
    resetLocalTestFonts();
  });
  final screens = <String, Widget Function()>{
    'Accessibility': () => const AccessibilitySettingsScreen(),
    'Appearance': () => const AppearanceSettingsScreen(),
    'Language': () => const LanguageSettingsScreen(),
    'Notification preferences': () => const NotificationPreferencesScreen(),
    'Email': () => const EmailSettingsScreen(),
    'Phone': () => const PhoneSettingsScreen(),
    'Two-factor authentication': () => const TwoFactorAuthScreen(),
    'Connected apps': () => const ConnectedAppsScreen(),
    'Billing history': () => const BillingHistoryScreen(),
    'Referral': () => const ReferralScreen(),
    'Feedback': () => const FeedbackScreen(),
    'Report problem': () => const ReportProblemScreen(),
    'Reminder times': () => const ReminderTimesScreen(),
    'Blocked users': () => const BlockedUsersScreen(),
    'Export request': () => const DataExportScreen(),
    'Export status': () => const DataExportStatusScreen(),
    'Download data': () => const DownloadMyDataScreen(),
    'Account deletion': () => const AccountDeletionScreen(),
    'Legal hub': () => const LegalHubScreen(),
    'Terms': () => const TermsPoliciesScreen(),
    'Edit profile': () => const EditProfileScreen(),
    'Change password': () => const ChangePasswordScreen(),
    'Monthly report': () => const MonthlyReportScreen(),
    'Voice journal': () => const VoiceRecordingScreen(),
    'Notification permission sheet': () =>
        const Scaffold(body: NotificationPermissionSheet()),
    'Notification denied sheet': () =>
        const Scaffold(body: NotificationDeniedSheet()),
    'Community report sheet': () =>
        Scaffold(body: ReportSheet(onSubmit: () {})),
  };
  for (final dark in [false, true]) {
    for (final landscape in [false, true]) {
      for (final entry in screens.entries) {
        testWidgets('audit ${entry.key} dark=$dark landscape=$landscape', (
          tester,
        ) async {
          tester.view.physicalSize = landscape
              ? const Size(568, 320)
              : const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final errors = <String>[];
          final oldHandler = FlutterError.onError;
          FlutterError.onError = (details) =>
              errors.add(details.exceptionAsString());
          try {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.highContrast(
                  dark ? AppTheme.dark : AppTheme.light,
                ),
                builder: (context, child) {
                  ScreenUtil.init(context);
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(2),
                      disableAnimations: true,
                      accessibleNavigation: true,
                      highContrast: true,
                    ),
                    child: child!,
                  );
                },
                home: entry.value(),
              ),
            );
            await tester.pump(const Duration(seconds: 2));
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(seconds: 3));
          } finally {
            FlutterError.onError = oldHandler;
          }
          observations.add({
            'screen': entry.key,
            'dark': dark,
            'landscape': landscape,
            'errors': errors,
          });
        });
      }
    }
  }
  test(
    'notification adapter round trip retains optional metadata (diagnostic)',
    () async {
      final adapter = AppNotificationAdapter();
      Hive.registerAdapter(adapter);
      final box = await Hive.openBox<AppNotification>('audit_notifications');
      final time = DateTime.utc(2026, 10, 10);
      await box.put(
        'n',
        AppNotification(
          id: 'n',
          title: 't',
          body: 'b',
          type: 'security',
          read: true,
          createdAt: time,
          deepLink: '/active-sessions',
          readAt: time,
        ),
      );
      await box.close();
      final reopened = await Hive.openBox<AppNotification>(
        'audit_notifications',
      );
      final result = reopened.get('n')!;
      observations.add({
        'screen': 'Notification storage round trip',
        'deepLink': result.deepLink,
        'readAt': result.readAt?.toIso8601String(),
        'errors': result.deepLink == null && result.readAt == null
            ? ['deepLink and readAt were lost after box reopening']
            : <String>[],
      });
      await reopened.close();
    },
  );
}
