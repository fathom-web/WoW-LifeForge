# LifeForge 0.3.0-alpha — Build 2 UI delivery

**Status:** headless tested, NOT validated in a live WoW Forever client and NOT suitable for public CurseForge publication.

## Delivered

- Maintained exactly one in-game addon folder, `LifeForge/`, with a tab-driven **hybrid dark fantasy + gold chronicle design**.
- 16 pages: Overview, Characters, Chronicle, Timeline, Statistics, Companions, Goals, Legacy Vault, Museum, Azeroth, Calendar, Time Capsules, Wrapped, Guild Legacy, Records and Settings.
- All metrics and history views read **real local SavedVariables**. Data that cannot yet be collected is described as unavailable, not fabricated.
- Reused nine row frames with paging (avoids creating thousands of frames when the archive grows); timeline and vault search use literal case-insensitive matching.
- Browsing local alt profiles through character/realm/account views **without changing the active character tracker**.
- Memory creation, editing and note-favoriting (right-click on a note); timeline event favorites; level-goal creation, granular notification toggles, privacy switches, and observed-companion erasure with explicit confirmation.
- In-game scale control (85/100/115%), minimap visibility, existing full LF2 export/import screen preserved.
- 23 headless regression tests covering original data engine + newly introduced view models, and a UI mock smoke-test; manifest check.

## Known limits

- Visual theme is a first pass using built-in Blizzard textures rather than custom polished illustrations; the promotional artwork is conceptual, **not an actual in-game capture**.
- Guild tracking, calendar grid, real cartographic rendering, curated records, archive comparisons, group formations, bond milestones, automatic trophy selection and deluxe Wrapped screens still require implementation.
- Vault dialogs support single-line summary/description fields in this build; a proper multi-line rich memory editor, future-letter authoring, full interactive goal editor and detailed privacy controls are slated for the next build.
- Backups maintain the Build 1 LF2 protocol. Live-client load compatibility and large-dataset throughput remain unverified.
- The view models currently build in-memory lists before paging; large-archive performance testing and incremental filtering are required before 1.0.
- The default UI is 940x645; scaling and window placement should be tested on different resolutions.

## Quick manual test once Forever is available

1. Install just the `LifeForge/` folder and type `/lf`.
2. Navigate all 16 tabs and choose Account in the scope selector.
3. Create a note; locate it under Vault, right-click to favorite, and confirm it appears under Museum.
4. Create a level goal, toggle notifications and change UI scale in Settings.
5. Export LF2 backup; import with Preview Merge; cancel and verify no data is modified. Test Replace with a disposable sample character only and keep a closed-client copy of SavedVariables.
6. Reload, relog, change characters and inspect preservation of data. Monitor Lua errors and framerate.

## GitHub workflow

Upload the **source ZIP contents** to a single GitHub repository. The `.github/workflows` test runs on push/PR; do not use repository Releases or GitHub Pages for addon distribution. Publish binaries **only via CurseForge** after v1.0 feature and live-client acceptance gates.
