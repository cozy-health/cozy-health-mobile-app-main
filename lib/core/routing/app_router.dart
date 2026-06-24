import 'package:cozy_health/features/activity/presentation/screens/activity_screens.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/coping_mechanisms_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_detail_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_result_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_selection_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_taking_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/create_account_screen.dart';
import '../../features/auth/presentation/screens/congratulations_screen.dart';
import '../../features/personalization/presentation/screens/personalization_screen.dart';
import '../../features/preparing_cozy/presentation/screens/preparing_cozy_screen.dart';

import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
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

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String createAccount = '/create-account';
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

  static const String home = '/home';

  static const String notifications = '/notifications';
  static const String moodFeeling = '/mood-feeling';
  static const String moodReason = '/mood-reason';
  static const String moodJournal = '/mood-journal';
  static const String moodSuccess = '/mood-success';
  static const String quizSelection = '/quiz-selection';
  static const String quizTaking = '/quiz-taking';
  static const String journal = '/journal';
  static const String voiceRecording = '/voice-recording';
  static const String activity = '/activity';
  static const String assistant = '/assistant';
  static const String quizDetail = '/quiz-detail';
  static const String quizResults = '/quiz-results';
  static const String copingMechanisms = '/coping-mechanisms';

  static Map<String, dynamic> _extraMap(GoRouterState state) {
    final extra = state.extra;
    if (extra is Map<String, dynamic>) return extra;
    return {};
  }

  static String _extraString(
    GoRouterState state, {
    String fallback = '',
    List<String> keys = const [],
  }) {
    final extra = state.extra;

    if (extra is String) return extra;

    if (extra is Map<String, dynamic>) {
      for (final key in keys) {
        final value = extra[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }

    return fallback;
  }

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
  path: quizDetail,
  name: 'quizDetail',
  builder: (_, state) {
    final extra = state.extra as Map<String, dynamic>? ?? {};

    return QuizDetailScreen(
      quizId: int.tryParse(extra['id'].toString()) ?? 0,
      quizTitle: extra['title'] as String? ?? 'Quiz',
      quizType: extra['type'] as String? ?? 'general',
    );
  },
),

GoRoute(
  path: quizTaking,
  name: 'quizTaking',
  builder: (_, state) {
    final extra = state.extra as Map<String, dynamic>? ?? {};

    return QuizTakingScreen(
      quizId: int.tryParse(extra['id'].toString()) ?? 0,
      quizTitle: extra['title'] as String? ?? 'Quiz',
      quizType: extra['type'] as String? ?? 'general',
    );
  },
),

GoRoute(
  path: quizResults,
  name: 'quizResults',
  builder: (_, state) {
    final extra = state.extra as Map<String, dynamic>? ?? {};

    return QuizResultsScreen(
      quizTitle: extra['title'] as String? ?? 'Quiz',
      score: int.tryParse(extra['score'].toString()) ?? 0,
      totalQuestions: int.tryParse(extra['total_questions'].toString()) ?? 0,
    );
  },
),
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
        path: login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
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

      GoRoute(
        path: home,
        name: 'home',
        builder: (_, __) => const MainScreen(),
      ),

      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: moodFeeling,
        name: 'moodFeeling',
        builder: (_, __) => const MoodFeelingScreen(),
      ),
      GoRoute(
        path: quizSelection,
        name: 'quizSelection',
        builder: (_, __) => const QuizSelectionScreen(),
      ),
      
  GoRoute(
  path: moodReason,
  name: 'moodReason',
  builder: (_, state) {
    final extra = state.extra as Map<String, dynamic>? ?? {};

    return MoodReasonScreen(
      selectedFeelingExpId: extra['feeling_exp_id'] as int? ?? 1,
      intensity: extra['intensity'] as int? ?? 5,
    );
  },
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
  path: moodJournal,
  name: 'moodJournal',
  builder: (_, state) {
    final extra = state.extra as Map<String, dynamic>? ?? {};

    return MoodJournalScreen(
      selectedFeelingExpId: extra['feeling_exp_id'] as int? ?? 1,
      intensity: extra['intensity'] as int? ?? 5,
      selectedReasonIds: List<int>.from(extra['reason_ids'] ?? []),
      selectedCopingIds: List<int>.from(extra['coping_mechanism_ids'] ?? []),
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
        path: journal,
        name: 'journal',
        builder: (_, __) => const JournalScreen(),
      ),
      GoRoute(
        path: voiceRecording,
        name: 'voiceRecording',
        builder: (_, __) => const VoiceRecordingScreen(),
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
    ],
  );
}