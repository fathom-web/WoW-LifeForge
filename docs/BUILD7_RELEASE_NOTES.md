# LifeForge Build 7 — 0.8.0-alpha (30 Oct 2026)

## What's implemented
- Tier milestones: 25 tracked thresholds over active hours, zone discovery, notes, observed companions and levels gained; replay-safe persisted unlock map, no historical claims.
- Azeroth Footprint: native 8-row zone atlas pagination for any number of recorded zones. Optional map ID and last verified position are saved only when client `C_Map` APIs return finite, valid evidence; no coordinates are inferred or transmitted.
- Core English locale dictionary with fallback and selected shared UI labels translated through `LF:L`. **Full localization remains unfinished**.
- Updated manifest, versioned install package and automated packaging workflow.
- Tests added for idempotent milestones, absent/secret map API, valid positions and safe locale fallback.

## Explicitly incomplete for public release
- Real world-map overlay/pins: pending Forever C_Map API and UI validation.
- Full UI string extraction, accessibility / responsive screen tests.
- Confirm in-game save/reload, combat lockouts, guild/party event behavior, and memory management.
- Source-only GitHub branch is authoritative. GitHub Actions provides version-matched addon ZIP as downloadable CI artifact. CurseForge has **not** been touched.