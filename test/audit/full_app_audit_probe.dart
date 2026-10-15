import 'package:cozy_health/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:cozy_health/features/assistant/presentation/widgets/chat_settings_view.dart';
import 'package:cozy_health/features/auth/presentation/screens/congratulations_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/create_account_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/login_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/restore_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/welcome_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/community_guidelines_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/community_search_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/featured_posts_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/follow_list_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/message_requests_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/moderation_queue_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/topics_screen.dart';
import 'package:cozy_health/features/community/presentation/widgets/community_groups.dart';
import 'package:cozy_health/features/content/presentation/screens/content_search_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/daily_affirmation_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/saved_articles_screen.dart';
import 'package:cozy_health/features/crisis/presentation/screens/crisis_screens.dart';
import 'package:cozy_health/features/home/presentation/screens/home_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/activity_mood_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/mood_trend_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/sleep_mood_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/triggers_analysis_screen.dart';
import 'package:cozy_health/features/journal/presentation/screens/journal_screen.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_feeling_screen.dart';
import 'package:cozy_health/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:cozy_health/features/personalization/presentation/screens/personalization_screen.dart';
import 'package:cozy_health/features/preparing_cozy/presentation/screens/preparing_cozy_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_shared_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/about_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/active_sessions_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/cancel_subscription_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/digital_wellbeing_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/help_center_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/help_support_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/profile_view_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_access_log_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_resources_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/restore_purchases_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/subscription_screen.dart';
import 'package:cozy_health/features/splash/presentation/screens/splash_screen.dart';
import 'package:cozy_health/features/wellness/presentation/wellness_screen.dart';
// Offline surface audit. SURFACE_STRICT fails on collected rendering exceptions.
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/chat_message.dart';
import 'package:cozy_health/core/models/chat_conversation.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/models/saved_article.dart';
import 'package:cozy_health/core/models/safety_plan.dart';
import 'dart:io';
import 'package:cozy_health/core/data/placeholder_data.dart';
import 'package:cozy_health/features/assistant/models/chat.dart' as assistant;
import 'package:cozy_health/features/assistant/presentation/widgets/conversation_list_view.dart';
import 'package:cozy_health/features/community/presentation/screens/direct_messages_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/user_profile_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/category_detail_screen.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_success_screen.dart';
import 'package:cozy_health/features/quiz/domain/clinical_assessment.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_detail_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_taking_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_result_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_result_detail_screen.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/clinical_disclaimer_sheet.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/provider_share_confirm_dialog.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/quiz_back_confirm_dialog.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/quiz_retake_confirm_dialog.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/quiz_support_sheet.dart';
import 'package:cozy_health/features/community/presentation/widgets/visibility_sheet.dart';
import '../features/quiz/assessment_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../support/surface_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final observations = <Map<String, Object?>>[];
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          (call) async => null,
        );
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await installLocalTestFonts();
    directory = await Directory.systemTemp.createTemp('cozy_full_audit_');
    Hive.init(directory.path);
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(SubscriptionStatusAdapter());
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(ChatConversationAdapter());
    Hive.registerAdapter(QuizAttemptAdapter());
    Hive.registerAdapter(SavedArticleAdapter());
    Hive.registerAdapter(SafetyPlanAdapter());
    Hive.registerAdapter(AppNotificationAdapter());
    await EncryptedHive.openBox<MoodEntry>(LocalDbService.moodBoxName);
    await EncryptedHive.openBox<JournalEntry>(LocalDbService.journalBoxName);
    await EncryptedHive.openBox<ChatMessage>(LocalDbService.chatMessageBoxName);
    await EncryptedHive.openBox<ChatConversation>(
      LocalDbService.chatConversationBoxName,
    );
    await EncryptedHive.openBox<QuizAttempt>(LocalDbService.quizAttemptBoxName);
    await EncryptedHive.openBox<SavedArticle>(
      LocalDbService.savedArticleBoxName,
    );
    await EncryptedHive.openBox<SafetyPlan>(LocalDbService.safetyPlanBoxName);
    await EncryptedHive.openBox<AppNotification>(
      LocalDbService.appNotificationBoxName,
    );
    await EncryptedHive.openBox<UserProfile>(LocalDbService.userProfileBoxName);
    await EncryptedHive.openBox<SubscriptionStatus>(
      LocalDbService.subscriptionStatusBoxName,
    );
    await LocalDbService().settingsBox();
    await (await LocalDbService().settingsBox()).put(
      ClinicalDisclaimerSheet.acknowledgementKey,
      true,
    );
    await LocalDbService().quizAttemptBox.put(
      'surface-audit-attempt',
      QuizAttempt(
        id: 'surface-audit-attempt',
        quizId: 'phq-9',
        quizSlug: 'phq-9',
        quizTitle: 'Mood assessment',
        answers: const [],
        score: 3,
        interpretation: 'Minimal',
        isCrisisFlagged: false,
        completedAt: DateTime(2026, 10, 14),
      ),
    );
  });
  tearDownAll(() async {
    await Directory('build/surface-review').create(recursive: true);
    await File(
      'build/surface-review/full-app-${const bool.fromEnvironment('SURFACE_NORMAL') ? 'normal' : 'contrast'}-probe-results.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(observations));
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
    resetLocalTestFonts();
  });
  setUp(() => DemoMode.instance.enabled = true);
  tearDown(() => DemoMode.instance.enabled = false);
  assistant.Conversation reviewConversation() {
    final conversation = assistant.Conversation.empty();
    conversation.messages.addAll([
      assistant.ChatMessage(
        id: 'review-user',
        role: assistant.ChatRole.user,
        text: 'I would like a quiet moment today.',
        createdAt: DateTime(2026, 10, 14, 9),
      ),
      assistant.ChatMessage(
        id: 'review-assistant',
        role: assistant.ChatRole.assistant,
        text: 'Take a moment to pause and check in with yourself.',
        createdAt: DateTime(2026, 10, 14, 9, 1),
      ),
    ]);
    return conversation;
  }

  final screens = <String, Widget Function()>{
    'Clinical disclaimer sheet': () =>
        const Scaffold(body: ClinicalDisclaimerSheet()),
    'Quiz support sheet': () => const Scaffold(body: QuizSupportSheet()),
    'Provider share dialog': () =>
        const Scaffold(body: ProviderShareConfirmDialog()),
    'Quiz leave dialog': () => const Scaffold(body: QuizBackConfirmDialog()),
    'Quiz retake dialog': () => const Scaffold(body: QuizRetakeConfirmDialog()),
    'Delete conversation dialog': () =>
        Scaffold(body: DeleteConversationDialog(onDelete: () {})),
    'Visibility sheet': () => Scaffold(
      body: VisibilitySheet(
        currentVisibility: PostVisibility.public,
        onSelect: (_) {},
      ),
    ),
    'Conversation history': () =>
        ConversationHistoryScreen(conversations: [reviewConversation()]),
    'Past conversation': () =>
        PastConversationScreen(conversation: reviewConversation()),
    'Direct messages': () =>
        const DirectMessagesScreen(extra: {'username': 'review_user'}),
    'Community profile': () =>
        const UserProfileScreen(extra: {'username': 'review_user'}),
    'Content category': () => const CategoryDetailScreen(
      extra: {'id': 'anxiety', 'title': 'Anxiety'},
    ),
    'Journal editor': () => const JournalEditorScreen(type: 'free_text'),
    'Journal search': () => JournalSearchScreen(
      entries: PlaceholderData.journals(),
      onOpen: (_) {},
    ),
    'Streak detail': () => const StreakDetailScreen(streak: 3),
    'Mood success': () => const MoodSuccessScreen(
      selectedFeeling: 'calm',
      selectedReasons: ['Work'],
      selectedCoping: ['Rest'],
      journalText: 'A quiet moment',
    ),
    'Quiz detail': () => QuizDetailScreen(
      extra: {
        'id': 'phq-9',
        'definition': assessmentFixture(ClinicalAssessment.phq9),
      },
    ),
    'Quiz taking': () => QuizTakingScreen(
      extra: {
        'id': 'phq-9',
        'type': 'clinical',
        'definition': assessmentFixture(ClinicalAssessment.phq9),
      },
    ),
    'Quiz result': () => QuizResultScreen(
      extra: {
        'attempt': LocalDbService().quizAttemptBox.get('surface-audit-attempt'),
      },
    ),
    'Quiz result detail': () =>
        QuizResultDetailScreen(extra: {'id': 'surface-audit-attempt'}),
    'AssistantScreen': () => AssistantScreen(),
    'ChatSettingsScreen': () => ChatSettingsScreen(),
    'CongratulationsScreen': () => CongratulationsScreen(),
    'CreateAccountScreen': () => CreateAccountScreen(),
    'ForgotPasswordScreen': () => ForgotPasswordScreen(),
    'LoginScreen': () => LoginScreen(),
    'RestoreScreen': () => RestoreScreen(),
    'WelcomeScreen': () => WelcomeScreen(),
    'CommunityGuidelinesScreen': () => CommunityGuidelinesScreen(),
    'CommunitySearchScreen': () => CommunitySearchScreen(),
    'FeaturedPostsScreen': () => FeaturedPostsScreen(),
    'FollowListScreen': () => FollowListScreen(),
    'MessageRequestsScreen': () => MessageRequestsScreen(),
    'ModerationQueueScreen': () => ModerationQueueScreen(),
    'TopicsScreen': () => TopicsScreen(),
    'CreateCommunityGroupScreen': () => CreateCommunityGroupScreen(),
    'ContentSearchScreen': () => ContentSearchScreen(),
    'DailyAffirmationScreen': () => DailyAffirmationScreen(),
    'SavedArticlesScreen': () => SavedArticlesScreen(),
    'CrisisResourcesHubScreen': () => CrisisResourcesHubScreen(),
    'CrisisDetectionOverlayScreen': () => CrisisDetectionOverlayScreen(),
    'EmergencyContactScreen': () => EmergencyContactScreen(),
    'SafetyPlanScreen': () => SafetyPlanScreen(),
    'SafetyPlanViewScreen': () => SafetyPlanViewScreen(),
    'PersistedSafetyPlanViewScreen': () => PersistedSafetyPlanViewScreen(),
    'GroundingExerciseScreen': () => GroundingExerciseScreen(),
    'BreathingExerciseScreen': () => BreathingExerciseScreen(),
    'ProfessionalHelpScreen': () => ProfessionalHelpScreen(),
    'CrisisFollowUpScreen': () => CrisisFollowUpScreen(),
    'InsightsScreen': () => InsightsScreen(),
    'ActivityMoodScreen': () => ActivityMoodScreen(),
    'MoodTrendScreen': () => MoodTrendScreen(),
    'SleepMoodScreen': () => SleepMoodScreen(),
    'TriggersAnalysisScreen': () => TriggersAnalysisScreen(),
    'GuidedPromptsScreen': () => GuidedPromptsScreen(),
    'JournalVoiceRecordingScreen': () => JournalVoiceRecordingScreen(),
    'MoodCheckInSuccessScreen': () => MoodCheckInSuccessScreen(),
    'MoodHistoryScreen': () => MoodHistoryScreen(),
    'MoodDetailViewScreen': () => MoodDetailViewScreen(),
    'OnboardingScreen': () => OnboardingScreen(),
    'PersonalizationScreen': () => PersonalizationScreen(),
    'PreparingCozyScreen': () => PreparingCozyScreen(),
    'QuizSharedScreen': () => QuizSharedScreen(),
    'QuizUsernameScreen': () => QuizUsernameScreen(),
    'QuizInvitationScreen': () => QuizInvitationScreen(),
    'AboutScreen': () => AboutScreen(),
    'ActiveSessionsScreen': () => ActiveSessionsScreen(),
    'CancelSubscriptionScreen': () => CancelSubscriptionScreen(),
    'DigitalWellbeingScreen': () => DigitalWellbeingScreen(),
    'HelpCenterScreen': () => HelpCenterScreen(),
    'HelpSupportScreen': () => HelpSupportScreen(),
    'PrivacySettingsScreen': () => PrivacySettingsScreen(),
    'ProfileViewScreen': () => ProfileViewScreen(),
    'ProviderAccessLogScreen': () => ProviderAccessLogScreen(),
    'ProviderResourcesScreen': () => ProviderResourcesScreen(),
    'ProviderScreen': () => ProviderScreen(),
    'RestorePurchasesScreen': () => RestorePurchasesScreen(),
    'SubscriptionScreen': () => SubscriptionScreen(),
    'SplashScreen': () => SplashScreen(),
    'WellnessScreen': () => WellnessScreen(),
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
            final router = GoRouter(
              routes: [GoRoute(path: '/', builder: (_, _) => entry.value())],
              errorBuilder: (_, _) =>
                  const Scaffold(body: Text('Review destination')),
            );
            addTearDown(router.dispose);
            await tester.pumpWidget(
              MaterialApp.router(
                theme: const bool.fromEnvironment('SURFACE_NORMAL')
                    ? (dark ? AppTheme.dark : AppTheme.light)
                    : AppTheme.highContrast(
                        dark ? AppTheme.dark : AppTheme.light,
                      ),
                builder: (context, child) {
                  ScreenUtil.init(context);
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(2),
                      disableAnimations: true,
                      accessibleNavigation: true,
                      highContrast: !const bool.fromEnvironment(
                        'SURFACE_NORMAL',
                      ),
                    ),
                    child: RepaintBoundary(
                      key: surfaceCaptureKey,
                      child: child!,
                    ),
                  );
                },
                routerConfig: router,
              ),
            );
            await tester.pump(const Duration(seconds: 2));
            final captureName =
                '${entry.key}_${dark ? 'dark' : 'light'}_${landscape ? 'landscape' : 'portrait'}_${const bool.fromEnvironment('SURFACE_NORMAL') ? 'normal' : 'contrast'}';
            await captureSurface(tester, captureName);
            if (const bool.fromEnvironment('SURFACE_SCREENSHOTS')) {
              for (
                var page = 1;
                page <= 4 && find.byType(Scrollable).evaluate().isNotEmpty;
                page++
              ) {
                await tester.drag(
                  find.byType(Scrollable).first,
                  const Offset(0, -400),
                );
                await tester.pump(const Duration(milliseconds: 300));
                await captureSurface(tester, '${captureName}_scroll$page');
              }
            }
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
  if (const bool.fromEnvironment('SURFACE_STRICT')) {
    test('all reviewed surfaces render without exceptions', () {
      for (final observation in observations) {
        expect(
          observation['errors'],
          isEmpty,
          reason:
              '${observation['screen']} dark=${observation['dark']} landscape=${observation['landscape']}',
        );
      }
    });
  }
}
