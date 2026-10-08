# Phase 5 empty states

## Audit before changes

No shared `lib/core/widgets/empty_state.dart` existed. Local empty widgets could
provide icons and routes, but had inconsistent typography and multiple actions.

| Screen | Before empty behavior | Placement / reuse |
|---|---|---|
| Home, first time | Welcome hero with icon and mood button; no blank space | Replace `_FirstTimeHero` content inside existing warm card |
| Home, partial | Existing per-card invitations, including “Log 3 moods to see trends” | Preserve `_MoodChart` guard and `_EmptyCard` |
| Mood history | Custom mood panel with logging CTA | StreamBuilder empty branch after loading |
| Journal list | Custom introduction and three actions | StreamBuilder empty branch after loading; retain editor callback |
| Journal search | Plain query text; no clear action | Results-empty branch below search field |
| Notifications | Custom icon/message and settings link | Existing stream empty branch after loading |
| Insights | Plain empty status mixed with charts; fewer than three entries not consistently guarded | Completed feed with fewer than three entries; reuse mood route |
| Chat history | Custom “No conversations yet” panel | Empty conversation-list branch; return new conversation |
| Professional directory | Search field and external resource links; no provider list or empty guidance | Below search field; focus existing search |
| Safety plan | Custom “No safety plan yet” introduction and creation button | FutureBuilder null branch after load |
| Affirmations | Existing hardcoded fallback | Preserve fallback; no new empty screen |
| Community feed | Custom empty panel; empty topic filter left compose bar only | Empty feed or filtered-topic branch |
| Community search | Static “Type to search” text even after entering a query | Posts tab when query is nonempty |
| Community groups | No groups screen or route exists | Not applicable; no new screen added |
| Content feed | Fixed featured article; no empty source branch | Featured section; preserve existing default article |
| Content categories | Plain “No articles yet” text | Empty articles branch |
| Bookmarks | Custom “No saved articles yet” icon/text; no CTA | Saved article stream empty branch after loading |
| Quiz list | Fixed catalog; no empty source branch | After loading attempts, before recommendation/catalog |
| Quiz history | Plain “No attempts yet” beneath heading | Completed empty attempts stream |
| Blocked users | Custom icon/text after unblocking mock users | Existing list empty branch |

## Implementation

Shared component: `lib/core/widgets/empty_state.dart`. Uses existing Material
icons, theme colors, 18/600 title, 14/400 optional subtitle with maximum width
280, 24px spacing and a primary CTA with minimum height 48. Scrolls when space
is constrained or text is enlarged. Supports an existing illustration asset.

Existing populated layouts and static catalogs remain available. Content,
Quiz and Blocked Users accept catalog/list inputs for their empty branches;
these inputs do not add backend fetching. Professional directory keeps its
external resource links and focuses its existing search field. Community search
remains a placeholder search surface without a backend source.

Phase 5 uses one commit for core flows and feature surfaces. Phase 4 commits
were pushed before Phase 5 changes; Phase 5 must remain unpushed.

## Validation

- `flutter analyze lib`: zero issues.
- `flutter test`: 126 passing tests, including 31 new empty-state widget tests
  in `test/features/empty_states/empty_states_test.dart`.
- Tests cover empty sources, CTA navigation, search clearing, loading guards,
  zero/one/two Insights entries, populated catalogs, live arrival of mood,
  journal, notification and bookmark data, and large text on a short screen.
- The unread notification transition exposed an existing rounded-border paint
  assertion. Invisible edges now use `BorderStyle.none`, preserving appearance.
- Backend files unchanged. The separate workspace deferred tracker was updated
  before Phase 5, as requested.
