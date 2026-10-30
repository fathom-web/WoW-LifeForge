# Quality plan

## Automated tests

`lua5.4 tests/run.lua` or `texlua tests/run.lua` (60 headless regression/smoke tests) exercises:
- First-run DB initialization and default choices.
- Play sessions, active vs AFK and per-zone time; level and gold dedup.
- Goals, memories, editable notes, future unlocks.
- Multi-realm/character totals and retirement.
- Companion overlap, mute and deletion.
- LF2 backup roundtrip, multi-part out-of-order imports, checksums, duplicates and corrupt data.
- Strict schema validation and alpha-v1 schema migration.
- Explicit import preview/confirmation, non-additive safe merge and staged restore.
- Rapid `/reload` session continuation and combat-deferred notices.

`python3 tests/check_manifest.py` verifies every TOC entry exists.

## Must test **inside WoW Forever** after launch

1. Startup with no SavedVariables; visible minimap button and commands.
2. `/reload`, logout/login, full game quit/restart: SavedVariables persisted.
3. Two Horde alts + one other realm; active/account/realm totals correct.
4. Level-ups, money gains/spending, travel, AFK, group join/leave, raid conversion.
5. Combat while a roster changes, while warnings queue, while UI opens/closes.
6. Backup 1, 10 and 100+ parts: in-game copy/paste, character preview, reload activation.
7. Restore a copy of a v1 alpha DB and verify non-destructive migration.
8. Corrupted backup must not mutate live data.
9. Performance: 1k, 10k, 50k events using synthetic fixtures; cap and resource usage.
10. Localization, UI scaling, different resolutions, combat lockdown and accessibility.
11. Memory/companion deletion reflected everywhere.
12. A WoW client version/API change must not silently enable an incompatible feature.

## Release gate

- All tests pass in GitHub CI.
- No UI Lua errors or forbidden API calls in current Forever build.
- Manual recovery from backup demonstrated across WoW restart.
- All `FEATURE_MATRIX` v1.0 acceptance items completed.
- Source and distribution policy confirmed and CurseForge metadata prepared.

## Build 4 additional tests (pre-launch)

- [x] Feb 2028 leap-year 42-cell layout and day alignment
- [x] Calendar day aggregation and milestone flags
- [x] Zone atlas aggregation between alts on the same realm
- [x] Museum solely from favorited recorded notes/events
- [x] Monthly Wrapped excludes guessed monthly companion/zone-hours
- [x] Existing schema-v2 and LF2 backup survives new favorites/daily data
- [x] Native rich-panel construction/render with mocked frames
- [x] All existing 38 tests retained
- [ ] Render all four new views in real Forever client at common resolutions and UI scales
- [ ] Verify date/time and event behavior against live WoW API
- [ ] Profile multiple years of actual SavedVariables history
- [ ] Test reinstallation, update, split backups and real-client recovery
- [ ] Verify map source/API before implementing real coordinate map


## Build 5 additional checks (pre-launch)

- [x] 60/60 headless Lua regression tests, including goal/note/letter management, retirement, data health, prune, quick bookmark and 16-tab mocked UI
- [x] 22/22 manifest entries
- [x] `tests/stress.lua` synthetic 3k-event large-save LF2 export/import preview
- [ ] In-game Forever tests and visual/manual acceptance (see `API_VALIDATION.md`)
