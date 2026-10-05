import '../security_gate.dart';
import 'package:flutter/material.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/features/activity/presentation/screens/activity_screens.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/coping_mechanisms_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_detail_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_result_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_selection_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_taking_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_history_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_result_detail_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/content_home_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/category_detail_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/article_detail_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/saved_articles_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/content_search_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/daily_affirmation_screen.dart';

import 'package:cozy_health/features/community/presentation/screens/community_hub_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/create_post_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/post_detail_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/user_profile_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/follow_list_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/community_guidelines_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/moderation_queue_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/direct_messages_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/message_requests_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/community_search_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/featured_posts_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/topics_screen.dart';

import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/create_account_screen.dart';
import '../../features/auth/presentation/screens/congratulations_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/personalization/presentation/screens/personalization_screen.dart';
import '../../features/preparing_cozy/presentation/screens/preparing_cozy_screen.dart';
import '../../features/crisis/presentation/screens/crisis_screens.dart';

import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/presentation/screens/notification_detail_screen.dart';

import '../../features/insights/presentation/screens/insights_home_screen.dart';
import '../../features/insights/presentation/screens/mood_trend_screen.dart';
import '../../features/insights/presentation/screens/triggers_analysis_screen.dart';
import '../../features/insights/presentation/screens/sleep_mood_screen.dart';
import '../../features/insights/presentation/screens/activity_mood_screen.dart';
import '../../features/insights/presentation/screens/monthly_report_screen.dart';

import '../../features/mood_check_in/presentation/screens/mood_feeling_screen.dart';
import '../../features/mood_check_in/presentation/screens/mood_reason_screen.dart';
import '../../features/mood_check_in/presentation/screens/mood_journal_screen.dart';
import '../../features/mood_check_in/presentation/screens/mood_success_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/journal/presentation/screens/voice_recording_screen.dart';
import '../../features/assistant/presentation/screens/assistant_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/privacy_settings_screen.dart';
import '../../features/settings/presentation/screens/help_support_screen.dart';
import '../../features/settings/presentation/screens/terms_policies_screen.dart';
import '../../features/settings/presentation/screens/report_problem_screen.dart';

