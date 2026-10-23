# Profile and Community review — development proposal

Reviewed 2026-10-23. Activity/Provider design approval does not approve these
new layouts. Production Profile and Community files are unchanged.

Pass 1 inspected the current screens, nearby Home/Activity design tokens,
navigation and visible hierarchy. Pass 2 inspected actual state/data handling,
privacy boundaries, large-text behaviour and proposed Flutter renders.

| Current issue | Proposed correction |
| --- | --- |
| Profile reports a one-day streak whenever any mood exists (`profile_view_screen.dart`). | Calculate distinct consecutive local dates; agree with the actual current-streak policy and show zero honestly. The sample “3 days” in the design is illustrative, not an implemented statistic. |
| Missing profile bio becomes a sample self-care quote. | Omit absent bio, or offer an explicit Add bio action. Never present sample text as a user's statement. |
| Profile mixes several border/radius/spacing styles and changes the page inset to 24 px. | Continue the approved 20 px page grid, Outfit typography and 24/16 px surfaces; align stat cards and stack at larger text. |
| Repeated stream/future creation can refresh joined/profile information during unrelated rebuilds. | Retain scoped subscriptions and joined-date future in screen state; clear immediately on account changes. |
| Current profile mixes personal wellness information with community identity without explaining their difference. | Keep check-in counts/streaks in the account’s own profile. Public member previews show non-anonymous public posts, with no mood/journal statistics. Confirm which public identity fields the backend actually supplies before showing them. |
| Community header puts search, Post and notifications in one row. | Separate the title/notification action, full-width search and one clear Create a post action. Adapt with large text rather than squeezing the input. |
| Community has both Post and Share something composer destinations. | Use one primary Create a post action. Preserve text/photo creation options in its existing flow. |
| Community topics use raw gesture targets without explicit selected semantics. | Use the house pressable, selected semantics, 48 px targets, horizontal overflow and contrast-aware selected foregrounds. Preserve every existing filter even though only a subset appears in the sketch. |
| General Posts heading, pills and cards follow different spacing/type conventions. | Use consistent Posts/Groups navigation, Latest posts hierarchy, theme-aware surfaces and one rhythm of gaps. No invented member totals, availability or engagement metrics in live data. |
| Post moderation relies on a long-press callback at the card entry point. | Add a visible, labelled action menu while retaining long press. Preserve report, hide, block and ownership rules. |
| Reaction controls depend on compact icon/count rows. | Give like and comment actions explicit labels, checked state for likes and 48 px interaction regions; wrap at large text. |
| Public member view includes implementation-status copy about unavailable social features. | Show a useful public-posts empty/error state and moderation action. Do not add follow/direct-message controls without supported behaviour. |

## Proposed screens

- Own profile: existing avatar/name/username/bio, Edit profile, private stats,
  Recent entries, Achievements, Saved articles and public-profile preview.
- Community Posts: title, search, Posts/Groups, one creation action, topic filters,
  readable posts, explicit moderation, reactions and guideline access.
- Community Groups: real group discovery/join status using existing routes;
  membership counts only when returned by the server.
- Public member profile: supplied public identity and non-anonymous public posts;
  block/report controls; no personal wellness activity or fabricated bio.

Open `activity-provider-implemented/index.html` to review light/dark and large-text
previews. Prototype names, profile statistics, groups, posts and engagement counts
are synthetic. Controls are visual examples; none publishes posts, edits accounts,
joins groups or changes moderation settings.

Implementation follows design approval. It must preserve edit-profile validation,
avatar assets, existing achieved milestones, account-scoped storage, consent,
anonymous-post boundaries, pending/offline mutations, filtering, pagination,
report/block rules and current route contracts. The public preview may use only
identity fields available through approved public data, not the private profile API.
