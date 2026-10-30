# WoW Forever API and compatibility validation — not yet performed in the released client

## Evidence available before launch (29 October 2026)

- Blizzard announced Forever's global launch on **4 November 2026**. Public beta material reports Interface `16001`.
- Public beta observations describe a Mainline-based Lua API with Midnight-era secret/restricted combat data; old Classic globals may be missing.
- The addon currently declares `## Interface: 16001`, uses `pcall` to register optional events, and avoids dynamic combat decision helpers.
- References: [Blizzard announcement](https://worldofwarcraft.blizzard.com/en-us/news/24302093/) and [Forever addon kit beta observations](https://github.com/Thunderz96/forever-addon-kit).
- These sources **do not** prove LifeForge itself loads successfully. No client has been tested.

## Prioritized first live-client tests

| Priority | Component | Actual test | Required proof |
|---|---|---|---|
| P0 | TOC, bootstrap | Clean install, `/lf`, `/reload`, logout, game restart | No Lua errors; saved stats persist |
| P0 | Identity and realms | Login 2 chars on same realm + 1 on another | No collisions, correct totals |
| P0 | Tracking | Zone changes, leveling, money, AFK | Counts match observed events |
| P0 | Backup | Export, import preview, cancel, confirm, `/reload` | No lost histories and no unconfirmed overwrite |
| P0 | UI/combat | Open/close/reposition/scale tabs during combat | No protected action errors or blocked input |
| P1 | Companions | Party, raid, join/leave, alt, AFK, muted/forgotten | Only observed overlap; privacy respected |
| P1 | Guild | Join/leave, relog, guild event availability | No phantom guild events |
| P1 | Storage | 1k/10k+ events, 1/10/100 LF2 parts | Bounds and graceful fallback |
| P1 | Calendar & Wrapped | Over midnight/month boundary | Accurate dates and scoped totals |
| P1 | Future letters | Reach level/time/date thresholds | Open exactly once |
| P1 | UI | 1080p, 1440p, ultrawide, scales | Readable and usable; no overlapping controls |
| P2 | Map | `C_Map` API discovery and reliable map IDs | Only ship a proper cartographic map if verified |

## Probe caveats

`/lf diagnostics` reports functions present in this runtime and the reported interface number; it **does not exercise their behavior**. Code-level 60/60 unit results are *not* an in-client acceptance sign-off.

## Release criteria

1. No unhandled Lua errors on launch/reload/logout or major gameplay events.
2. Account-wide SavedVariables verified across restarts, characters and migrations.
3. Backup/Restore demonstrated in-game with no silent overwrite/data corruption.
4. Privacy deletion and opt-out demonstrated, including group member identity handling.
5. No combat-protected/secret data operations or significant FPS regression.
6. Every v1.0 feature passes manual acceptance or has a documented, honest fallback.
7. CurseForge project and supported game version approved, license/policy checked.
