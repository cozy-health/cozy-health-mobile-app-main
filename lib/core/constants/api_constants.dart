class ApiConstants {
  static const String baseUrl =
      'http://10.0.2.2:8000/api/v1';

  /*
  |--------------------------------------------------------------------------
  | Auth
  |--------------------------------------------------------------------------
  */
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';

  /*
  |--------------------------------------------------------------------------
  | User
  |--------------------------------------------------------------------------
  */
  static const String me = '/me';

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
  static const String subscriptionPackages =
      '/subscription/packages';

  static const String subscriptionActivate =
      '/subscription/activate';

  static const String subscriptionCancel =
      '/subscription/cancel';

  /*
  |--------------------------------------------------------------------------
  | Mood Check-ins
  |--------------------------------------------------------------------------
  */
  static const String moodCheckins =
      '/mood-checkins';

  static const String moodCheckinToday =
      '/mood-checkins/today';

  /*
  |--------------------------------------------------------------------------
  | Mood Lookup Data
  |--------------------------------------------------------------------------
  */
  static const String feelings =
      '/feelings';

  static const String feelingExpressions =
      '/feeling-expressions';

  static const String feelingCauses =
      '/feeling-causes';

  static const String copingMechanisms =
      '/coping-mechanisms';

  /*
  |--------------------------------------------------------------------------
  | Journals
  |--------------------------------------------------------------------------
  */
  static const String journals =
      '/journals';

  /*
  |--------------------------------------------------------------------------
  | Quizzes
  |--------------------------------------------------------------------------
  */
  static const String quizzes =
      '/quizzes';

  static const String quizResults =
      '/quiz-results';

  /*
  |--------------------------------------------------------------------------
  | Activity
  |--------------------------------------------------------------------------
  */
  static const String activityOverview =
      '/activity/overview';

  static const String activityMoodChart =
      '/activity/mood-chart';

  static const String activityCommonTriggers =
      '/activity/common-triggers';

  static const String activityJournalStats =
      '/activity/journal-stats';

  static const String activityRecommendations =
      '/activity/recommendations';

  /*
  |--------------------------------------------------------------------------
  | Notifications
  |--------------------------------------------------------------------------
  */
  static const String notifications =
      '/notifications';

  static const String notificationUnreadCount =
      '/notifications/unread-count';
}