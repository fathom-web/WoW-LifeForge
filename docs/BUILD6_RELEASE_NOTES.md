# Build 6 — 0.7.0-alpha — 30 October 2026

## Completed this build

- Future Self Letters: level, accumulated active **hours**, and user-local calendar dates. The same parser drives the in-game editor and `/lf letter` slash command. Strict validation rejects impossible dates and targets already reached. Timestamp-date letters from earlier alphas remain readable/unlockable.
- Memory and letter editor: a taller dialog with multi-line text input. The live client still needs keyboard, focus, scroll and resolution testing.
- Family Legacy: earliest registered character, most-played hero, registered realm count, archived characters, combined levels and recorded memories. All figures use only locally saved characters.
- Backup import progress: accurate number of received LF2 chunks. Preview, explicit confirmation, schema validation, non-executable decode and staged restore remain unchanged.
- Lockdown guard for `/lf notifications` while a restore is staged or data is read-only.
- Version bumped to 0.7.0-alpha; packaging filename updated. Schema remains 2, so previous LF2 exports remain compatible.

## Automated test evidence

- 64/64 headless Lua regression tests; additional leap-day, invalid dates, legacy date-format, family scope and restore-command tests.
- Synthetically loaded 3,000 events, 500 notes, 500 sessions, 600 group records, 100 companions, 360 days; LF2 export/import roundtrip survived in 320 pieces.
- `tests/check_manifest.py` verifies 22 manifest-referenced addon files.
- These tests are NOT client FPS measurements or evidence that the WoW Forever UI/API works.

## Open release gates

- WoW Forever game-client compatibility: official interface number, SavedVariables persistence, 16 views and GUI scaling, group/guild events, AFK/clock handling and combat restrictions.
- Large LF2 backup remains limited in-game and may be awkward with hundreds of parts. For very large saves, copy the original SavedVariables file while WoW is closed.
- Azeroth Footprint currently offers an honest zone atlas, not a map with GPS-style pins; requires validated API map IDs/coordinates.
- English is currently the only supported language; full UI text extraction/translated strings and accessibility QA remain.
- Public-source license selection and CurseForge author/release setup are not done.

**Publishing rule:** source to GitHub; CurseForge only after client tests and acceptance. Novyx Forge marketing only.