import '../../features/settings/presentation/screens/provider_screen.dart';
import '../../features/settings/presentation/screens/subscription_screen.dart';
import '../../features/settings/presentation/screens/profile_view_screen.dart';
import '../../features/settings/presentation/screens/notification_preferences_screen.dart';
import '../../features/settings/presentation/screens/data_export_screen.dart';
import '../../features/settings/presentation/screens/account_deletion_screen.dart';
import '../../features/settings/presentation/screens/change_password_screen.dart';
import '../../features/settings/presentation/screens/active_sessions_screen.dart';
import '../../features/settings/presentation/screens/appearance_settings_screen.dart';
import '../../features/settings/presentation/screens/language_settings_screen.dart';
import '../../features/settings/presentation/screens/accessibility_settings_screen.dart';
import '../../features/settings/presentation/screens/email_settings_screen.dart';
import '../../features/settings/presentation/screens/phone_settings_screen.dart';
import '../../features/settings/presentation/screens/two_factor_auth_screen.dart';
import '../../features/settings/presentation/screens/connected_apps_screen.dart';
import '../../features/settings/presentation/screens/billing_history_screen.dart';
import '../../features/settings/presentation/screens/cancel_subscription_screen.dart';
import '../../features/settings/presentation/screens/restore_purchases_screen.dart';
import '../../features/settings/presentation/screens/referral_screen.dart';
import '../../features/settings/presentation/screens/feedback_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/legal_hub_screen.dart';
import '../../features/settings/presentation/screens/reminder_times_screen.dart';
import '../../features/settings/presentation/screens/blocked_users_screen.dart';
import '../../features/settings/presentation/screens/data_export_status_screen.dart';
import '../../features/settings/presentation/screens/download_my_data_screen.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String forgotPassword = '/forgot-password';
  static const String congratulations = '/congratulations';
  static const String personalization = '/personalization';
  static const String preparingCozy = '/preparing-cozy';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String privacySettings = '/privacy-settings';
  static const String helpSupport = '/help-support';
  static const String termsPolicies = '/terms-policies';
  static const String reportProblem = '/report-problem';
  static const String provider = '/provider';
  static const String subscription = '/subscription';
  static const String profileView = '/profile-view';
  static const String notificationPreferences = '/notification-preferences';
  static const String dataExport = '/data-export';
  static const String accountDeletion = '/account-deletion';
  static const String changePassword = '/change-password';
  static const String activeSessions = '/active-sessions';
  static const String appearanceSettings = '/appearance-settings';
  static const String languageSettings = '/language-settings';
  static const String accessibilitySettings = '/accessibility-settings';
  static const String emailSettings = '/email-settings';
  static const String phoneSettings = '/phone-settings';
  static const String twoFactorAuth = '/two-factor-auth';
  static const String connectedApps = '/connected-apps';
  static const String billingHistory = '/billing-history';
  static const String cancelSubscription = '/cancel-subscription';
  static const String restorePurchases = '/restore-purchases';
  static const String referral = '/referral';
  static const String feedback = '/feedback';
  static const String about = '/about';
  static const String legalHub = '/legal-hub';
  static const String legalTerms = '/legal/terms';
  static const String legalPrivacy = '/legal/privacy';
  static const String reminderTimes = '/reminder-times';
  static const String blockedUsers = '/blocked-users';
  static const String dataExportStatus = '/data-export-status';
  static const String downloadMyData = '/download-my-data';

  static const String home = '/home';

  static const String notifications = '/notifications';
  static const String notificationDetail = '/notification-detail';

  static const String insights = '/insights';
  static const String insightsMoodTrend = '/insights/mood-trend';
  static const String insightsTriggers = '/insights/triggers';
  static const String insightsSleepMood = '/insights/sleep-mood';
  static const String insightsActivityMood = '/insights/activity-mood';
  static const String insightsMonthlyReport = '/insights/monthly-report';

  static const String moodFeeling = '/mood-feeling';
  static const String moodReason = '/mood-reason';
  static const String moodJournal = '/mood-journal';
  static const String moodSuccess = '/mood-success';
  static const String moodHistory = '/mood-history';
  static const String moodDetail = '/mood-detail';
  static const String quizSelection = '/quiz-selection';
  static const String quizTaking = '/quiz-taking';
  static const String journal = '/journal';
  static const String voiceRecording = '/voice-recording';
  static const String activity = '/activity';
  static const String assistant = '/assistant';
  static const String quizDetail = '/quiz-detail';
  static const String quizResults = '/quiz-results';
  static const String quizHistory = '/quiz-history';
  static const String quizResultDetail = '/quiz-result-detail';

  static const String contentHome = '/content';
  static const String categoryDetail = '/category-detail';
  static const String articleDetail = '/article-detail';
  static const String savedArticles = '/saved-articles';
  static const String contentSearch = '/content-search';
  static const String dailyAffirmation = '/daily-affirmation';

  static const String communityHub = '/community';
  static const String createPost = '/community/create-post';
  static const String postDetail = '/community/post-detail';
  static const String userProfile = '/community/user-profile';
  static const String followList = '/community/follow-list';
  static const String communityGuidelines = '/community/guidelines';
  static const String moderationQueue = '/community/moderation';
  static const String directMessages = '/community/dm';
  static const String messageRequests = '/community/dm-requests';
  static const String communitySearch = '/community/search';
  static const String featuredPosts = '/community/featured';
  static const String topics = '/community/topics';

  static const String copingMechanisms = '/coping-mechanisms';
  static const String crisisHub = '/crisis';
  static const String crisisOverlay = '/crisis-overlay';
  static const String crisisContact = '/crisis-contact';
  static const String safetyPlan = '/safety-plan';
  static const String safetyPlanView = '/safety-plan-view';
  static const String grounding = '/grounding';
  static const String breathing = '/breathing';
  static const String professionalHelp = '/professional-help';
  static const String crisisFollowUp = '/crisis-follow-up';

  static Map<String, dynamic> _extraMap(GoRouterState state) {
    final extra = state.extra;
    if (extra is Map<String, dynamic>) return extra;
    return {};
  }

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: welcome,
        name: 'welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgotPassword',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: createAccount,
        name: 'createAccount',
        builder: (_, __) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: congratulations,
        name: 'congratulations',
        builder: (_, __) => const CongratulationsScreen(),
      ),
      GoRoute(
        path: personalization,
        name: 'personalization',
        builder: (_, __) => const PersonalizationScreen(),
      ),
      GoRoute(
        path: preparingCozy,
        name: 'preparingCozy',
        builder: (_, __) => const PreparingCozyScreen(),
      ),

      GoRoute(path: home, name: 'home', builder: (_, __) => const MainScreen()),

      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: notificationDetail,
        name: 'notificationDetail',
        builder: (_, __) => const NotificationDetailScreen(),
      ),
      GoRoute(
        path: insights,
        name: 'insights',
        builder: (_, __) => const InsightsHomeScreen(),
      ),
      GoRoute(
        path: insightsMoodTrend,
        name: 'insightsMoodTrend',
        builder: (_, __) => const MoodTrendScreen(),
      ),
      GoRoute(
        path: insightsTriggers,
        name: 'insightsTriggers',
        builder: (_, __) => const TriggersAnalysisScreen(),
      ),
      GoRoute(
        path: insightsSleepMood,
        name: 'insightsSleepMood',
        builder: (_, __) => const SleepMoodScreen(),
      ),
      GoRoute(
        path: insightsActivityMood,
        name: 'insightsActivityMood',
        builder: (_, __) => const ActivityMoodScreen(),
      ),
      GoRoute(
        path: insightsMonthlyReport,
        name: 'insightsMonthlyReport',
        builder: (_, __) => const MonthlyReportScreen(),
      ),
      GoRoute(
        path: moodFeeling,
        name: 'moodFeeling',
        builder: (_, state) => MoodFeelingScreen(
          entry: state.extra is MoodEntry ? state.extra as MoodEntry : null,
        ),
      ),
      GoRoute(
        path: moodReason,
        name: 'moodReason',
        builder: (_, state) {
          final map = state.extra is Map ? (state.extra as Map) : null;
          return MoodReasonScreen(
            selectedFeelingExpId: (map?['selectedFeelingExpId'] as int?) ?? 1,
            intensity: (map?['intensity'] as int?) ?? 3,
          );
        },
      ),
      GoRoute(
        path: moodJournal,
        name: 'moodJournal',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};

          return MoodJournalScreen(
            selectedFeelingExpId: extra['feeling_exp_id'] as int? ?? 1,
            intensity: extra['intensity'] as int? ?? 5,
            selectedReasonIds: List<int>.from(extra['reason_ids'] ?? []),
            selectedCopingIds: List<int>.from(
              extra['coping_mechanism_ids'] ?? [],
            ),
          );
        },
      ),
      GoRoute(
        path: moodSuccess,
        name: 'moodSuccess',
        builder: (_, __) => const MoodSuccessScreen(
          selectedFeeling: '',
          selectedReasons: [],
          selectedCoping: [],
          journalText: '',
        ),
      ),
      GoRoute(
        path: moodHistory,
        name: 'moodHistory',
        builder: (_, __) => const MoodHistoryScreen(),
      ),
      GoRoute(
        path: moodDetail,
        name: 'moodDetail',
        builder: (_, state) => MoodDetailViewScreen(
          entry: state.extra is MoodEntry ? state.extra as MoodEntry : null,
        ),
      ),

      GoRoute(
        path: quizSelection,
        name: 'quizSelection',
        builder: (_, __) => const QuizSelectionScreen(),
      ),
      GoRoute(
        path: quizResults,
        name: 'quizResults',
        builder: (_, state) => QuizResultScreen(extra: _extraMap(state)),
      ),
      GoRoute(
        path: quizHistory,
        name: 'quizHistory',
        builder: (_, __) => const QuizHistoryScreen(),
      ),
      GoRoute(
        path: quizResultDetail,
        name: 'quizResultDetail',
        builder: (_, state) => QuizResultDetailScreen(extra: _extraMap(state)),
      ),
      GoRoute(
        path: copingMechanisms,
        name: 'copingMechanisms',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};

          return CopingMechanismsScreen(
            selectedFeelingExpId: extra['feeling_exp_id'] as int? ?? 1,
            intensity: extra['intensity'] as int? ?? 5,
            selectedReasonIds: List<int>.from(extra['reason_ids'] ?? []),
          );
        },
      ),
      GoRoute(
        path: crisisHub,
        name: 'crisisHub',
        builder: (_, __) => const CrisisResourcesHubScreen(),
      ),
      GoRoute(
        path: crisisOverlay,
        name: 'crisisOverlay',
        builder: (_, __) => const CrisisDetectionOverlayScreen(),
      ),
      GoRoute(
        path: crisisContact,
        name: 'crisisContact',
        builder: (_, __) => const EmergencyContactScreen(),
      ),
      GoRoute(
        path: safetyPlan,
        name: 'safetyPlan',
        builder: (_, __) => const SafetyPlanScreen(),
      ),
      GoRoute(
        path: safetyPlanView,
        name: 'safetyPlanView',
        builder: (_, __) => const PersistedSafetyPlanViewScreen(),
      ),
      GoRoute(
        path: grounding,
        name: 'grounding',
        builder: (_, __) => const GroundingExerciseScreen(),
      ),
      GoRoute(
        path: breathing,
        name: 'breathing',
        builder: (_, __) => const BreathingExerciseScreen(),
      ),
      GoRoute(
        path: professionalHelp,
        name: 'professionalHelp',
        builder: (_, __) => const ProfessionalHelpScreen(),
      ),
      GoRoute(
        path: crisisFollowUp,
        name: 'crisisFollowUp',
        builder: (_, __) => const CrisisFollowUpScreen(),
      ),
      GoRoute(
        path: quizDetail,
        name: 'quizDetail',
        builder: (_, state) {
          return QuizDetailScreen(extra: _extraMap(state));
        },
      ),
      GoRoute(
        path: quizTaking,
        name: 'quizTaking',
        builder: (_, state) => QuizTakingScreen(extra: _extraMap(state)),
      ),
      GoRoute(
        path: contentHome,
        name: 'contentHome',
        builder: (_, __) => const ContentHomeScreen(),
      ),
      GoRoute(
        path: categoryDetail,
        name: 'categoryDetail',
        builder: (_, state) => CategoryDetailScreen(extra: _extraMap(state)),
      ),
      GoRoute(
        path: articleDetail,
        name: 'articleDetail',
        builder: (_, state) => ArticleDetailScreen(extra: _extraMap(state)),
      ),
      GoRoute(
        path: savedArticles,
        name: 'savedArticles',
        builder: (_, __) => const SavedArticlesScreen(),
      ),
      GoRoute(
        path: contentSearch,
        name: 'contentSearch',
        builder: (_, __) => const ContentSearchScreen(),
      ),
      GoRoute(
        path: dailyAffirmation,
        name: 'dailyAffirmation',
        builder: (_, __) => const DailyAffirmationScreen(),
      ),
      GoRoute(
        path: communityHub,
        name: 'communityHub',
        builder: (_, __) => const CommunityHubScreen(),
      ),
      GoRoute(
        path: createPost,
        name: 'createPost',
        builder: (_, __) => const CreatePostScreen(),
      ),
      GoRoute(
        path: postDetail,
        name: 'postDetail',
        builder: (_, state) => PostDetailScreen(
          post: _extraMap(state)['post'] as Map<String, dynamic>? ?? {},
        ),
      ),
      GoRoute(
        path: userProfile,
        name: 'userProfile',
        builder: (_, state) => UserProfileScreen(extra: _extraMap(state)),
      ),
      GoRoute(
        path: followList,
        name: 'followList',
        builder: (_, __) => const FollowListScreen(),
      ),
      GoRoute(
        path: communityGuidelines,
        name: 'communityGuidelines',
        builder: (_, __) => const CommunityGuidelinesScreen(),
      ),
      GoRoute(
        path: moderationQueue,
        name: 'moderationQueue',
        builder: (_, __) => const ModerationQueueScreen(),
      ),
      GoRoute(
        path: directMessages,
        name: 'directMessages',
        builder: (_, state) => DirectMessagesScreen(extra: _extraMap(state)),
      ),
      GoRoute(
        path: messageRequests,
        name: 'messageRequests',
        builder: (_, __) => const MessageRequestsScreen(),
      ),
      GoRoute(
        path: communitySearch,
        name: 'communitySearch',
        builder: (_, __) => const CommunitySearchScreen(),
      ),
      GoRoute(
        path: featuredPosts,
        name: 'featuredPosts',
        builder: (_, __) => const FeaturedPostsScreen(),
      ),
      GoRoute(
        path: topics,
        name: 'topics',
        builder: (_, __) => const TopicsScreen(),
      ),

      GoRoute(
        path: journal,
        name: 'journal',
        builder: (_, __) => const SecurityGate(
          journal: true,
          journalRoot: true,
          child: JournalScreen(),
        ),
      ),
      GoRoute(
        path: voiceRecording,
        name: 'voiceRecording',
        builder: (_, __) => const SecurityGate(
          journal: true,
          journalRoot: true,
          child: VoiceRecordingScreen(),
        ),
      ),
      GoRoute(
        path: activity,
        name: 'activity',
        builder: (_, __) => const ActivityScreen(),
      ),
      GoRoute(
        path: assistant,
        name: 'assistant',
        builder: (_, __) => const AssistantScreen(),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: editProfile,
        name: 'editProfile',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: privacySettings,
        name: 'privacySettings',
        builder: (_, __) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: helpSupport,
        name: 'helpSupport',
        builder: (_, __) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: termsPolicies,
        name: 'termsPolicies',
        builder: (_, __) => const TermsPoliciesScreen(),
      ),
      GoRoute(
        path: legalTerms,
        name: 'legalTerms',
        builder: (_, __) => const TermsPoliciesScreen(title: 'Terms'),
      ),
      GoRoute(
        path: legalPrivacy,
        name: 'legalPrivacy',
        builder: (_, __) => const TermsPoliciesScreen(title: 'Privacy Policy'),
      ),
      GoRoute(
        path: reportProblem,
        name: 'reportProblem',
        builder: (_, __) => const ReportProblemScreen(),
      ),
      GoRoute(
        path: provider,
        name: 'provider',
        builder: (_, __) => const ProviderScreen(),
      ),
      GoRoute(
        path: subscription,
        name: 'subscription',
        builder: (_, __) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: profileView,
        name: 'profileView',
        builder: (_, __) => const ProfileViewScreen(),
      ),
      GoRoute(
        path: notificationPreferences,
        name: 'notificationPreferences',
        builder: (_, __) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: dataExport,
        name: 'dataExport',
        builder: (_, __) => const DataExportScreen(),
      ),
      GoRoute(
        path: accountDeletion,
        name: 'accountDeletion',
        builder: (_, __) => const AccountDeletionScreen(),
      ),
      GoRoute(
        path: changePassword,
        name: 'changePassword',
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: activeSessions,
        name: 'activeSessions',
        builder: (_, __) => const ActiveSessionsScreen(),
      ),
      GoRoute(
        path: appearanceSettings,
        name: 'appearanceSettings',
        builder: (_, __) => const AppearanceSettingsScreen(),
      ),
      GoRoute(
        path: languageSettings,
        name: 'languageSettings',
        builder: (_, __) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: accessibilitySettings,
        name: 'accessibilitySettings',
        builder: (_, __) => const AccessibilitySettingsScreen(),
      ),
      GoRoute(
        path: emailSettings,
        name: 'emailSettings',
        builder: (_, __) => const EmailSettingsScreen(),
      ),
      GoRoute(
        path: phoneSettings,
        name: 'phoneSettings',
        builder: (_, __) => const PhoneSettingsScreen(),
      ),
      GoRoute(
        path: twoFactorAuth,
        name: 'twoFactorAuth',
        builder: (_, __) => const TwoFactorAuthScreen(),
      ),
      GoRoute(
        path: connectedApps,
        name: 'connectedApps',
        builder: (_, __) => const ConnectedAppsScreen(),
      ),
      GoRoute(
        path: billingHistory,
        name: 'billingHistory',
        builder: (_, __) => const BillingHistoryScreen(),
      ),
      GoRoute(
        path: cancelSubscription,
        name: 'cancelSubscription',
        builder: (_, __) => const CancelSubscriptionScreen(),
      ),
      GoRoute(
        path: restorePurchases,
        name: 'restorePurchases',
        builder: (_, __) => const RestorePurchasesScreen(),
      ),
      GoRoute(
        path: referral,
        name: 'referral',
        builder: (_, __) => const ReferralScreen(),
      ),
      GoRoute(
        path: feedback,
        name: 'feedback',
        builder: (_, __) => const FeedbackScreen(),
      ),
      GoRoute(
        path: about,
        name: 'about',
        builder: (_, __) => const AboutScreen(),
      ),
      GoRoute(
        path: legalHub,
        name: 'legalHub',
        builder: (_, __) => const LegalHubScreen(),
      ),
      GoRoute(
        path: reminderTimes,
        name: 'reminderTimes',
        builder: (_, __) => const ReminderTimesScreen(),
      ),
      GoRoute(
        path: blockedUsers,
        name: 'blockedUsers',
        builder: (_, __) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: dataExportStatus,
        name: 'dataExportStatus',
        builder: (_, __) => const DataExportStatusScreen(),
      ),
      GoRoute(
        path: downloadMyData,
        name: 'downloadMyData',
        builder: (_, __) => const DownloadMyDataScreen(),
      ),
    ],
  );
}
