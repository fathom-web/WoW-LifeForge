# LifeForge v1.0 — Full feature matrix (Build 7 review)

**Important:** Working alpha means functional code and headless tests, **not** release approval. Every row remains part of public v1.0. Real Forever client verification and manual usability review are still required.

| # | Agreed feature | Build 5 status | Remaining public-release acceptance |
|---:|---|---|---|
| 1 | Hybrid fantasy UI | Working alpha | Live texture/layout, accessible multiline editors, resolution/scale |
| 2 | Character Legacy | Working alpha | Client identity API |
| 3 | Realm and Account Legacy | Working alpha | Cross-realm/alt actual SavedVariables |
| 4 | Life Statistics | Working alpha | Client event correctness and timer drift |
| 5 | Adventure Timeline | Working alpha | Long-save paging/filter usability |
| 6 | The Chronicle | Working alpha, expanded | Story polish and narrative UX |
| 7 | Legacy Vault/Notes | Working alpha, multiline editor | On-client font/text scrolling acceptance |
| 8 | Legacy Goals | Working alpha, expanded | Six-kind editor behavior and timing in WoW |
| 9 | Adventure Companions | Working alpha | Real party/raid roster events and privacy |
| 10 | Smart Milestones | Tier engine implemented (alpha) | Verify tracking-derived unlocks and alerts in live client |
| 11 | Session Intelligence | Working alpha, expanded | Timing/AFK semantics in client |
| 12 | Legacy Wrapped | Working alpha | Seasonal visual polish and screenshot flow |
| 13 | Backup & Restore | Working alpha | Multi-part large-save UI and actual disk persistence |
| 14 | Settings/Privacy/Data Health | Working alpha, expanded | Manual accessibility/privacy audit |
| 15 | Legendary Bonds | Working alpha | Observed overlap actual in-game |
| 16 | Azeroth Footprint | Paginated zone atlas; guarded C_Map evidence capture (alpha) | Native world-map integration and coordinates must be validated live |
| 17 | Memory Museum | Working alpha | Gallery game-client visuals |
| 18 | Future Self Letters | Working alpha: level/hours/date editor | In-game timezone and editor acceptance |
| 19 | Personal Records & Firsts | Working alpha, expanded | Verify real firsts and record semantics |
| 20 | Family Legacy | Working alpha: multi-character summary | Validate account/realm SavedVariables with real alts |
| 21 | The Last Adventure | Working alpha | Absence/reunion live event verification |
| 22 | Time Capsules | Working alpha | Archives from long-lived data |
| 23 | Adventure Party | Working alpha | Nicknames, events, roster conditions in client |
| 24 | Then vs Now | Working alpha | Visual comparison UX |
| 25 | Memory Bookmark | Working alpha, expanded | Hotkey UX and in-game data context |
| 26 | Guild Legacy | Working alpha, expanded | Actual guild membership behavior and memories |
| 27 | Character Retirement | Working alpha, expanded | Right-click workflow in actual client |
| 28 | Legacy Calendar | Working alpha | Date/time locale and day interactions |
| 29 | Smart Notifications | Working alpha | Combat-delayed notice behavior |
| 30 | Localization | English dictionary + fallback; key UI strings extracted | Remaining literal UI strings and translated languages |
| 31 | Retention, Integrity & Performance | Working alpha, expanded | Long-run on-client soak/backup/benchmark |

## Release gate

Public 1.0 is **blocked** until all applicable rows have passed live-client tests or an explicitly documented technical constraint has a graceful in-game alternative. Automated headless tests alone are insufficient.

### Technical non-fabrication rule

No guessed map coordinates, bosskills, group time, historical events, inferred relationships or invented loot. Some features must remain observational or user-entered.