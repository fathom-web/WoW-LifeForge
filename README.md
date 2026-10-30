# LifeForge Complete — Build 7 (`0.8.0-alpha`)

**Your Character. Your Journey. Your Legend.**

One standalone **in-game addon** for World of Warcraft: Forever. Build 7 keeps the entire 31-area public-v1.0 product scope and expands the actual functions behind the existing 16-tab dark/gold Hybrid interface.

> **Unverified client alpha — 30 October 2026. NOT game-client validated.** Interface `16001` is provisional until checked against the final Forever release. This is not a public `1.0` and must not be described as complete, CurseForge-approved, or proven to work in WoW.

## Development and distribution

1. **One product:** LifeForge, native WoW Lua UI; no companion app, no website account.
2. **Feature work:** Developed here in the ChatGPT project.
3. **GitHub:** Source code, changes, tests and history. This source ZIP is repository-ready; **nothing was pushed**.
4. **CurseForge:** The *only* public distribution/update service, after in-client acceptance.
5. **Novyx Forge:** Only brand/marketing/showcase, not a download/update host.

## Build 7 — Pre-launch hardening

- **Milestones:** 25 meaningful, replay-safe, recorded-time tiers across active play, discovered zones, memories, observed companions and level-ups.
- **Atlas:** native paginated zone atlas; guarded, opt-in-by-availability `C_Map` evidence may attach genuine map IDs and observed positions. No guesses, map overlays or off-game storage.
- **UI and locale:** English dictionary with safe fallback, selected headings extracted, 8-row atlas pagination with page controls.
- **Packaging:** the authoritative install ZIP is built by GitHub Actions on each commit, available in the workflow's artifacts; `dist/` is generated, not source. No CurseForge publication.
- **Testing:** 67 headless Lua tests + stress archive backup/restore; real client validation remains required.

## What Build 6 adds

- **Future Self Letters:** all three trigger types in-game: `level:60`, `hours:100`, `date:2027-01-01`. Date input is calendar-validated, and old timestamp-based letters remain readable. Multiline memory/letter editor now has extra space.
- **Family Legacy:** shows the earliest tracked character, most-played hero, combined level totals, realms, archived count, and real saved memories (only for characters actually logged in).
- **Backup UX:** number of imported parts displayed accurately; existing safe preview, merge, replace and confirmation behavior retained.
- **Safety:** notification command respects a staged restore/read-only database. Existing data schema 2 remains unchanged.
- **Tests:** 64 headless Lua tests; synthetic large history + backup roundtrip passes.

## What Build 5 added

- **Legacy Goals:** All six supported types can be created and edited in-game (level, tracked time in seconds, zones, notes, companions, gold in copper). Right-click removal is confirmation gated; edited presets remain edited across relogins.
- **Character Retirement:** Right-click a character in the Characters tab to archive or restore it. Records are not deleted and archived characters remain browsable.
- **Legacy Vault:** Edit note title, body and category. Right-click to toggle favorite; Shift + right-click and confirm to delete. Right-click Future Self Letters to delete with confirmation.
- **Quick Bookmark:** ` /lf bookmark ` or `+ BOOKMARK` creates and favorites a memory with actual current character, tracked zone, date and observed party.
- **Guild Memories:** Save a note in the Guild tab with the `Guild Memory` category and guild name captured at creation (when available). Guild history remains observed rather than backfilled.
- **Session Intelligence:** Mean active duration for completed sessions, active/AFK current session, historical records; bounded detail storage retains aggregate totals.
- **Personal Firsts & Chronicle:** Verifiable first zone, note and tracked moment. Monthly chapters use factual counts for levels, explored zones, companions, goals and memories; no invented encounters.
- **Data Health & Retention:** ` /lf diagnostics ` validates the database and reports available API functions and client interface. An explicitly confirmed cleanup discards only raw session/group detail older than 365 days, never totals, calendar days, notes, chapters or snapshots.
- **First-login explanation:** New players are told that data is local and cannot reconstruct pre-installation history.
- **Compatibility:** Existing schema 2 and LF2 backup format remain unchanged. Legacy v1 migration continues to be supported. An API report is a *probe*, not proof of real-client compatibility.

## What remains from Builds 1–4

Character, realm and account tracking; session/AFK/level/gold/zone data; timeline, Chronicle, goals, notes, letters and favorites; Companions, Legendary Bonds, recurring parties, observed guild changes, The Last Adventure; Time Capsules and Then vs Now; Calendar, zone-atlas Footprint, Memory Museum and Wrapped; minimap button, slash commands, settings, and LF2 validated chunked Backup & Restore.

## Run tests

```bash
texlua tests/run.lua                # or lua5.4 tests/run.lua
texlua tests/stress.lua             # synthetic large-save and LF2 roundtrip smoke
python3 tests/check_manifest.py    # manifest file resolution
python3 scripts/package.py         # build addon-only zip in dist/
```

**Result at build time:** 67/67 headless Lua tests, 22/22 manifest entries, and a synthetic history/back-up test (3,000 events, 500 notes, 500 sessions, 600 group records, 100 companions, 360 days). These do **not** prove visual appearance, FPS, API event behavior, `/reload` persistence, or any other actual game-client operation.

## Install for development testing once Forever is available

Extract the *addon-only ZIP* to give this layout:

```text
World of Warcraft/<Forever installation>/Interface/AddOns/LifeForge/LifeForge.toc
```

The actual client folder name should be verified in your installation. Use `/lifeforge`, `/lf`, `/lf bookmark`, `/lf settings`, `/lf diagnostics`. Before upgrading or restoring anything, fully close WoW and back up the `WTF/Account/.../SavedVariables/LifeForge.lua` file from the correct installation/account. SavedVariables are local to that installation, **not cloud synced**.

## Important constraints

- **Azeroth Footprint is currently a zone atlas**, not a coordinate-accurate interactive world map; wait for verified Forever map APIs/map IDs, then implement a map without fabricated coordinates.
- **Large in-game LF2 backups may require many copied parts.** For large archives, prefer the original SavedVariables file, backed up with WoW closed. A large historical save could exceed the 6 MB in-game export cap.
- Character metadata and group information from game APIs remain provisional until tested in the actual release client.
- Client textures, protected actions/combat behavior, scaling and UI accessibility are not certified by mocked-frame tests.
- English UI is supported; a localization scaffold exists but full string extraction and translations are not complete.
- This repository has **no chosen public source-code license**. Choose the license and verify Blizzard/CurseForge distribution terms before going public.

## Details

- [`docs/FEATURE_MATRIX.md`](docs/FEATURE_MATRIX.md) — all 31 v1.0 areas with honest implementation status
- [`docs/BUILD5_RELEASE_NOTES.md`](docs/BUILD5_RELEASE_NOTES.md) — exact Build 5 changes
- [`docs/API_VALIDATION.md`](docs/API_VALIDATION.md) — specific in-client test gates
- [`docs/TEST_PLAN.md`](docs/TEST_PLAN.md) — regression and release criteria
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — existing versioned local data model