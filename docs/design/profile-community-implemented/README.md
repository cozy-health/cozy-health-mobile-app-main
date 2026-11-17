# Profile, Community, streaks and achievements

Open [the gallery](index.html) to review actual Flutter screenshots and the approved pop-up design references. All content is synthetic and local. Normal app code does not substitute these fixtures for real records.

The implemented screens are Profile, Community Posts, Groups, public member profile and Achievements (including the dated streak visual). Activity and Provider were implemented in the preceding phase and remain in [their review gallery](../activity-provider-implemented/index.html).

Read [the two-pass pop-up audit and achievement roadmap](../profile-community-popup-audit.md) for the exact five existing achievements, feasible additional types, every modal finding, and proposed implementation requirements. The pop-ups have since been approved and implemented. See [actual modal captures](../approved-popups-implemented/index.html) and [implementation verification](../approved-popups-implemented/README.md).

Verification on development:

- 121 acceptance checks passed across progress calculations, retained/offline/server awards, account-switch isolation, community state, screen/theme render fixtures, Provider records/messages/resources, avatars and voice review.
- Two additional checks passed for hidden Profile preferences/no invented bio and Community post/group search.
- 18 focused Home/quick-action regression checks passed. The final 73-check render run refreshed every capture after contrast corrections and checked small accent-label contrast across all theme combinations. This is 141 distinct checks overall; repeated render runs are not added to that total.
- Flutter analysis: no issues across the 17 changed implementation, proposal and test items.
- 79 gallery capture links verified; inline gallery JavaScript parsed successfully.
- Four existing accents, light/dark appearances, yellow high contrast and narrow 200% text scenarios are represented. Current report/visibility also have large-text render captures for the audit.
- Brand fills and original artwork retain their colors. New small accent text/status glyphs use the existing contrast helper when an accent is too faint on its background.

These are widget/render and source checks. Physical-device accessibility, native keyboard behavior and live development API behavior still require device acceptance. Development remains the only permitted release target. The original review was local; the subsequent approved implementation is committed and pushed separately.

Reproduce the gallery captures with `test/features/ui_review/profile_community_review_test.dart`, then run `node tool/render_profile_review_gallery.cjs`. Files named `popup-*` are proposals; `current-*` are existing modal audit captures. Full-page images use an expanded viewport; normal captures represent a 375-point viewport, and large-text captures use a 320-point viewport.
