# Mobile card and popup surface review

Reviewed on 2026-10-15. The approved appearance is black pages with charcoal cards and elevated popups.

## Changes

| Surface | Dark mode | Boundary |
| --- | --- | --- |
| Page and navigation | `#000000` | Existing navigation separators |
| Cards and grouped sections | `#171717` | Continuous rounded `#666666` outline |
| Elevated panels, dialogs, sheets, and menus | `#242424` | Visible rounded outline |
| Internal dividers | Theme neutral | `#404040` in normal dark mode |
| High contrast | Black or white surfaces | Opaque foreground outline, 2 px |

- Settings, privacy, appearance, and language groups own and clip their Material surfaces; child rows cannot cover the rounded outline.
- Home quiz, calendar, journaling, affirmation, and other custom cards use shared theme boundaries. Tinted panels and gradients are composited onto opaque surfaces.
- Dialogs, sheets, pickers, menus, and dropdowns share elevated surfaces. Transparent wrappers do not add a second outline around custom popup frames.
- Large text can expand cards, wrap summaries and legends, and scroll fixed-column screens and popup content. Keyboard-open report sheets retain visible inputs.
- Brand accents, content, navigation destinations, and backend interfaces are preserved. Shared UI helpers are AppSurface, AppScrollBody, and AppDropdown.

## Verification

Final checks passed. Analysis reports no errors or warnings; two pre-existing informational brace-style notices remain in hive_files_io.dart and repository_fixture.dart. The final test-file cleanup separately reports no issues.

| Check | Result | Evidence |
| --- | --- | --- |
| Full suite | 614 passed, 2 skipped | [Log](../../build/surface-full-tests.log) |
| Normal contrast, light and dark | 430 checks passed; 0 rendering errors | [Strict audit log](../../build/surface-probe-tests.log) |
| High contrast, light and dark | 430 checks passed; 0 rendering errors | [Strict audit log](../../build/surface-contrast-probe-tests.log) |
| Accent, popup, dropdown, and keyboard regression matrix | Passed | [Targeted log](../../build/surface-final-targeted.log) |
| Analysis | No errors or warnings; existing informational notices only | [Full log](../../build/surface-analysis.log), [final test-file check](../../build/surface-final-test-analysis.log) |

The screen audit covers 320 ? 568 portrait and 568 ? 320 landscape with 200% text. The main UI review also covers larger phones and 160% text. Popup regressions exercise all four brand accents, normal and high contrast, actual open menus and pickers, dropdown selection, snackbar outlines, and a 300 px keyboard inset.

[Open the screenshot gallery](../../build/surface-review/index.html). Screenshots and machine-readable screen/overlay inventories are in `build/surface-review`.

## Coverage checklist

All 115 public screen classes have runtime fixtures. Shared card primitives and 79 dialog, sheet, menu, and picker call sites were reviewed. Private popup content inherits the shared frame/theme treatment; major public popup variants also have direct rendering fixtures.

### activity (1)

- [x] ActivityScreen

### assistant (4)

- [x] AssistantScreen
- [x] ChatSettingsScreen
- [x] ConversationHistoryScreen
- [x] PastConversationScreen

### auth (6)

- [x] CongratulationsScreen
- [x] CreateAccountScreen
- [x] ForgotPasswordScreen
- [x] LoginScreen
- [x] RestoreScreen
- [x] WelcomeScreen

### community (14)

- [x] CommentsScreen
- [x] CommunityGuidelinesScreen
- [x] CommunityHubScreen
- [x] CommunitySearchScreen
- [x] CreatePostScreen
- [x] DirectMessagesScreen
- [x] FeaturedPostsScreen
- [x] FollowListScreen
- [x] MessageRequestsScreen
- [x] ModerationQueueScreen
- [x] PostDetailScreen
- [x] TopicsScreen
- [x] UserProfileScreen
- [x] CreateCommunityGroupScreen

### content (6)

- [x] ArticleDetailScreen
- [x] CategoryDetailScreen
- [x] ContentHomeScreen
- [x] ContentSearchScreen
- [x] DailyAffirmationScreen
- [x] SavedArticlesScreen

### crisis (10)

- [x] CrisisResourcesHubScreen
- [x] CrisisDetectionOverlayScreen
- [x] EmergencyContactScreen
- [x] SafetyPlanScreen
- [x] SafetyPlanViewScreen
- [x] PersistedSafetyPlanViewScreen
- [x] GroundingExerciseScreen
- [x] BreathingExerciseScreen
- [x] ProfessionalHelpScreen
- [x] CrisisFollowUpScreen

