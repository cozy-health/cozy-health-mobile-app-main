# Profile, Community and progress review

Development only. The Profile, Community feed, Groups, public member layouts and pop-up family are approved and implemented. See [actual modal captures](approved-popups-implemented/index.html) and [implementation notes](approved-popups-implemented/README.md). The findings below preserve the original two-pass audit and its proposed fixes; the approved fixes are now applied. All screenshot content is synthetic.

## Implemented

- Profile uses the real profile/avatar, honors username/stat visibility preferences, and removes the invented fallback bio and placeholder streak. Recent entries, achievements and saved articles use existing destinations. Public preview is available to signed-in accounts and never includes journals or check-ins.
- Community has one create action, a full-width search entry, labeled notification/options controls, stable topic selection and large touch targets. Post reactions wrap when text grows. Original uploaded images remain contained, not cropped. Anonymous authors have no member-profile action.
- Groups retain real server counts, membership and paginated loading. The duplicated +1 count is removed. Membership actions disable while saving; account changes clear old groups and pending controls. No patient-side group creation endpoint is invented.
- Public profiles show only non-anonymous public posts. A self profile has no block action. No follow, private message, private bio or health-stat feature is implied.
- Search now filters public posts and group metadata fetched from existing paginated endpoints. It has loading, empty and retry states; it does not introduce an unsupported people-search endpoint. Group membership remains in Community → Groups.
- Home’s streak shortcut and Profile lead to real progress: account-calendar day grouping, unique check-in days, a dated last-seven-days visual, current/best streaks, and five earned/pending milestone cards. A streak through yesterday remains current until today ends. Draft journals and future records do not earn new milestones. Server earned dates take precedence, and cached awards remain after a break or source-record removal. Account changes invalidate pending achievement responses.

## Achievement feasibility

The server already supports these five; this phase completes their visuals and client data handling rather than inventing a new reward scheme:

| Existing milestone | Exact criterion |
| --- | --- |
| First check-in | One saved mood check-in, regardless of mood or intensity |
| First journal entry | One saved, non-draft journal entry |
| Three steady days | Check-ins on 3 consecutive account-calendar days |
| A week of checking in | Check-ins on 7 consecutive account-calendar days |
| Thirty days of checking in | Check-ins on 30 consecutive account-calendar days |

Recommended extensions, **not implemented without a separately agreed catalog and backend change**:

| Priority | Proposed milestone | Feasible evidence / work |
| --- | --- | --- |
| 1 | 10, 25 and 50 check-in days | Distinct saved days, not repeated taps. Extend server retention and the shared client catalog, then reconcile offline awards. No consecutive-day requirement. |
| 1 | 3, 7 and 15 writing days | Distinct days with completed non-draft journals; content and word count do not affect rewards. Use account timezone and retained server awards. |
| 2 | First completed assessment | Saved, validated QuizAttempt with completedAt; never use score, severity or repeated assessment volume. Requires server award support. |
| 2 | First saved resource | Persisted saved article/resource, not a view or a guessed “read” event. Agree which saved resource types qualify and retain its award server-side. |
| Later | First completed breathing session | Add a reliable completion record/event first. Opening a breathing screen is insufficient evidence. |

Keep achievements private and optional. Do not reward particular moods, disclosure of health records, crisis use, higher assessment scores or public posting frequency. No public leaderboards, punitive lost-streak copy or automatic celebration pop-ups are added. Existing notification preferences remain unchanged.

## Pop-up audit — pass 1: inventory and interaction

“Four pages” is treated as Activity, Provider, Profile and Community. Related Home quick actions/streaks are included as a cross-check. This is not an audit of every unrelated Settings screen.

