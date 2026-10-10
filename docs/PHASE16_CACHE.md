# Phase 16 saved-content integration

SavedArticle now persists slug, category, read time and optional article body in the encrypted Hive cache. Existing field indexes and type ID remain stable; legacy six-field records load with missing metadata as null. Regression tests cover encrypted reopen and legacy upgrades.

ContentRepository uses canonical article bookmark paths for direct save/unsave, refreshes saved content after writes, removes unsaved local records and bounds server pagination. Five unused activity constants were removed; deferred payment and assistant repository methods remain.

Validation: full Flutter analysis has no issues; full mobile suite passes 510 tests. No screen layout changed in this batch; crisis and quick actions remain independent overlays.

The backend handoff is cozy-health-api-main/docs/PHASE16_ENDPOINTS.md. Real feed/search and body rendering remain Phase 20. Approved data, image moderation and live deployment checks remain open; Phase 16 is not closed.
