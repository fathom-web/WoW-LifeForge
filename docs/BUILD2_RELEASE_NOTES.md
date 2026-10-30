# LifeForge Build 2 — 0.3.0-alpha

**Built 29 October 2026. Not tested in the live World of Warcraft: Forever client.**

## What this build delivers

1. A 940 x 645px moveable, scalable in-game window using Blizzard-provided textures, bronze/gold accents, a fantasy sidebar and 16 tab destinations.
2. Current-character, current-realm and account-wide summaries; saved-character switching, including selecting an alt from a different realm.
3. Read-only data views for statistics, companions, calendar, monthly time capsules, zone footprint, personal records and current Lifetime Wrapped summary.
4. Search and paging for timelines, chronicle and notes; direct editor for creating/editing memories, note favorites and event favorites, plus a create-level-goal dialog.
5. Settings interactions for tracking, companion tracking, each notification category, UI scale and minimap visibility, and a pathway to LF2 Backup & Restore.
6. ESC-to-close registration for main window, edit dialog and backup window where supported by the WoW client.
7. Regression tests for all 16 view models, UI creation using mocked WoW frames, search matching, correctly scoped alt views and favorite counts.

## Functional maturity — do not confuse panels with finished features

| Area | In 0.3.0-alpha | Still needed before 1.0 |
|---|---|---|
| Overview and character views | Functional displays and filters | Portrait treatment and full fantasy polish, retire/edit UI |
| Chronicle & Timeline | Events and search/pagination/favorites | Narrative chapters, richer events, complete filters |
| Statistics & Companions | Readable tracked statistics | Detailed visualization, group formation/bonds/reunions |
| Goals | Live list, level-goal creation | All goal types and goal lifecycle UI |
| Vault & Museum | Notes, favorites, text editor | Full museum displays, letters authoring and unlock UX |
| Azeroth | Zone list with observed times | World map overlays and zone chapter navigation |
| Calendar | Day-by-day activity list | Visual date grid and event drill-down |
| Capsules & Wrapped | Monthly snapshot list and running summary | Then-vs-now, full monthly/seasonal Wrapped, screenshots |
| Guild & Records | Transparent placeholders / known data | Genuine guild history and full records engine |
| Backup & Restore | Existing secure LF2 round-trip engine and dialog | Verify very large archive and real-client usability |
| Privacy & Settings | Toggles and local storage | Full data erasure/pruning UI and privacy workflow |

## Validation

- Run `texlua tests/run.lua` (or `lua5.4 tests/run.lua`) from the repository root.
- Run `python3 tests/check_manifest.py` to validate all manifest entries.
- Test install/loading, no Lua errors, minimap, slash commands, frames, editor, party, multiple realms, save/logout/reload, backup import and scaling in **the actual Forever release client**.

## Guardrails

- No external network, tracking or advertising code.
- Novyx Forge is a marketing brand only; GitHub is source storage; CurseForge will be the only public distribution/updates channel.
- No unsupported estimates of historical playtime or companions. Social overlap indicates time observed in the same party/raid, not necessarily actual joint combat.
- Public 1.0 is blocked until the complete `FEATURE_MATRIX.md` acceptance scope is implemented and verified.
