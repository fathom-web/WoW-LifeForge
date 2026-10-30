# LifeForge 0.4.0-alpha — Build 3: Legacy & Social Systems

Date: 2026-10-29  •  **Pre-release, not live-client verified**

## Implemented

- Extended schema-v2 character records **additively**, preserving older SaveVariables/backup compatibility.
- Observed group-overlap tracking: companion time, session counts, 4 Legendary Bond thresholds, and long-gap reunion milestones.
- Recurrent group signatures, nicknames, session history, measured group-overlap duration, bounded storage.
- Explicit companion erasure across characters, suppression of further observations for the forgotten key, and removal of associated generated facts.
- Captured guild membership changes with cautious nil handling and no backfilled history.
- Derived peak gold, max level, longest completed active session and recent session history views.
- Chronicle month chapters based on observed events only.
- Monthly snapshot comparison (Then vs Now), letter composer and letters in Time Capsules, and bookmark group context.
- Updated Companions, Guild, Records, Wrapped, Chronicle and Time Capsules view models.
- Preserved LF2 chunked backup engine, explicit preview/confirmation, and CI automation.

## Automated verification

- **38/38 headless Lua tests passed** under `texlua` (including 13 additional Build 3 tests).
- **19/19** referenced TOC Lua files exist.
- Addon ZIP packaged; source ZIP prepared for GitHub.

## Known limitations

- **No real Forever testing** until supported client is available. The API interface ID `16001` remains provisional.
- Time with friends means **observed time in the same group**, not proof of shared online activity outside party/raid. When roster state is uncertain or inaccessible, tracking stops until safely refreshed.
- Social erasure does not rewrite free-form note content manually typed by the player, and only erases generated social events linked to the player key.
- Character-alts are not visible until the player logs into them with LifeForge on this installation.
- Group nicknames are locally per-character and based on exact roster membership, not cross-realm account or person identity.
- Monthly Time Capsules are once-per-month recorded starting-state snapshots (not continuously updated monthly end-of-period snapshots); comparisons are anchored to that snapshot.
- Some UI sections are functional list views pending v1.0 visual polish.
- No direct GitHub push, CurseForge upload or automatic game client testing was performed.

## Next build recommendation

Build 4: visual experience polish + interactive calendar, museum and detailed Wrapped, followed by deeper data retention and live client tests. Preserve one addon, one GitHub repository and CurseForge-only public distribution.
