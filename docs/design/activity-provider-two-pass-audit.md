# Activity and Provider: two-pass audit

Reviewed 2026-10-22. Home spacing corrections are already implemented locally.
Activity and Provider production code was not changed during this review.

Pass 1 inspected the implemented layout, navigation, typography, artwork and the
provided Recommended for you reference. Pass 2 inspected data meaning, dates,
loading/error/offline states, accessibility and current-widget stress renders.
Six isolated synthetic-data render scenarios were exercised. The audit harness
collects render exceptions as evidence; its completion does not mean the screens
are defect-free. It reproduced a Provider RenderFlex overflow of 69px at 667x375,
200% text and a 180px keyboard inset. Normal phone / large phone scenarios were
also captured. No physical-device acceptance or live API verification was done.

## Activity findings

| ID / pass | Issue found | Recommended change |
| --- | --- | --- |
| A1 / 1 | Page margins (16px), app-bar title inset (24px), 8px content cards and assorted gaps differ from the approved Home design. | Use the same 20px page grid, typography roles and 4/8/12/16/20 spacing. Use 24px large panels and 16px small tiles where appropriate. |
| A2 / 1 | The chart lacks a numeric vertical scale and precise date ranges; period labels are fixed Mon-Sun or generic 1-7. | Label the measured quantity, real date/bucket ranges and display scale; state the comparison range clearly. |
| A3 / 1 | The two legend entries differ only by colour; the bullet glyph is missing in the captured font. | Use actual rendered line samples with distinct solid/dashed styles, contrast-aware colours and text; add accessible chart summaries/data access. |
| A4 / 1 | Period buttons use raw accent text/borders, InkWell and an unconditional 180ms transition. | Use branded press feedback, selected semantics, readable foreground fallback and shared reduced-motion handling; retain 48px targets and full labels. |
| A5 / 1 | Recommended for you contains insight/journal shortcuts rather than the reference's article cards; title lengths leave uneven card bottoms. | Implement a real article grid with aligned image frames, equal row heights and complete wrapping titles; retain existing shortcuts under a separate optional Quick insights section if needed. |
| A6 / 2 | Average emotional intensity is named averageMood and shown as Mood trend; a higher value appears as a positive change. | Label it Average intensity / Intensity change, use the existing 1-5 display conversion, neutral directional language, and do not imply stronger emotion means better well-being. |
| A7 / 2 | Missing chart buckets become 5.0 for the current period; comparison buckets instead have gaps. | Keep missing values distinct from observations, draw gaps/isolated points, and show insufficient-data messages. Never create observed values from absent entries. |
| A8 / 2 | Cozy Calendar fills the first N weekdays from total entries, so repeated entries on one date imply activity on other dates. Writing weekdays are aggregated over the whole selected period without explaining this. | Derive each calendar indicator from actual dates; clearly label any weekday-frequency aggregation. Align the same date/timezone policy across Home and Activity. |
| A9 / 2 | Common triggers labels frequency as High/Medium/Low impact, though no impact is measured. | Match the new check-in's Causes terminology; show counts or percentage of check-ins mentioning each cause. Do not label frequency as causal impact. |
| A10 / 2 | Writing streak uses already period-filtered records and today's date; the apparent global streak can change when switching periods. | Explicitly define current streak vs longest streak in the selected range and keep its policy consistent with Home. |
| A11 / 2 | Stream errors are not separated from an empty data set, and the Activity bottom padding is only 48px while the shell overlays a two-button stack. | Distinguish loading, empty, error and available cached data; provide appropriate retry. Calculate clearance from the actual floating stack so the last article stays readable/tappable. |

## Provider findings