| Entry / source | Current finding | Recommendation for approval |
| --- | --- | --- |
| Activity (`activity_screens.dart`) | Period and chart details are inline. No extra app-owned period modal needs rebuilding. Article sharing uses the system share UI. | Keep inline controls and native share UI. Do not introduce a new alert for routine progress. |
| Provider record categories (`provider_hub_screen.dart`) | Anchored menu respects consent availability. | Keep anchored behavior and disabled categories; use consistent 48-point rows and accessible category labels. |
| Provider chooser (same file) | Scrollable list supports selection, but lacks a contextual heading and explicit Close. | Proposed **Choose a provider** sheet: title, close, current-conversation check, named choices and cancellation. Clear selected draft records when conversation changes as today. |
| Record picker (`provider_record_picker.dart`) | Already has close, selection count, same-sheet pagination, empty/retry states and account/thread invalidation. | Keep those behaviors. Align outer sheet safe area, title spacing and shape with the proposed family. Do not replace it with the simple record-preview example. |
| Selected record preview (`provider_hub_screen.dart`) | Scrollable AlertDialog is safe for long records, but a review task uses different chrome from the picker. | Proposed **Record preview** sheet with clear Done and scrollable actual consent-filtered content. Preserve all real fields, privacy masking and account invalidation; sample copy in the preview is not a data contract. |
| Provider revoke (`provider_screen.dart`) | Clear, scrollable confirmation explains loss of access and has Cancel/Revoke actions. | Retain confirmation and exact consequences; align with the destructive-confirmation family, with neutral cancel and a clearly destructive final action. |
| Provider email correction (same file) | Existing form validates and scrolls; explains invitation replacement. | Keep validation and explanation. Apply the form-sheet treatment if approved; keyboard must not hide input, error or action. No second redundant confirmation. |
| Provider voice (`core/audio/voice_recorder_popup.dart`) | Already anchored, themed, scroll-constrained and explicit about recording/review. | Existing behavior can remain. Optional visual alignment is illustrated by **Voice message**; preserve permissions, stop-on-background, retry and recording cleanup. This proposal is not a replacement recording implementation. |
| Profile avatar (`avatar_picker_sheet.dart`) | Already has SafeArea, keyboard padding, scrolling, close, selected-avatar semantics, guest/account guards and a separate remove confirmation. | Keep the character grid, preview, save and recovery flows. **Profile photo** is an optional entry-menu visual refinement; it does not remove the 24 characters or change their art. Remove-photo confirmation follows the destructive family. |
| Community post actions (`post_actions.dart`) | Existing default sheet has no title/close. Block executes immediately from the menu, while public member block asks for confirmation. | Proposed **Post options** sheet with visible heading, close and grouped actions. Route Block to the same confirmation as member profile. Self-block/anonymous-block safeguards are already retained/fixed; layout and the new confirmation step await approval. |
| Community report (`report_sheet.dart`) | Already scrolls, offsets for keyboard, disables invalid/duplicate submission and retains retry errors. Selected reason is visually indicated but lacks a selected-state semantic; outer modal lacks explicit safe-area configuration. | Proposed **Report a post** form sheet: descriptive heading, close, reason semantics, bounded scroll content, notes label, keyboard-safe action and retry status. Keep exact supported reasons, server submission and success behavior. |
| Community visibility (`visibility_sheet.dart`) | Public/Anonymous work in normal mode. Followers appears only in demo. Sheet scrolls but lacks explicit close and selected-state semantics. | Proposed **Post visibility** sheet with explained choices, stable check mark and Close/Cancel. Only Public and Anonymous in normal mode. Keep the moderator visibility notice. |
| Member block (`user_profile_screen.dart`) | Clear existing confirmation; self-block is excluded. | Proposed **Block this member?** visual family with consequences, a neutral cancellation action and explicit destructive action. Do not silently block on dismissal. |
| Community publishing guidelines (`create_post_screen.dart`) | Actual published document is fetched and presented in a scrollable dialog with Cancel / Agree and post. | Preserve the full server document, version and acceptance behavior. Apply the long-form sheet family if approved; no fabricated guidelines or prechecked agreement. |
| Home shared quick actions (`quick_actions_sheet.dart`) | Already themed, bounded, scrollable, safe-area aware and explicitly dismissible. | Keep. Its action pattern provides a useful basis for the rest. |

The demo-only direct-messages action menu is outside the normal member-profile flow. This phase does not enable unsupported community DMs or follower visibility. The Home introductory tour is onboarding, not a recurring progress pop-up; no new achievement alert is introduced.

## Pop-up audit — pass 2: visual and state requirements

Review images include light and dark treatments and narrow, 200% text/high-contrast scenarios. Existing report and visibility widgets also receive large-text render checks; Provider picker, avatar and voice retain their existing focused regression checks. Source review covers the remaining dialogs. These checks do **not** establish physical-device VoiceOver/TalkBack, native keyboard or live development API behavior.

The approved modal family uses the following implementation requirements:

1. Match canvas/surface, on-surface text, active accent and outline colors to each user theme. Destructive actions use the semantic error color. Original avatar/artwork colors stay intact. Keep brand fills while using the existing contrast helper for small accent text and state glyphs; text must remain readable even with yellow on a light surface or blue on a dark surface.
2. Use a shared title/close row, 48×48 interactive targets, neutral dismissal and consistent corner/spacing tokens. Selection is announced and never depends on color alone.
3. Constrain height to the safe available viewport. Let content scroll with large text, landscape and keyboard; keep final actions reachable. Do not use a fixed-size Column for long options or legal content.
4. Preserve edits and display an inline live-region error on failure. Disable duplicate requests while saving; close only after confirmed success. Dismiss/cancel never commits a choice or destroys data.
5. Clear private previews when account/conversation changes, including an already-open record-preview sheet. Scope every asynchronous callback to the original account and conversation. Preserve consent filtering and offline behavior.
6. Use quiet inline confirmation for routine saves. Reserve interruptive confirmations for block/revoke/remove/discard actions or necessary consent. Respect reduced-motion settings and keep feedback immediate.

Design rationale follows Apple’s [alerts](https://developer.apple.com/design/human-interface-guidelines/alerts), [feedback](https://developer.apple.com/design/human-interface-guidelines/feedback) and [progress indicators](https://developer.apple.com/design/human-interface-guidelines/progress-indicators) guidance, applied through CozyHealth’s existing custom Flutter design system.

## Review scope

The gallery separates **implemented screen captures** from **approved pop-up design references**. Theme examples use all four existing accents; yellow examples also enable high contrast. Full-page captures expand the viewport for content review; normal viewport captures show actual scrolling constraints. Community captures reproduce the bottom navigation and floating controls so their reserved clearance is visible. Only development commits and pushes are authorized; production remains untouched.
