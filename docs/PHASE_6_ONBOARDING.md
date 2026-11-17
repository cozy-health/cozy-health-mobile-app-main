# Phase 6: personalized onboarding and feature tour

## Before

Onboarding used three static slides and a SharedPreferences completion flag,
then routed to Welcome. Signup and social sign-in could subsequently show a
separate goals/age/gender personalization flow. There was no preferences model,
preferences Hive box, settings Hive box, or Home feature tour.

## Implementation

Seven pages share a progress bar, back navigation, and a primary action:
Welcome, focus areas, current challenges, check-in frequency, attribution,
personalization preview, and account setup. Focus and challenges require one
selection to continue; Skip clears that answer. Frequency defaults to
"A few times a week" and has no Skip, following the specific step requirement.
Attribution includes "Prefer not to say". Preview includes selections as chips
and an edit action. Account setup routes to the existing signup/login screens;
Skip routes to Welcome. Completing this flow also marks personalization complete
so new users do not repeat the old questionnaire after signup.

Entrance and page transitions use 700ms easeOutCubic, with no bounce. Reduced
motion and accessible navigation disable transitions. Content scrolls within
each page.

The optional first-Home tour starts after loading and layout. It highlights the
mood hero, Journal quick-action launcher, Assistant tab, and crisis button,
then shows "You're all set". Home has no Journal bottom-navigation tab, so the
tour highlights the existing + launcher and explains "Tap +, then Journal".
Navigation stays unchanged. Declining, skipping, or finishing records
`user_settings.has_seen_tour = true`. Existing users without that flag also get
one optional offer. The installed package is tutorial_coach_mark 1.3.4.
Pulse is disabled; cards use 700ms easeOutCubic or zero duration with reduced
motion. Package focus transitions are instantaneous because its easing is fixed.

## Storage and backend gap

`UserPreferences` has immutable `List<String> focusAreas`,
`List<String> currentChallenges`, `String checkInFrequency`, nullable
`String attribution`, `DateTime completedAt`, and `bool skipped`.
`skipped` records whether any step was skipped; completion time is serialized UTC.
The manual Hive adapter uses type ID 11.

Answers are saved in typed Hive box `user_preferences` under `current`, and
mirrored as JSON in `user_settings.onboarding_preferences`. The tour flag is
initialized only when absent. Preferences and settings are cleared with existing
account-data cleanup.

The mobile queue accepts arbitrary string types, but the backend SyncController
model registry rejects `user_preferences` with "Unknown type". No backend files
were changed. A stable UUID identifies a durable upsert intent in `sync_queue`;
re-saving replaces the previous intent. Queue processing holds this unsupported
type without upload or retry, while supported types continue normally. A log
reports the integration gap without logging users' answers. Backend support and
activation of this queued type are still required before server synchronization.

## Files

Created:

- `lib/core/models/user_preferences.dart`
- `lib/features/onboarding/presentation/screens/steps/welcome_step.dart`
- `lib/features/onboarding/presentation/screens/steps/focus_areas_step.dart`
- `lib/features/onboarding/presentation/screens/steps/challenges_step.dart`
- `lib/features/onboarding/presentation/screens/steps/frequency_step.dart`
- `lib/features/onboarding/presentation/screens/steps/attribution_step.dart`
- `lib/features/onboarding/presentation/screens/steps/preview_step.dart`
- `lib/features/onboarding/presentation/screens/steps/step_widgets.dart`
- `lib/features/home/presentation/widgets/feature_tour.dart`
- `test/features/onboarding/onboarding_flow_test.dart`
- `test/features/home/feature_tour_test.dart`
- This report.

Modified:

- `lib/core/services/local_db_service.dart`
- `lib/core/widgets/bottom_navigation_bar.dart`
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- `lib/features/auth/presentation/screens/congratulations_screen.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/home/presentation/screens/main_screen.dart`
- `pubspec.yaml` and `pubspec.lock`

## Verification and commit

13 onboarding tests cover all steps, selections, validation, skips, progress,
preview/edit, navigation, reduced motion, actual Hive persistence and adapter
reopening, and held/deduplicated sync intents. 10 tour tests cover optional offer,
seen suppression, skip and completion persistence, every target, repeat visits,
animations, overlay disposal, small screens with enlarged text, and integration
with real Home and navigation widgets. Tests use local fonts without fetching.

`flutter analyze lib`: zero issues. `flutter test`: 149 tests passing
(126 existing plus 23 new). One commit covers both sub-phases:
`feat(onboarding): 7-step personalized onboarding + feature tour`.
Phase 6 is committed locally and must remain unpushed pending review.

Before Phase 6, Phase 5 (`afdd220`) was pushed and both Android and iOS CI passed.
The workspace deferred tracker received the requested Community groups row
before Phase 6 implementation; Phase 6 does not modify that tracker.