| ID / pass | Issue found | Recommended change |
| --- | --- | --- |
| P1 / 1 | No conversation is presented as Connect provider, with a sparse unpadded empty state and equal-weight Connect/Refresh text actions. | Distinguish unconnected, pending invitation, connected-empty, loading, offline and failed-load states; use one clear primary action and secondary retry. Derive connection state rather than inferring it solely from a thread list. |
| P2 / 1 | Provider identity is a centred name with no clear connection/sharing context; multiple providers add a separate dropdown and repeat the name. | Use a compact provider header/switcher with initials/photo and actual available identity fields plus a labelled connection/sharing action. Do not invent availability, specialty or response times. |
| P3 / 1 | Standard-light message surfaces visually merge with the white canvas; sender/recipient distinction depends mostly on alignment. | Use distinct incoming/outgoing bubbles with explicit readable text colours, appropriate boundaries in high contrast, consistent grouping and padding. |
| P4 / 1 | Message timestamps use raw YYYY-MM-DD HH:MM text. | Use concise localised message times and date separators where helpful. Preserve the existing privacy rule that shared record cards do not expose timestamps/internal IDs. |
| P5 / 1 | Hub resources and connection-management resources duplicate entry points, while resources/shared-history lists have generic or absent empty states. | Retain Messages / Shared history / Resources as primary destinations, route duplicate resource links to one consistent presentation, and give each state clear content and actions. |
| P6 / 2 | The composer puts attachments, input, microphone and text Send into one row; at 200% text the placeholder becomes a tall narrow column. A landscape keyboard reproduces a 69px bottom overflow. | Adapt composer controls to available width/text scale, preserve useful input width, use a separate action row when required, and keep it visible above the keyboard/safe area. Keep Provider free of floating Home shortcuts. |
| P7 / 2 | Send remains visually enabled for an empty draft with no attachments, but pressing it does nothing. | Derive enabled state from trimmed text, selected records, sending and offline state; keep retry clear and preserve the existing stable message identifier. |
| P8 / 2 | Selected-record chips have a fixed 72px tray; repeated record types look identical and the ten-record limit has little feedback. | Use adaptive preview chips/cards with meaningful available titles, visible selected count/cap, clear removal and selected state in the picker; keep privacy-filtered previews. |
| P9 / 2 | Record picker pagination closes and reopens a sheet for each page; resource completion/decline controls have inconsistent emphasis and offline availability. | Keep pagination in one stable sheet; use balanced branded actions with clear status, per-item progress and consistent offline feedback. |
| P10 / 2 | One error variable handles loading, send and record failures; successful five-second refreshes clear it even when a failed send is still pending. Error copy claims saved messages even when no cache exists. | Separate fetch, cached/offline and failed-send presentation; keep send failure until success/dismissal; preserve the draft, attachments and idempotent retry. |
| P11 / 2 | Account change clears content but does not immediately reload/reset every loading/error flag; refresh errors are not consistently scoped to the originating owner. | Refresh/reset connection presentation immediately for the new account and guard delayed results/errors by account/conversation. Preserve existing consent and cache boundaries. |

## Reference implementation scope

The reference contains four article tiles: Mental Health 101; productivity and
burnout; diet, exercise and mental health; gratitude and mental health.

- Keep the two-column illustration/title arrangement on ordinary phones; switch
  to one column for narrow widths or larger text. Allow titles to wrap fully.
- Use full illustrations with BoxFit.contain, common optical image frames and
  equal row heights. Do not reuse mood faces as unrelated article illustrations.
- Preserve artwork colours. Derive card fills/borders from the selected theme;
  do not hard-code the reference's green/orange borders into every theme.
- Keep Recommended for you as a curated section. Do not claim clinical or
  per-patient ranking: the current backend explicitly supplies published articles
  without patient recommendation ranking or reading analytics.
- Use existing content article list/detail/bookmark endpoints. The Flutter normal
  catalog currently exposes one built-in item; this does not establish how many
  published articles exist on the development server, which was not queried.
- The detail widget accepts an explicit body but falls back to generic anxiety
  copy and a fixed author/date when metadata is missing. Each new tile must open
  its own real body and truthful metadata; omit missing author/date/read time.
- Loading, offline cached content, no available articles and failures need honest
  states. Four complete reference articles require locating or preparing their
  content; do not fill empty positions with fake cards.

An asynchronous question asks whether to use available published articles or add
the four exact reference topics with their full article content. That decision is
still pending when writing this report.

## Shared acceptance requirements

Use existing project tokens and AppPressable, preserve native text input and
navigation behaviour, and validate all four accents in light/dark/high contrast.
Retain text scaling and reduced motion. Charts need text/semantics in addition to
colour. Preserve current sharing permissions, protected journal entry points,
voice/record preview, cache, account guards, message retry IDs and existing routes.

Next: confirm this scope/content decision, produce Activity and Provider visual
layouts including key empty/connected/keyboard states, obtain design approval,
then implement and provide fresh Flutter screenshots. No commit/push is included.

## Evidence and main source locations

- Current renders: ../../build/activity-provider-review/index.html
- Activity: lib/features/activity/presentation/screens/activity_screens.dart
- Provider: lib/features/settings/presentation/screens/provider_hub_screen.dart
- Resources: lib/features/settings/presentation/screens/provider_resources_screen.dart
- Shared records: lib/features/settings/presentation/widgets/shared_record_card.dart
- Content: lib/features/content/data/content_repository.dart and article_detail_screen.dart
- Existing backend: routes/api.php and Api/V1/ArticleController.php
- Apple layout: https://developer.apple.com/design/human-interface-guidelines/layout
- Apple charts: https://developer.apple.com/design/human-interface-guidelines/charts
- Apple accessibility: https://developer.apple.com/design/human-interface-guidelines/accessibility
