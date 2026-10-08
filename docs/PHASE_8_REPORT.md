# Phase 8 report

## Deployment and sync prerequisite

Backend develop is pushed through eecf0b5 (335a773 preferences sync, eecf0b5 demo account, c00c033 deploy entrypoint). Railway deployment is online. DemoAccountSeeder ran against the Railway production database through its public MySQL proxy using temporary process environment values; local environment files were unchanged. Live authenticated checks returned login 200, 30 moods, 14-day streak, a complete safety plan and stored onboarding preferences. No tokens are included in this report.

Mobile prerequisite eec118e is committed and pushed. The queue previously excluded user_preferences even when due. It now handles them with the same due-date and retry rules as other types. Two upload/retry tests were added; 151 tests passed and analysis had zero issues. Both CI builds succeeded:
- [iOS unsigned IPA](https://github.com/cozy-health/cozy-health-mobile-app-main/actions/runs/37758004728)
- [Android debug APK](https://github.com/cozy-health/cozy-health-mobile-app-main/actions/runs/37758004744)

## Commits and checks

One commit per Phase 8 sub-phase. Phase 8 commits remain local; DEFERRED.md was not modified.

| Sub-phase | Commit | New tests | Full suite | flutter analyze lib |
|---|---|---:|---:|---|
| 8.1 Core UX | 716b943 | 11 | 162 passed | Zero issues |
| 8.2 Monitoring | 9c26c40 | 7 | 169 passed | Zero issues |
| 8.3 Help center | a95635c | 4 | 173 passed | Zero issues |
| 8.4 Wellbeing | Commit containing this report | 7 | 180 passed | Zero issues |

Phase 8 adds 29 tests; the sync prerequisite adds another two to the previous 149-test baseline.

## 8.1 Core UX

Auth fields have email/password/new-password autofill hints, including password confirmation. Biometric login was already implemented with local_auth. It now requires device support, enrolled biometrics and a stored token, hides otherwise, blocks duplicate submission and validates the saved session before navigation. This is not a new biometric package integration; real hardware behavior still needs device testing.

Mood check-in drafts retain the current step and all answers on step changes in the existing user_settings Hive box. Only today's draft is offered, with Resume and Discard actions. Saving and explicit discard clear it. Failed saves preserve the check-in. Journal save now awaits persistence before closing the editor, preserving the draft on failure.

Shared AppButton and mood/provider/journal save controls disable during submission and show an inline spinner with Loading... . Keyboard handling dismisses on outside taps and dragged form scrolls; auth fields have additional scroll padding.

SkeletonLoader provides the 1500ms easeInOut 0.4/0.7/0.4 animation and stops for reduce-motion/accessibility settings. Applied to Home, Journal, mood history, notifications, insights, activity, saved articles, quiz selection and quiz history. Community and content feeds use static in-memory data with no initial fetch/loading phase; their populated layouts are preserved.

FriendlyError and AppSnackbar provide warm copy, retry where an operation can be repeated, and support links after three failures. Insights and provider error views have retry/failure counting. Raw technical error text is replaced with plain connection guidance. Existing snackbar actions, including Undo, are preserved. Shared notices have an icon, rounded 16 corners, elevation 3, 3000ms dismissal, and no slide animation with reduce motion. Legacy constructors across the app now use the shared helper.

Tests cover draft fields, reopen persistence, day expiry and deletion; real check-in resume; auth autofill and unsupported biometrics; loading buttons; reduced-motion skeletons; technical error redaction; retry and support recovery. The earlier empty-state test now expects the skeleton used by insights.

## 8.2 Monitoring

Sentry Flutter 8.14.2 is installed (dependency resolver selection). Reporting is disabled unless SENTRY_DSN is supplied as a dart-define. No invalid placeholder DSN is initialized.

Errors are rebuilt using an allowlist: no journal bodies, mood notes, chat text, emails, names, request bodies/URLs, arbitrary contexts, breadcrumbs, function names, variables or source context are retained. Fixed feature tags cover mood_checkin, journal, crisis, auth, chat, provider and app. Crisis route events and events while the crisis overlay is open are dropped. Screenshot, view hierarchy, feedback, scope sync and interaction capture are disabled.

Limitations for Phase 8.5: dashboard delivery cannot be verified without a real DSN. An explicit debug-only probe exists but is never called automatically. Native crash, app-hang and ANR reporting are disabled because native events bypass Dart redaction. Performance sampling is configured at 0.2, but transaction uploads are dropped until a safe schema is implemented. This integration currently reports Dart/Flutter errors only. See PHASE_8_MONITORING.md for details.

## 8.3 Help center

20 static FAQ items: Getting Started 3, Mood & Journal 4, Crisis Resources 4, Privacy & Data 3, Account 3, Community 3. Questions expand into muted answers. Search filters questions and answers; empty search has Clear search. The existing Settings -> Help & Support route opens the new help center and retains report-problem and feedback navigation. Old unsupported claims about emailed PDF/JSON exports and unconditional data-sharing guarantees were removed.

Emergency guidance is grounded in [NHS urgent mental health guidance](https://www.nhs.uk/nhs-services/mental-health-services/where-to-get-urgent-help-for-mental-health/), adapted to local emergency services rather than a country-specific number. No backend FAQ endpoint was added.

Tests verify catalog/category counts, expansion, search/clear, existing support-route compatibility and report-problem navigation.

## 8.4 Digital wellbeing and final verification

Settings -> Digital Wellbeing captures Gentle reminders (off), Suggested daily usage limit (15 min / 30 min / 1 hour / No limit; defaults to No limit), and Show usage summary at close (off). Values persist in the user_settings Hive box under digital_wellbeing. These are preferences only: notifications, limits and close summaries are not enforced or activated yet, which the screen explains.

Backend sync gap: /sync/batch does not register user_settings. The app stores digital_wellbeing_sync_pending=true alongside the values and does not enqueue an unsupported type that would exhaust retry attempts. Upload requires a future backend user_settings handler. No backend changes and no DEFERRED.md changes were made.

Tests cover defaults, invalid stored limits, Hive reopen persistence/pending intent, both toggles/dropdown, disabled saving controls, and load retry. Final SDK privacy verification also explicitly disables native app-hang/ANR uploads and asserts those guards in the monitoring configuration test. This final hardening is grouped into the wellbeing commit.

## Files by sub-phase

### 8.1 Core UX

- `lib/core/api/api_interceptors.dart`
- `lib/core/services/mood_draft_service.dart`
- `lib/core/widgets/app_button.dart`
- `lib/core/widgets/app_snackbar.dart`
- `lib/core/widgets/custom_text_field.dart`
- `lib/core/widgets/friendly_error.dart`
- `lib/core/widgets/skeleton_loader.dart`
- `lib/features/activity/presentation/screens/activity_screens.dart`
- `lib/features/assistant/presentation/screens/assistant_screen.dart`
- `lib/features/assistant/presentation/widgets/conversation_list_view.dart`
- `lib/features/auth/presentation/screens/create_account_screen.dart`
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/widgets/apple_auth_button.dart`
- `lib/features/auth/presentation/widgets/auth_ui.dart`
- `lib/features/auth/presentation/widgets/google_auth_button.dart`
- `lib/features/auth/presentation/widgets/sign_up_form.dart`
- `lib/features/community/presentation/screens/create_post_screen.dart`
- `lib/features/community/presentation/screens/message_requests_screen.dart`
- `lib/features/community/presentation/screens/post_detail_screen.dart`
- `lib/features/community/presentation/screens/user_profile_screen.dart`
- `lib/features/content/presentation/screens/article_detail_screen.dart`
- `lib/features/content/presentation/screens/daily_affirmation_screen.dart`
- `lib/features/content/presentation/screens/saved_articles_screen.dart`
- `lib/features/crisis/presentation/screens/crisis_screens.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/insights/presentation/screens/insights_home_screen.dart`
- `lib/features/insights/presentation/screens/sleep_mood_screen.dart`
- `lib/features/insights/presentation/screens/triggers_analysis_screen.dart`
- `lib/features/insights/presentation/widgets/insights_feed.dart`
- `lib/features/journal/presentation/screens/journal_screen.dart`
- `lib/features/journal/presentation/screens/voice_recording_screen.dart`
- `lib/features/mood_check_in/presentation/screens/mood_feeling_screen.dart`
- `lib/features/notifications/presentation/screens/notifications_screen.dart`
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- `lib/features/quiz/presentation/screen/quiz_history_screen.dart`
- `lib/features/quiz/presentation/screen/quiz_result_detail_screen.dart`
- `lib/features/quiz/presentation/screen/quiz_selection_screen.dart`
- `lib/features/settings/presentation/screens/about_screen.dart`
- `lib/features/settings/presentation/screens/accessibility_settings_screen.dart`
- `lib/features/settings/presentation/screens/account_deletion_screen.dart`
- `lib/features/settings/presentation/screens/active_sessions_screen.dart`
- `lib/features/settings/presentation/screens/billing_history_screen.dart`
- `lib/features/settings/presentation/screens/blocked_users_screen.dart`
- `lib/features/settings/presentation/screens/cancel_subscription_screen.dart`
- `lib/features/settings/presentation/screens/change_password_screen.dart`
- `lib/features/settings/presentation/screens/connected_apps_screen.dart`
- `lib/features/settings/presentation/screens/data_export_screen.dart`
- `lib/features/settings/presentation/screens/data_export_status_screen.dart`
- `lib/features/settings/presentation/screens/download_my_data_screen.dart`
- `lib/features/settings/presentation/screens/edit_profile_screen.dart`
- `lib/features/settings/presentation/screens/email_settings_screen.dart`
- `lib/features/settings/presentation/screens/feedback_screen.dart`
- `lib/features/settings/presentation/screens/language_settings_screen.dart`
- `lib/features/settings/presentation/screens/phone_settings_screen.dart`
- `lib/features/settings/presentation/screens/privacy_settings_screen.dart`
- `lib/features/settings/presentation/screens/provider_screen.dart`
- `lib/features/settings/presentation/screens/referral_screen.dart`
- `lib/features/settings/presentation/screens/reminder_times_screen.dart`
- `lib/features/settings/presentation/screens/report_problem_screen.dart`
- `lib/features/settings/presentation/screens/subscription_screen.dart`
- `lib/features/settings/presentation/screens/two_factor_auth_screen.dart`
- `lib/main.dart`
- `test/features/empty_states/empty_states_test.dart`
- `test/features/ux/ux_test.dart`
- `test/support/local_fonts.dart`

### 8.2 Monitoring

- `docs/PHASE_8_MONITORING.md`
- `lib/core/services/crash_reporting.dart`
- `lib/features/crisis/presentation/screens/crisis_screens.dart`
- `lib/main.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/core/crash_reporting_test.dart`

### 8.3 Help center

- `lib/features/settings/presentation/screens/help_center_screen.dart`
- `lib/features/settings/presentation/screens/help_support_screen.dart`
- `test/features/settings/help_center_test.dart`

### 8.4 Digital wellbeing and final verification

- `lib/core/models/digital_wellbeing_preferences.dart`
- `lib/core/services/digital_wellbeing_service.dart`
- `lib/core/routing/app_router.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/features/settings/presentation/screens/digital_wellbeing_screen.dart`
- `test/features/settings/digital_wellbeing_test.dart`
- `docs/PHASE_8_REPORT.md`
- `lib/core/services/crash_reporting.dart` (final native app-hang/ANR privacy guard)
- `test/core/crash_reporting_test.dart` (guard assertions)
- `docs/PHASE_8_MONITORING.md` (updated native reporting limitations)
