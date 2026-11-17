# Full mobile app source inventory

Generated 2026-10-10. Source inventory and review cues, not proof of visual or interaction correctness. Every screen file and additional screen/view class is listed. Counts are search matches, not defect counts. See full-app-audit.md for verified findings and coverage limits.

| File | Screen/view classes | Explicit palette references | Motion expressions | Overlay calls | Empty handlers |
| --- | --- | ---: | ---: | ---: | ---: |
| [lib/features/activity/presentation/screens/activity_screens.dart](../../lib/features/activity/presentation/screens/activity_screens.dart) | ActivityScreen | 14 | 1 | 0 | 0 |
| [lib/features/assistant/presentation/screens/assistant_screen.dart](../../lib/features/assistant/presentation/screens/assistant_screen.dart) | AssistantScreen | 0 | 6 | 2 | 0 |
| [lib/features/assistant/presentation/widgets/chat_settings_view.dart](../../lib/features/assistant/presentation/widgets/chat_settings_view.dart) | ChatSettingsScreen | 1 | 0 | 1 | 3 |
| [lib/features/assistant/presentation/widgets/conversation_list_view.dart](../../lib/features/assistant/presentation/widgets/conversation_list_view.dart) | ConversationHistoryScreen, PastConversationScreen | 3 | 0 | 1 | 0 |
| [lib/features/auth/presentation/screens/congratulations_screen.dart](../../lib/features/auth/presentation/screens/congratulations_screen.dart) | CongratulationsScreen | 3 | 0 | 0 | 0 |
| [lib/features/auth/presentation/screens/create_account_screen.dart](../../lib/features/auth/presentation/screens/create_account_screen.dart) | CreateAccountScreen | 0 | 0 | 0 | 0 |
| [lib/features/auth/presentation/screens/forgot_password_screen.dart](../../lib/features/auth/presentation/screens/forgot_password_screen.dart) | ForgotPasswordScreen | 10 | 0 | 0 | 0 |
| [lib/features/auth/presentation/screens/login_screen.dart](../../lib/features/auth/presentation/screens/login_screen.dart) | LoginScreen | 0 | 0 | 0 | 0 |
| [lib/features/auth/presentation/screens/restore_screen.dart](../../lib/features/auth/presentation/screens/restore_screen.dart) | RestoreScreen | 0 | 0 | 0 | 0 |
| [lib/features/auth/presentation/screens/welcome_screen.dart](../../lib/features/auth/presentation/screens/welcome_screen.dart) | WelcomeScreen | 0 | 0 | 0 | 0 |
| [lib/features/community/presentation/screens/comments_screen.dart](../../lib/features/community/presentation/screens/comments_screen.dart) | CommentsScreen | 0 | 0 | 0 | 0 |
| [lib/features/community/presentation/screens/community_guidelines_screen.dart](../../lib/features/community/presentation/screens/community_guidelines_screen.dart) | CommunityGuidelinesScreen | 2 | 0 | 0 | 0 |
| [lib/features/community/presentation/screens/community_hub_screen.dart](../../lib/features/community/presentation/screens/community_hub_screen.dart) | CommunityHubScreen | 0 | 1 | 1 | 0 |
| [lib/features/community/presentation/screens/community_search_screen.dart](../../lib/features/community/presentation/screens/community_search_screen.dart) | CommunitySearchScreen | 0 | 0 | 0 | 0 |
| [lib/features/community/presentation/screens/create_post_screen.dart](../../lib/features/community/presentation/screens/create_post_screen.dart) | CreatePostScreen | 9 | 0 | 0 | 0 |
| [lib/features/community/presentation/screens/direct_messages_screen.dart](../../lib/features/community/presentation/screens/direct_messages_screen.dart) | DirectMessagesScreen | 3 | 0 | 1 | 0 |
| [lib/features/community/presentation/screens/featured_posts_screen.dart](../../lib/features/community/presentation/screens/featured_posts_screen.dart) | FeaturedPostsScreen | 0 | 0 | 0 | 0 |
| [lib/features/community/presentation/screens/follow_list_screen.dart](../../lib/features/community/presentation/screens/follow_list_screen.dart) | FollowListScreen | 0 | 0 | 0 | 0 |
| [lib/features/community/presentation/screens/message_requests_screen.dart](../../lib/features/community/presentation/screens/message_requests_screen.dart) | MessageRequestsScreen | 1 | 0 | 0 | 0 |
| [lib/features/community/presentation/screens/moderation_queue_screen.dart](../../lib/features/community/presentation/screens/moderation_queue_screen.dart) | ModerationQueueScreen | 4 | 0 | 0 | 5 |
| [lib/features/community/presentation/screens/post_detail_screen.dart](../../lib/features/community/presentation/screens/post_detail_screen.dart) | PostDetailScreen | 0 | 0 | 0 | 0 |
| [lib/features/community/presentation/screens/topics_screen.dart](../../lib/features/community/presentation/screens/topics_screen.dart) | TopicsScreen | 0 | 0 | 0 | 0 |
| [lib/features/community/presentation/screens/user_profile_screen.dart](../../lib/features/community/presentation/screens/user_profile_screen.dart) | UserProfileScreen | 2 | 0 | 1 | 0 |
| [lib/features/community/presentation/widgets/community_groups.dart](../../lib/features/community/presentation/widgets/community_groups.dart) | CreateCommunityGroupScreen | 2 | 0 | 0 | 0 |
| [lib/features/content/presentation/screens/article_detail_screen.dart](../../lib/features/content/presentation/screens/article_detail_screen.dart) | ArticleDetailScreen | 0 | 0 | 0 | 0 |
| [lib/features/content/presentation/screens/category_detail_screen.dart](../../lib/features/content/presentation/screens/category_detail_screen.dart) | CategoryDetailScreen | 0 | 0 | 0 | 0 |
| [lib/features/content/presentation/screens/content_home_screen.dart](../../lib/features/content/presentation/screens/content_home_screen.dart) | ContentHomeScreen | 0 | 1 | 0 | 0 |
| [lib/features/content/presentation/screens/content_search_screen.dart](../../lib/features/content/presentation/screens/content_search_screen.dart) | ContentSearchScreen | 0 | 0 | 0 | 0 |
| [lib/features/content/presentation/screens/daily_affirmation_screen.dart](../../lib/features/content/presentation/screens/daily_affirmation_screen.dart) | DailyAffirmationScreen | 0 | 0 | 0 | 0 |
| [lib/features/content/presentation/screens/saved_articles_screen.dart](../../lib/features/content/presentation/screens/saved_articles_screen.dart) | SavedArticlesScreen | 0 | 0 | 0 | 0 |
| [lib/features/crisis/presentation/screens/crisis_screens.dart](../../lib/features/crisis/presentation/screens/crisis_screens.dart) | CrisisResourcesHubScreen, CrisisDetectionOverlayScreen, EmergencyContactScreen, SafetyPlanScreen, SafetyPlanViewScreen, PersistedSafetyPlanViewScreen, GroundingExerciseScreen, BreathingExerciseScreen, ProfessionalHelpScreen, CrisisFollowUpScreen | 36 | 1 | 6 | 2 |
| [lib/features/home/presentation/screens/home_screen.dart](../../lib/features/home/presentation/screens/home_screen.dart) | HomeScreen, StreakDetailScreen, InsightsScreen | 25 | 6 | 0 | 0 |
| [lib/features/home/presentation/screens/main_screen.dart](../../lib/features/home/presentation/screens/main_screen.dart) | MainScreen | 4 | 0 | 1 | 0 |
| [lib/features/insights/presentation/screens/activity_mood_screen.dart](../../lib/features/insights/presentation/screens/activity_mood_screen.dart) | ActivityMoodScreen | 12 | 2 | 0 | 0 |
| [lib/features/insights/presentation/screens/insights_home_screen.dart](../../lib/features/insights/presentation/screens/insights_home_screen.dart) | InsightsHomeScreen | 4 | 1 | 0 | 0 |
| [lib/features/insights/presentation/screens/monthly_report_screen.dart](../../lib/features/insights/presentation/screens/monthly_report_screen.dart) | MonthlyReportScreen | 3 | 0 | 0 | 4 |
| [lib/features/insights/presentation/screens/mood_trend_screen.dart](../../lib/features/insights/presentation/screens/mood_trend_screen.dart) | MoodTrendScreen | 17 | 2 | 0 | 0 |
| [lib/features/insights/presentation/screens/sleep_mood_screen.dart](../../lib/features/insights/presentation/screens/sleep_mood_screen.dart) | SleepMoodScreen | 14 | 2 | 0 | 0 |
| [lib/features/insights/presentation/screens/triggers_analysis_screen.dart](../../lib/features/insights/presentation/screens/triggers_analysis_screen.dart) | TriggersAnalysisScreen | 6 | 1 | 0 | 0 |
| [lib/features/insights/presentation/widgets/data_table_view.dart](../../lib/features/insights/presentation/widgets/data_table_view.dart) | DataTableView | 0 | 0 | 0 | 0 |
| [lib/features/journal/presentation/screens/journal_screen.dart](../../lib/features/journal/presentation/screens/journal_screen.dart) | JournalScreen, JournalEditorScreen, GuidedPromptsScreen, JournalVoiceRecordingScreen, JournalSearchScreen, JournalEntryDetailScreen | 33 | 6 | 10 | 0 |
| [lib/features/journal/presentation/screens/voice_recording_screen.dart](../../lib/features/journal/presentation/screens/voice_recording_screen.dart) | VoiceRecordingScreen | 8 | 0 | 0 | 0 |
| [lib/features/mood_check_in/presentation/screens/mood_feeling_screen.dart](../../lib/features/mood_check_in/presentation/screens/mood_feeling_screen.dart) | MoodFeelingScreen, MoodCheckInSuccessScreen, MoodHistoryScreen, MoodDetailViewScreen | 22 | 6 | 1 | 0 |
| [lib/features/mood_check_in/presentation/screens/mood_success_screen.dart](../../lib/features/mood_check_in/presentation/screens/mood_success_screen.dart) | MoodSuccessScreen | 1 | 0 | 0 | 0 |
| [lib/features/notifications/presentation/screens/notification_detail_screen.dart](../../lib/features/notifications/presentation/screens/notification_detail_screen.dart) | NotificationDetailScreen | 0 | 0 | 0 | 0 |
| [lib/features/notifications/presentation/screens/notifications_screen.dart](../../lib/features/notifications/presentation/screens/notifications_screen.dart) | NotificationsScreen | 10 | 0 | 1 | 0 |
| [lib/features/onboarding/presentation/screens/onboarding_screen.dart](../../lib/features/onboarding/presentation/screens/onboarding_screen.dart) | OnboardingScreen | 0 | 2 | 0 | 0 |
| [lib/features/personalization/presentation/screens/personalization_screen.dart](../../lib/features/personalization/presentation/screens/personalization_screen.dart) | PersonalizationScreen | 4 | 0 | 0 | 0 |
| [lib/features/preparing_cozy/presentation/screens/preparing_cozy_screen.dart](../../lib/features/preparing_cozy/presentation/screens/preparing_cozy_screen.dart) | PreparingCozyScreen | 1 | 0 | 0 | 0 |
| [lib/features/quiz/presentation/screen/quiz_detail_screen.dart](../../lib/features/quiz/presentation/screen/quiz_detail_screen.dart) | QuizDetailScreen | 2 | 0 | 0 | 0 |
| [lib/features/quiz/presentation/screen/quiz_history_screen.dart](../../lib/features/quiz/presentation/screen/quiz_history_screen.dart) | QuizHistoryScreen | 0 | 0 | 0 | 0 |
| [lib/features/quiz/presentation/screen/quiz_result_detail_screen.dart](../../lib/features/quiz/presentation/screen/quiz_result_detail_screen.dart) | QuizResultDetailScreen | 0 | 0 | 0 | 0 |
| [lib/features/quiz/presentation/screen/quiz_result_screen.dart](../../lib/features/quiz/presentation/screen/quiz_result_screen.dart) | QuizResultScreen | 0 | 0 | 0 | 0 |
| [lib/features/quiz/presentation/screen/quiz_selection_screen.dart](../../lib/features/quiz/presentation/screen/quiz_selection_screen.dart) | QuizSelectionScreen | 2 | 0 | 0 | 0 |
| [lib/features/quiz/presentation/screen/quiz_taking_screen.dart](../../lib/features/quiz/presentation/screen/quiz_taking_screen.dart) | QuizTakingScreen | 0 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/about_screen.dart](../../lib/features/settings/presentation/screens/about_screen.dart) | AboutScreen | 11 | 0 | 1 | 0 |
| [lib/features/settings/presentation/screens/accessibility_settings_screen.dart](../../lib/features/settings/presentation/screens/accessibility_settings_screen.dart) | AccessibilitySettingsScreen | 4 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/account_deletion_screen.dart](../../lib/features/settings/presentation/screens/account_deletion_screen.dart) | AccountDeletionScreen | 6 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/active_sessions_screen.dart](../../lib/features/settings/presentation/screens/active_sessions_screen.dart) | ActiveSessionsScreen | 1 | 0 | 1 | 0 |
| [lib/features/settings/presentation/screens/appearance_settings_screen.dart](../../lib/features/settings/presentation/screens/appearance_settings_screen.dart) | AppearanceSettingsScreen | 11 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/billing_history_screen.dart](../../lib/features/settings/presentation/screens/billing_history_screen.dart) | BillingHistoryScreen | 10 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/blocked_users_screen.dart](../../lib/features/settings/presentation/screens/blocked_users_screen.dart) | BlockedUsersScreen | 5 | 0 | 1 | 0 |
| [lib/features/settings/presentation/screens/cancel_subscription_screen.dart](../../lib/features/settings/presentation/screens/cancel_subscription_screen.dart) | CancelSubscriptionScreen | 9 | 0 | 1 | 0 |
| [lib/features/settings/presentation/screens/change_password_screen.dart](../../lib/features/settings/presentation/screens/change_password_screen.dart) | ChangePasswordScreen | 5 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/connected_apps_screen.dart](../../lib/features/settings/presentation/screens/connected_apps_screen.dart) | ConnectedAppsScreen | 11 | 0 | 1 | 0 |
| [lib/features/settings/presentation/screens/data_export_screen.dart](../../lib/features/settings/presentation/screens/data_export_screen.dart) | DataExportScreen | 0 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/data_export_status_screen.dart](../../lib/features/settings/presentation/screens/data_export_status_screen.dart) | DataExportStatusScreen | 17 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/digital_wellbeing_screen.dart](../../lib/features/settings/presentation/screens/digital_wellbeing_screen.dart) | DigitalWellbeingScreen | 0 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/download_my_data_screen.dart](../../lib/features/settings/presentation/screens/download_my_data_screen.dart) | DownloadMyDataScreen | 8 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/edit_profile_screen.dart](../../lib/features/settings/presentation/screens/edit_profile_screen.dart) | EditProfileScreen | 9 | 0 | 0 | 2 |
| [lib/features/settings/presentation/screens/email_settings_screen.dart](../../lib/features/settings/presentation/screens/email_settings_screen.dart) | EmailSettingsScreen | 9 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/feedback_screen.dart](../../lib/features/settings/presentation/screens/feedback_screen.dart) | FeedbackScreen | 8 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/help_center_screen.dart](../../lib/features/settings/presentation/screens/help_center_screen.dart) | HelpCenterScreen | 0 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/help_support_screen.dart](../../lib/features/settings/presentation/screens/help_support_screen.dart) | HelpSupportScreen | 0 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/language_settings_screen.dart](../../lib/features/settings/presentation/screens/language_settings_screen.dart) | LanguageSettingsScreen | 1 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/legal_hub_screen.dart](../../lib/features/settings/presentation/screens/legal_hub_screen.dart) | LegalHubScreen | 9 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/notification_preferences_screen.dart](../../lib/features/settings/presentation/screens/notification_preferences_screen.dart) | NotificationPreferencesScreen | 5 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/phone_settings_screen.dart](../../lib/features/settings/presentation/screens/phone_settings_screen.dart) | PhoneSettingsScreen | 12 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/privacy_settings_screen.dart](../../lib/features/settings/presentation/screens/privacy_settings_screen.dart) | PrivacySettingsScreen | 3 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/profile_view_screen.dart](../../lib/features/settings/presentation/screens/profile_view_screen.dart) | ProfileViewScreen | 18 | 0 | 0 | 2 |
| [lib/features/settings/presentation/screens/provider_access_log_screen.dart](../../lib/features/settings/presentation/screens/provider_access_log_screen.dart) | ProviderAccessLogScreen | 0 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/provider_resources_screen.dart](../../lib/features/settings/presentation/screens/provider_resources_screen.dart) | ProviderResourcesScreen | 0 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/provider_screen.dart](../../lib/features/settings/presentation/screens/provider_screen.dart) | ProviderScreen | 19 | 0 | 1 | 0 |
| [lib/features/settings/presentation/screens/referral_screen.dart](../../lib/features/settings/presentation/screens/referral_screen.dart) | ReferralScreen | 19 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/reminder_times_screen.dart](../../lib/features/settings/presentation/screens/reminder_times_screen.dart) | ReminderTimesScreen | 9 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/report_problem_screen.dart](../../lib/features/settings/presentation/screens/report_problem_screen.dart) | ReportProblemScreen | 15 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/restore_purchases_screen.dart](../../lib/features/settings/presentation/screens/restore_purchases_screen.dart) | RestorePurchasesScreen | 10 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/settings_screen.dart](../../lib/features/settings/presentation/screens/settings_screen.dart) | SettingsScreen | 21 | 0 | 1 | 0 |
| [lib/features/settings/presentation/screens/subscription_screen.dart](../../lib/features/settings/presentation/screens/subscription_screen.dart) | SubscriptionScreen | 16 | 0 | 0 | 1 |
| [lib/features/settings/presentation/screens/terms_policies_screen.dart](../../lib/features/settings/presentation/screens/terms_policies_screen.dart) | TermsPoliciesScreen | 4 | 0 | 0 | 0 |
| [lib/features/settings/presentation/screens/two_factor_auth_screen.dart](../../lib/features/settings/presentation/screens/two_factor_auth_screen.dart) | TwoFactorAuthScreen | 25 | 0 | 1 | 0 |
| [lib/features/splash/presentation/screens/splash_screen.dart](../../lib/features/splash/presentation/screens/splash_screen.dart) | SplashScreen | 0 | 4 | 0 | 0 |

Source files scanned: 268.
