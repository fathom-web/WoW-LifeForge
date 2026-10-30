# Build 4 — The Ultimate Experience

**Version:** `0.5.0-alpha`  
**Date:** 29 October 2026  
**Base:** `0.4.0-alpha` with all Build 1–3 modules preserved  
**State:** Headless test passed; **real WoW Forever client untested**

## Delivered

| Feature | New implementation | Grounding / limitation |
|---|---|---|
| Legacy Calendar | Native 7×6 clickable month heatmap; month navigation; real day session, level, event and memory counts; scope aggregation | Uses only locally recorded `daily`, `events`, and `notes`. Activity density is relative to the selected month's peak. |
| Azeroth Footprint | Ranked zone-atlas list with native heat bars and aggregated time | A **zone atlas**, not a cartographic interactive Azeroth world map. No guessed pin positions or travel paths. |
| Memory Museum | Six-card/page native gallery; inspect panel; active-character-only un-favorite action | Only manually favorited notes and favorited real milestone events are displayed. No inferred loot or trophies. |
| Legacy Wrapped | Native four-metric recap plus highlights; all-time and calendar-month selection; native screenshot-friendly presentation | Per-month uses daily activity and timestamped occurrences. Companion-time and zone-duration rankings are *all-time only*. |
| Performance | UI refresh throttled to approximately 15 seconds during passive ticks; user actions immediately refresh | Multi-year runtime/performance profiling still required in a real client. |
| Data compatibility | Kept account schema `2`; `LF2` backup format unchanged; all new reports are derived from existing stored data | Old Build 3 v2 save and LF2 backup compatible by design and headless tests. |
| UI | Existing dark/gold shell preserved; special pages reuse frames | Still alpha visuals, not a pixel-perfect replication of marketing imagery. |

## Source changes

- New `LifeForge/Core/Experience.lua`: pure calendar, atlas, museum, monthly/lifetime Wrapped models.
- New `LifeForge/UI/Experience.lua`: native WoW frames for gallery, heat grid, bars and Wrapped.
- Updated `LifeForge/UI/Main.lua`: show/hide rich pages while preserving existing tabs/scope selectors; correct selected alt realm subtitle.
- Updated `LifeForge/Core/Tracking.lua`: bounded passive UI refresh frequency.
- TOC now references **21** addon files, including the new modules; version set to `0.5.0-alpha`.
- New Build 4 regression tests; 45/45 total.

## Acceptance checks completed outside WoW

- Calendar month layout and leap-year days; 42-cell alignment.
- Per-day summation with actual stored events; month filtering and intensity scale.
- Zone aggregation across characters on the same realm.
- Museum inclusion only for favorited existing data and removal semantics.
- Monthly and all-time Wrapped facts; no synthetic monthly friend or zone-duration claims.
- LF2 import/export retains museum favorites and period data.
- Native panel construction/render smoke test with mocked frame functions.
- Existing 38 test cases retained and passed.
- 21 TOC dependencies exist and package correctly.

## Important limitations / remaining 1.0 work

1. **Not live-tested:** no claim of working in released Forever. Interface-ID, exact API behavior, protected frames and texture rendering need hands-on verification.
2. **Real Azeroth map:** only a zone atlas is implemented. An actual accurate map with map IDs/coordinates needs a verified Forever mapping API and data model; do not synthesize coordinates.
3. **Wrapped sharing:** screenshot workflow only. No automatic artwork export, upload or account synchronization.
4. **Museum:** note and event favorites work; real loot/achievements are not inferred; offline alt exhibits are browsable read-only.
5. **Performance:** model functions iterate bounded collections; a realistic multi-year saved dataset must be stress-tested; any true giant archive may require archival policies.
6. **Other v1.0 modules:** richer Chronicle visuals, full goal management, calendar event drill-down, character retirement controls, complete localization extraction, settings/data-health UX and accessibility remain unfinished.
7. **Release:** no GitHub push, no CurseForge upload or publication.

**Release criterion:** 1.0 only after all product scope acceptance tests and a genuine WoW Forever client validation pass.
