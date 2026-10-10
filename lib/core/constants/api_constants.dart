class ApiConstants {
  // Release gate: both independently verified leaf fingerprints must be supplied.
  // No single-pin rollout and no remote/unpinned fallback. See CERT_ROTATION.md.
  static const currentLeafPin = String.fromEnvironment(
    'API_CURRENT_LEAF_SHA256',
  );
  static const nextLeafPin = String.fromEnvironment('API_NEXT_LEAF_SHA256');
  static const String baseUrl =
      'https://cozy-health-api-production.up.railway.app/api/v1';

  /*
  |--------------------------------------------------------------------------
  | Auth
  |--------------------------------------------------------------------------
  */
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google';
  static const String appleLogin = '/auth/apple';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  /*
  |--------------------------------------------------------------------------
  | User
  |--------------------------------------------------------------------------
  */
  static const String me = '/user/profile';

  /*
  |--------------------------------------------------------------------------
  | Provider
  |--------------------------------------------------------------------------
  */
  static const String provider = '/provider';
  static const String providerRequest = '/provider/request';
  static const String providerVerify = '/provider/verify';

  /*
  |--------------------------------------------------------------------------
  | Subscription
  |--------------------------------------------------------------------------
  */
  static const String subscription = '/subscription';
  static const String subscriptionPackages = '/subscription/packages';

  static const String subscriptionActivate = '/subscription/activate';

  static const String subscriptionCancel = '/subscription/cancel';

  /*
  |--------------------------------------------------------------------------
  | Mood Check-ins
  |--------------------------------------------------------------------------
  */
  static const String moodEntries = '/mood-entries';

  /*
  |--------------------------------------------------------------------------
  | Journals
  |--------------------------------------------------------------------------
  */
  static const String journals = '/journals';

  static const String journalEntries = '/journal-entries';

  /*
  |--------------------------------------------------------------------------
  | Quizzes
  |--------------------------------------------------------------------------
  */
  static const String quizzes = '/quizzes';

  static const String quizResults = '/quiz-results';

  static const String quizAttempts = '/quiz-attempts';

  /*
  |--------------------------------------------------------------------------
  | Assistant
  |--------------------------------------------------------------------------
  */
  static const String conversations = '/conversations';

  /*
  |--------------------------------------------------------------------------
  | Content
  |--------------------------------------------------------------------------
  */
  static const String savedContent = '/content/saved';

  /*
  |--------------------------------------------------------------------------
  | Crisis
  |--------------------------------------------------------------------------
  */
  static const String safetyPlan = '/safety-plan';

  /*
  |--------------------------------------------------------------------------
  | Notifications
  |--------------------------------------------------------------------------
  */
  static const String notifications = '/notifications';

  static const String notificationUnreadCount = '/notifications/unread-count';
}
