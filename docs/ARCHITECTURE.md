# LifeForge Foundation Architecture — schema 2

```text
WoW Forever APIs / Events (small, explicit compatibility surface)
  PLAYER_LOGIN  -> Boot
  PLAYER_LEVEL_UP / PLAYER_MONEY / ZONE_CHANGED -> collectors
  GROUP_ROSTER_UPDATE -> companion observer
  PLAYER_LOGOUT -> session close
  OnUpdate (5-second accumulator) -> session, AFK, group overlap and daily totals
                   |
                   v
Bootstrap -> Database -> Character -> Events -> Goal/Memory/Chronicle/Snapshots
                   |                         |
                   v                         v
          Account-wide SavedVariables     In-game read-only views
                   |
                   v
          LF2 Backup serializer / safe staged restore
```

## Data ownership and invariants

- `LifeForgeDB` is **account-wide** within the local WoW installation. It is **not** Battle.net cross-device cloud sync.
- Character key is `normalizedRealm:characterName`; documented realm normalization and legacy alias migration.
- `db.characters[key]` is the source of truth. Shared account and realm totals are **derived** from individual character records, never added separately.
- `c.nextId` generates monotonically increasing local IDs; event and note IDs share a per-character sequence.
- `c.stats.active` + `c.stats.afk` are tracked (approximate) seconds, not lifetime `/played`.
- `c.companions[playerKey].seconds` counts sampled party/raid overlap while our player is present. No full historical friend tracking.
- `c.daily[YYYY-MM-DD]` and `c.snapshots[YYYY-MM]` are existing time series anchors for Calendar, Then vs Now, Wrapped and Time Capsule.
- `c.letters`, `c.groupHistory`, `c.guildHistory` and `c.snapshots` already exist in schema 2 so future modules won't require a destructive schema rewrite.
- `db.future.designVersion` tracks future schema-conforming presentation.
- Bounded collections protect client memory; retention/archival strategy is a required public-release item.

## Schema 2 high-level shape

```text
LifeForgeDB
  schema: 2
  created / updated
  settings
    tracking, socialTracking, mutedCompanions, minimap, scale
    notifications{}, ui{}, retentionDays
  characters{}
    [realm:character]
      name, realm, class, race, faction, level, gold, zone
      created, lastSeen, retired
      stats{ active, afk, sessions, levelUps, goldDelta, goldEarned, goldSpent }
      events[]  { id, kind, title, description, zone, at, favorite }
      notes[]   { id, title, body, category, at, updated, favorite, zone }
      goals{}   { id, title, kind, target, completed }
      zones{}   { firstSeen, seconds }
      companions{} { firstSeen, lastSeen, seconds, groupSessions }
      sessionHistory[], openSession
      daily{}, snapshots{}, letters[]
      groupHistory{}, guildHistory{}
  characterOrder[]
  meta{ migrations[], lastExportAt }
  future{ designVersion }
  _legacyBackupV1 (only after migration; removed manually in a future safe migration)
```

## Backup contract (LF2)

- Text part wire format: `LF2|partNumber|totalParts|8HEXchecksum|base64PayloadChunk`.
- Parser accepts only plain typed records (`T`, `S`, `N`, `B`, `Z`); Lua execution, metatables, functions and cycles are prohibited.
- Maximum raw payload 6MB; parts of 3200 characters; no silent truncation.
- All parts are required; order irrelevant, duplicate equal chunks tolerated, conflicting duplicate rejected.
- Validated preview counts incoming/new/conflicting characters.
- Merge preserves existing local char profiles and adds only absent incoming char profiles; replace swaps entire database. No summing non-additive tracked stats.
- Explicit confirmation is required before staging `LifeForgeDB`, and `/reload` is required to activate it.
- LF2 checksum is **integrity-only**, not cryptographic authentication. It is not encryption.

## WoW API integration risk

The beta reports Interface `16001` and follows modern Mainline APIs. Unknown event registration is wrapped in `pcall`. We only read normal player identity, currency, level, zone, AFK and party/raid roster info; no combat log parsing, protected-action execution, or automated combat. Live-client verification is a release gate.

## Build 3 extension (0.4.0-alpha, 29 Oct 2026)

Schema v2 remains compatible with Build 1 and Build 2. Character fields `parties` and `records` are optional extensions normalized for **all** stored characters during initialization. This avoids breaking imported v2 saves from previously observed alts; LF2 backup validation checks these structures when present.

- `Core/Social.lua`: observed roster → per-companion counters + bond thresholds; exact roster keys → named recurring `parties`; bounded `groupHistory`; optional exclusion and explicit erasure. Combat-era uncertain rosters pause observations; normal group observations are never interpreted as real-world friendship.
- `Core/Guild.lua`: observed guild name changes only. No guild history is inferred from a character existing before addon installation.
- `Core/Records.lua`: peak gold/level, longest completed active session and deterministic `ThenVsNow` deltas.
- `Core/Chronicle.lua`: monthly generated chapters derived only from stored event records.
- `Core/Memories.lua`: new bookmarks include captured group-membership keys when social tracking permits.
- `UI/ViewModel.lua`: pre-existing hybrid fantasy view models now expose concrete guild, companion groups, records and monthly summaries.

Privacy: forgetting a companion removes identifiable generated records and automatically blocks subsequent observation of that same key. Free-form manual note contents must be reviewed by the player separately.

## Build 4 — Derived presentation models and native visual panels

The existing schema v2 and non-executable LF2 export format remain unchanged. Build 4 introduces:

- `Core/Experience.lua`: pure, read-only `CalendarModel`, `FootprintModel`, `MuseumModel`, `WrappedPeriods`, and `WrappedModel` generated from current locally observed records. Character/realm/account membership resolves through `GetKeys` and is not invented for unvisited alts.
- `UI/Experience.lua`: creates once and reuses a 42-cell calendar, 8-zone heat-bar atlas, six-card-per-page museum and native Wrapped metrics. Accessed by `Main.lua` without creating one frame per historic event.
- `Tracking.lua`: rate-limits passive live UI refreshes while retaining explicit event/interaction refresh.

Monthly reporting is intentionally narrower than all-time reporting. Historic group minutes and individual zone durations were not persisted per month in earlier Builds, so those metrics are not shown for month-specific Wrapped. Real map plotting requires validated map IDs/coordinates from the actual Forever client; this build does not assume them.
