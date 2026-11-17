# Approved pop-up implementation

Development only. The previously approved modal family is now wired into normal app flows. [Open the actual screenshots](index.html).

Implemented:

- Shared `WellnessSheet`, choice rows and destructive confirmations, using existing theme tokens, branded pressables, readable control ink, explicit Close, safe-area/keyboard insets and bounded scrolling.
- Post options, report form and visibility choices. Report failure retains the reason and notes; pending submission disables duplicate sends and dismissal. Normal mode exposes Public/Anonymous only. Account changes clear an unfinished report.
- Post and public-member blocking share the same explicit confirmation. Cancel, Close and backdrop dismissal never block. Self/anonymous block actions stay excluded.
- Provider chooser and record picker use consistent sheets. Same-sheet pagination, selection limits, consent masking and retry remain intact. An already-open record preview clears when its original account/conversation changes.
- Provider revoke, invitation-email correction and full published community guidelines use the approved confirmation/form family. Existing validation, document content/version and consent submission remain authoritative. Email correction retains its cancel-before-reinvite behavior and sharing choices.
- Profile photo options retain all 24 original characters, photo recovery/cropping, preview, guest guards and account-change cleanup. Removing a photo uses the shared confirmation.
- Voice recording retains its anchored card and lifecycle/permission/upload/cleanup behavior. Stop and Send stay visible while details scroll; failed sends retain the recording for retry. The card remains compact.

The original five achievements remain supported. Additional achievement categories in the roadmap still require agreed criteria and server award support; this UI approval does not fabricate new server awards.

Verification:

- Final acceptance in an isolated staged checkout: **279 checks passed**, covering the approved Activity/Provider, Profile/Community, streak/achievement and pop-up changes without unrelated workspace edits.
- 107 pop-up behavior/render regression checks passed, including Provider messaging/consent/invitations, avatars on Android/iOS variants, recorder behavior and real modal theme/layout checks.
- A separate real-provider flow verifies chooser cancellation and account-change clearing of an open private record preview.
- Four accents × light/dark captures for reporting, visibility, photo options and record selection, plus narrow 200% high contrast, landscape and a keyboard-reachability check.
- Scoped Flutter analysis is clean. These checks use synthetic fixtures, not live account data or native device acceptance.

Reproduce captures with `test/features/ui_review/approved_popups_test.dart` and the provider-preview case in `test/features/settings/provider_hub_test.dart`. Then run `node tool/render_approved_popup_gallery.cjs`. Source design references remain available in the preceding review gallery; they are clearly labeled as approved references rather than unimplemented proposals.