### home (4)

- [x] HomeScreen
- [x] StreakDetailScreen
- [x] InsightsScreen
- [x] MainScreen

### insights (6)

- [x] ActivityMoodScreen
- [x] InsightsHomeScreen
- [x] MonthlyReportScreen
- [x] MoodTrendScreen
- [x] SleepMoodScreen
- [x] TriggersAnalysisScreen

### journal (7)

- [x] JournalScreen
- [x] JournalEditorScreen
- [x] GuidedPromptsScreen
- [x] JournalVoiceRecordingScreen
- [x] JournalSearchScreen
- [x] JournalEntryDetailScreen
- [x] VoiceRecordingScreen

### mood check in (5)

- [x] MoodFeelingScreen
- [x] MoodCheckInSuccessScreen
- [x] MoodHistoryScreen
- [x] MoodDetailViewScreen
- [x] MoodSuccessScreen

### notifications (2)

- [x] NotificationsScreen
- [x] NotificationDetailScreen

### onboarding (1)

- [x] OnboardingScreen

### personalization (1)

- [x] PersonalizationScreen

### preparing cozy (1)

- [x] PreparingCozyScreen

### quiz (9)

- [x] QuizDetailScreen
- [x] QuizHistoryScreen
- [x] QuizResultDetailScreen
- [x] QuizResultScreen
- [x] QuizSelectionScreen
- [x] QuizSharedScreen
- [x] QuizUsernameScreen
- [x] QuizInvitationScreen
- [x] QuizTakingScreen

### settings (36)

- [x] AboutScreen
- [x] AccessibilitySettingsScreen
- [x] AccountDeletionScreen
- [x] ActiveSessionsScreen
- [x] AppearanceSettingsScreen
- [x] BillingHistoryScreen
- [x] BlockedUsersScreen
- [x] CancelSubscriptionScreen
- [x] ChangePasswordScreen
- [x] ConnectedAppsScreen
- [x] DataExportScreen
- [x] DataExportStatusScreen
- [x] DigitalWellbeingScreen
- [x] DownloadMyDataScreen
- [x] EditProfileScreen
- [x] EmailSettingsScreen
- [x] FeedbackScreen
- [x] HelpCenterScreen
- [x] HelpSupportScreen
- [x] LanguageSettingsScreen
- [x] LegalHubScreen
- [x] NotificationPreferencesScreen
- [x] PhoneSettingsScreen
- [x] PrivacySettingsScreen
- [x] ProfileViewScreen
- [x] ProviderAccessLogScreen
- [x] ProviderResourcesScreen
- [x] ProviderScreen
- [x] ReferralScreen
- [x] ReminderTimesScreen
- [x] ReportProblemScreen
- [x] RestorePurchasesScreen
- [x] SettingsScreen
- [x] SubscriptionScreen
- [x] TermsPoliciesScreen
- [x] TwoFactorAuthScreen

### splash (1)

- [x] SplashScreen

### wellness (1)

- [x] WellnessScreen

## Testing limits

These are offline Flutter widget renders using fixture data, cached data, and error/empty states. They do not certify every live-account state, device font fallback, or OS-owned permission, biometric, payment, and share prompts. No production account actions or native calls were performed. The iOS app was not installed or built on a device in this Windows workspace.

For readable screenshots, the optional capture workflow loads Outfit from `build/surface-review/Outfit.ttf`, downloaded from the official Google Fonts repository. Ordinary test runs retain the existing headless font setup.

## Reproduce

Run Flutter and Dart outside the sandbox as required by the project's AGENTS.md.

```powershell
New-Item -ItemType Directory -Force build/surface-review
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/google/fonts/main/ofl/outfit/Outfit%5Bwght%5D.ttf' -OutFile build/surface-review/Outfit.ttf
flutter test --no-pub
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub --dart-define=SURFACE_SCREENSHOTS=true test/core/theme/surface_test.dart test/features/ui_review/ui_review_test.dart
flutter test --no-pub --dart-define=SURFACE_SCREENSHOTS=true --dart-define=SURFACE_NORMAL=true --dart-define=SURFACE_STRICT=true test/audit/full_app_audit_probe.dart
flutter test --no-pub --dart-define=SURFACE_SCREENSHOTS=true --dart-define=SURFACE_STRICT=true test/audit/full_app_audit_probe.dart
```
