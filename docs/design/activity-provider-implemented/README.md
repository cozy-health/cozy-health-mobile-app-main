# Activity and Provider implementation review

Development branch: `develop`. No production deployment, release, push or merge
is part of this work. The previously approved Home/mood work remains committed
at `bae3d14`.

Activity and Provider use the approved design in real application widgets.
Profile, Community, Groups and public member screens in this gallery are separate
design proposals and are not registered application routes.

## Implemented

- Activity follows the Home grid, surfaces and theme. It preserves Week, Month,
  3 Months and Year, uses actual date ranges, the existing intensity conversion,
  null chart buckets, neutral comparisons, line-style keys and accessible chart
  data. Check-in rhythm uses actual distinct dates. Writing streak uses all
  completed journals instead of a period-filtered subset. Duplicate causes are
  counted once per check-in; frequency is not labelled causal impact.
- Recommended articles use real published list/detail endpoints, account-scoped
  first-page cache, complete article bodies and explicit loading/error/empty/
  cached states. The library supports pagination. Missing author/date/read-time
  metadata is omitted for these articles, and they do not fall back to another
  article’s body. Four reference titles in screenshot fixtures are synthetic;
  they do not establish that four matching articles are published on development.
- Four distinct original illustrations were extracted from the owner’s
  `Frame 1000004340.svg`. Duplicate reference cards were not duplicated as content.
  SVG source fragments and transparent PNG exports are included, with export
  scripts and a source hash. Colours are preserved. Small light illustration
  plates intentionally preserve the original black clock hands/lettering in dark
  mode; outer cards follow the selected user theme.
- Provider preserves the existing API, consent-filtered SharedRecordCard, voice
  sending, account caches and idempotent message identifiers. Identity, Messages/
  Shared/Resources, message bubbles, local times, connection states and composer
  now follow the approved theme-aware design. Empty drafts cannot send. Failed
  sends remain actionable after successful polling. Delayed loading/sending
  errors are scoped to the originating account/conversation.
- Record selection paginates in the same sheet, retains existing previews and
  selected indicators, and displays the ten-record cap. Selected records have
  useful privacy-filtered titles, preview and removal rather than a fixed-height
  tray. Shared record cards do not show timestamps or internal IDs.
- Resources share the new surfaces and controls, guard delayed results by
  account and consistently disable status mutations offline.

## Review boundaries

The owner was asked whether to add four new complete articles or use available
published content. Until that content decision changes, this implementation reads
available published articles and does not invent article bodies or publish content.
The supplied SVG is the artwork source, not an article-text source.

Screenshot fixtures use synthetic records and local API doubles. No live patient
data was read and no articles/messages/posts were published to generate them.
They demonstrate the real Flutter layout and client flows, not live API availability
or a physical-device acceptance run. Theme variants cover all four accents in
light/dark/high contrast, plus 200% text and the landscape keyboard layout.

## Reproduce

```powershell
flutter test test/features/activity/activity_summary_test.dart test/features/content/published_articles_repository_test.dart test/features/settings/provider_hub_test.dart test/features/settings/provider_resources_test.dart test/features/settings/provider_record_picker_test.dart
flutter test test/features/ui_review/implemented_activity_provider_review_test.dart
```

See [the Profile/Community review](../profile-community-two-pass-review.md) for the
next phase. No production Profile or Community screen was changed for the proposals.

Verification: 70 checks passed (24 statistics/content/messaging/resource/privacy
checks and 46 screen-layout scenarios). Scoped Flutter analysis is clean. The
gallery has 63 screen captures and all theme/proposal paths resolve. The default
client environment was verified as development, using `api-dev.cozyhealth.org`.
