# Host Lobby — Figma Design Spec

Use this spec to recreate the Host Lobby screen in Figma. Edit in Figma, then **select the frame** and tell Cursor to implement it — the Figma MCP will read your design and update the code.

## Quick Start
1. Create a new Figma file (or page) for "Host Lobby"
2. Follow the structure below
3. Apply the design tokens
4. When done, select the Host Lobby frame in Figma and say: *"Implement this design in the host lobby"*

---

## Design Tokens

### Colors (hex)
| Token | Hex | Usage |
|-------|-----|-------|
| `backgroundPrimary` | `#0F1117` | Page background |
| `backgroundSecondary` | `#161A23` | Surface (QR header) |
| `surface` | `#1E232D` | Cards, elevated surfaces |
| `surfaceElevated` | `#262B36` | — |
| `borderSubtle` | `#2E3442` | Borders |
| `textPrimary` | `#FFFFFF` | Primary text |
| `textSecondary` | `#B5BAC1` | Secondary text |
| `textMuted` | `#7C818C` | Muted text |
| `primaryAccent` | `#5865F2` | Accent (Discord blurple) |
| `accentGold` | `#FBBF24` | Gold (host star, partner) |
| `success` | `#57F287` | Ready state, Start button |
| `danger` | `#ED4245` | — |
| `white` | `#FFFFFF` | QR code background |

### Spacing (golden ratio scale)
| Token | px | Usage |
|-------|-----|-------|
| `gr0` | 4 | — |
| `gr1` | 6 | Small gaps |
| `gr2` | 10 | Between elements |
| `gr3` | 16 | Section padding (compact) |
| `gr4` | 26 | Section padding, vertical rhythm |
| `gr5` | 42 | Bottom padding |

### Typography
| Element | Size | Weight | Color |
|---------|------|--------|-------|
| App bar title | 20 | Medium | `textPrimary` |
| Section title | 15 | Bold | `textPrimary` |
| Subsection title | 14 | Bold | `textPrimary` |
| Username | 15 | SemiBold (600) | `textPrimary` |
| Body / label | 13 | Regular | `textSecondary` |
| Small / hint | 12 | Regular | `textSecondary` |
| Tiny | 10–11 | Regular | `textSecondary` |
| Button | 13–14 | SemiBold (600) | varies |

### Border Radius
| Token | px |
|-------|-----|
| Small | 8 |
| Medium | 12 |
| Large | 14 |
| XL | 16 |
| Pill | 999 |

---

## Screen Structure (top to bottom)

**Viewport:** 390×844 (iPhone 14) or 360×640 (compact)

### 1. App Bar
- Height: 56
- Background: `backgroundPrimary`
- Title: "Host Lobby" (center)
- Back: arrow icon, left

### 2. Body (SafeArea + ListView)
- Horizontal padding: 16 (gr3)
- Vertical padding: 10 top, 42 + safe bottom

---

## Component Specs

### QR Header
- **Background:** `#1E232D` (surface)
- **Padding:** 16–26 vertical, 16–26 horizontal (responsive)
- **Contents:**
  - Row: QR icon (18×18, accent) + "Players joined: N • Scan QR to join" (13px, secondary)
  - Spacer 16
  - QR code container: white bg, 12px radius, 12px padding, shadow
  - QR size: 140 (compact) / 160 (normal)
  - IP text below: 10px, secondary, ellipsis

### Player Slot Card
- **Background:** `#1E232D` (card)
- **Border:** 1–2px, radius 16
  - Own slot: accent or success (ready)
  - Other: player color @ 25% opacity
- **Padding:** 10 (compact) / 16 (normal)
- **Shadow:** black 12%, blur 8, offset (0,2)
- **Layout:** Row
  - Avatar: 44×44 (compact) / 50×50, radius 8
  - Gap: 10
  - Content (Expanded): Column
    - Row: 8×8 color dot + username (15, semibold) + host star (13, gold) if host
    - Commander name (12) or "No commander selected" (accent)
    - Partner: "+ PartnerName" (11)
  - Buttons (own slot only): Partner, Commander, Ready? — min 44h, Wrap

### Empty Slot Card
- **Background:** `#1E232D`
- **Border:** 1px `textSecondary` 20%
- **Padding:** 26 vertical, 10 horizontal
- **Text:** "N open slot(s) — share your device to let friends join" (13, center)

### Game Settings Card
- **Background:** `#1E232D`
- **Padding:** 16 (compact) / 26 (normal)
- **Radius:** 14
- **Sections:**
  - "Game Settings" (15, bold)
  - Format row: "Format" label + Commander | Standard toggle (pill, 44min height)
  - Starting life: "Starting Life" + chips [20, 25, 30, 40, 60, Custom]
  - "Gameplay" (14, bold)
  - Switch tiles: Planechase, Archenemy, Bounty, Auto-KO, etc.
  - Turn time limit: Off, 1m, 2m, 5m chips

### Start Game Button
- **Full width,** min height 52
- **Enabled:** `#57F287` (success)
- **Disabled:** `#B5BAC1` (textSecondary) 30%
- **Text:** "Start Game" or hint (16, bold, white)

---

## Responsive Breakpoints
- **Compact:** width < 360
- **Narrow config:** width < 280 (stack Starting Life vertically)
- **Narrow timer:** width < 320 (stack Turn time limit vertically)

---

## Figma Setup Tips
1. Create a **Frame** 390×844 named "Host Lobby"
2. Add **Color styles** for each token
3. Add **Text styles** for each typography row
4. Use **Auto layout** with 10px (gr2) / 16px (gr3) / 26px (gr4) spacing
5. Set **Constraints** for responsive behavior
6. Use **Components** for: PlayerSlotCard, FormatToggle, LifeChip, SwitchTile

---

*Generated from `lib/features/lobby/lobby_screen.dart` — MGT Life Spark*
