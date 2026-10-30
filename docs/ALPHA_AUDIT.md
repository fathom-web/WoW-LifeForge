# Audit of initial 0.1.0-alpha
Date: 2026-10-29. Original files preserved in `legacy-alpha/` for review only.

| Area | Original 0.1.0 | Build 1 response |
|---|---|---|
| Database | schema 1; creates character keyed by raw realm:name; no migrations | schema 2; supports normalized realm with alpha alias migration, preserved old database snapshot |
| Character scope | realm and account totals | same plus dedicated character sections and ID-based events |
| Sessions | counted every Boot; elapsed OnUpdate; reload may double sessions | resume logical session after rapid reload/relogin, 5-second aggregation, AFK separated |
| Money & level | basic change/level detection | positive/negative money deltas, level dedup, daily summary |
| Events | event list with simple favorite bound | typed event records, bounded nonfavorite removal, no fabricated history |
| Social | not implemented | opt-in/out local roster observations, group-time counts, per-player erase |
| Backup | `LF1` in one edit box; direct replacement after simple checks | `LF2` chunked parts, strict parser, shape validation, preview/confirmation, account replacement or non-destructive merge |
| Recovery | direct SavedVariables assignment; no rollback safeguards | staged validated replacement, explicit reload; filesystem copy always recommended |
| Tests | none | Lua unit regression tests, manifest check, GitHub CI |
| UI | basic tabs with recreating children | fixed-layout developer UI with stable elements and dedicated Backup screen |
| Locale | inline English strings | separate English localization table scaffold |

## Remaining known issues / release blockers

- Real Forever client API behavior cannot be verified in this environment; beta interface ID may change after launch.
- New sessions are considered the same logical play session if rejoining within 120 seconds, even when this was a fast logout/login; this is an explicit heuristic.
- Social seconds indicate **group overlap**, not the exact time both users actively played or were in the same zone. The contact need not run LifeForge.
- On a group change *during combat*, membership is conservatively paused until safe roster inspection. If the client prevents reading roster entirely, social tracking remains empty.
- In-game backup UX is manual/chunked and could be laborious for multi-year databases; for very large data prefer direct SavedVariables filesystem copies.
- Imported backup checksum prevents accidental alteration, **not** a malicious person tampering with a backup; only import from trusted sources.
- Merge does not combine stats for the same character; it retains the local version to prevent overcounting. Per-character conflict UI is future work.
- UI is intentionally a developer shell, not finished Hybrid artwork.
