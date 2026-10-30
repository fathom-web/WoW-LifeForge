# LifeForge Hybrid In-Game UI — Build 2 specification

## Visual direction

- Fantasy chronicle with dark wood/bronze/gold accents, using standard in-game frames and textures.
- 940 × 645 main frame, UI scaling cycle 85%, 100%, 115%; draggable unless in combat.
- Left rail with 16 navigable sections; 4 metric cards across the top; three scope controls; 9-row paged body; footer with version/status.
- Read-only display of observed data by default. No automatic screenshot generation or out-of-game integration.

## Navigation

Tabs: Overview, Characters, Chronicle, Timeline, Statistics, Companions, Goals, Legacy Vault, Museum, Azeroth, Calendar, Time Capsules, Wrapped, Guild Legacy, Records, Settings.

- **Character** scope includes the selected saved character, not necessarily the current active character.
- **Realm** scope groups characters on that selected saved character's realm.
- **Account** scope shows all characters previously observed on this local installation.
- Search operates on Timeline, Chronicle and Vault; filters are literal (not Lua patterns).
- Click a character row to inspect the character. Click an event to toggle favorite on the active character. Click a note to edit; right-click to toggle favorite. Click companion to open privacy/remove dialog.
- Settings are locally persisted through WoW SavedVariables; /lf and minimap open/close the frame.

## Known gaps / acceptance before 1.0

Current interface intentionally is functional rather than a complete recreation of the earlier illustrative flyer. Full book illustrations, typography assets, graphical maps, charts, group stories, guild progression, editor for Future Self Letters, visual month calendar, an immersive memory museum and expanded Wrapped need subsequent builds. Usability with real WoW gamepad/monitor settings and protected/combat actions is unverified.
