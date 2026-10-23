# Activity and Provider design proposal

Review date: 2026-10-22. Open [the review gallery](index.html).

These are design-only Flutter renders, separate from production routes, repositories
and APIs. Names, conversation, statistics and record/resource examples are synthetic.
Buttons depict proposed behaviour; this fixture does not send messages, connect
providers, fetch articles or change patient data.

Home and mood are committed separately on `develop`, commit `bae3d14`.
The Activity and Provider proposal is deliberately awaiting design review.

## Changes shown

- Home's 20 px margins, Outfit typography, warm/neutral canvas, 24 px card corners
  and 48 px controls continue into these screens.
- Activity names intensity accurately, shows a 1–5 scale with missing-data gaps,
  solid/dashed chart keys, actual calendar dates and neutral comparisons. Current
  writing streak is distinguished from the selected reporting range. Causes show
  counts with an explicit denominator and explain multiple causes per check-in.
- The four article topics from the supplied reference use equal-height cards with
  full titles. Two columns become one at narrow widths or large text. The current
  brain illustration is reused; the dial and lettering are code-native visual
  treatments inspired by the reference. Final article imagery is reviewable here,
  rather than presented as an exact reproduction of the source illustration files.
- Provider has one identity panel and one tab set: Messages, Shared, Resources.
  “Shared” opens Shared history. Separate message surfaces work in light and dark
  themes. The composer reserves a full row for text in portrait, with sharing,
  voice and disabled empty-send controls below. Landscape with a keyboard uses
  one compact row. Provider receives no floating overlay buttons.
- Shared history keeps dates and internal IDs out of the shared record content.
  Resources shows pending and completed work, with an explicit decline action.
  Disconnected and pending-invitation views have distinct wording and actions.
- All four existing accents have light/dark Activity and Messages previews.
  Additional captures cover 320 px width, 200% text, dark high contrast and a
  667×375 landscape viewport with a reserved 180 px keyboard inset.

## Decisions still required before production implementation

- Approve these layouts and the article illustration treatment.
- Choose existing published article content or commission the four exact reference
  topics. Titles in this preview are sample content, not a new live article source.
- Retain the existing data, consent and routing contracts. The audit's loading,
  empty, offline, retry, stable-message-ID, conversation-reset and picker-pagination
  changes still require production implementation and behavioural verification;
  screenshots do not establish that these are working features.

See [the two-pass audit](../activity-provider-two-pass-audit.md) for the complete
implementation scope and the issues found in the current production screens.

## Reproduce

```powershell
flutter test tool/design_previews/activity_provider_preview_test.dart --reporter expanded
flutter analyze tool/design_previews/activity_provider_preview_test.dart
```

Screenshots use locally loaded real fonts, project theme tokens and the current
bottom navigation. No production screen files were edited for this proposal.

Verification: 29 render/layout checks passed; scoped Flutter analysis found no
issues. All gallery image/document paths resolve. There are 35 full-resolution PNG
captures. These checks validate the preview layouts, not production behaviour.
