# 06 — UX & INTERACTION SPECIFICATION

**Run ID:** `run_20261123_045201_dynamic_capture_bar_and_chained_seed_overlay`  
**Aesthetic:** Solducci Glassmorphism Dark Theme (`#09090B`, `#18181B`, Violet Accent `#8B5CF6`)  

---

## 1. Spatial Morphing Wireframes

### State 1: Single-Line (Compact Inline Mode)
```text
┌────────────────────────────────────────────────────────────────────────┐
│  (🌿)   Cattura un pensiero, seme o @entità...                    (↑)  │
└────────────────────────────────────────────────────────────────────────┘
  40px                      Expanded TextField                       40px
```
- **Height:** ~52px.
- **Leading Icon:** `Icons.eco_outlined`, color `Colors.white38`.
- **TextField:** Single line, vertical center alignment, wrapping disabled for single line.
- **Send Button:** Circular container (32x32) with `AppTheme.primary`, arrow upward.

---

### State 2: Multi-Line (Two-Tier Expanded Mode)
```text
┌────────────────────────────────────────────────────────────────────────┐
│  (🌿)  [↳ @Progetto Alfa] [⚯ @Marco]          Raccogli seme   (↑)      │
│ ────────────────────────────────────────────────────────────────────── │
│  Stiamo definendo le specifiche per la nuova release e dobbiamo         │
│  rivedere insieme l'architettura dei grafi...                          │
└────────────────────────────────────────────────────────────────────────┘
```
- **Top Row (Tier 1):**
  - **Left:** Leading icon `(🌿)` anchored at top-left.
  - **Middle:** Horizontal scrollable row of active **Tag Chips** (`SeedMentionChip`).
  - **Right:**
    - Slide-in text label: `"Raccogli seme "` in `TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)`.
    - Slides smoothly from behind the send button (`SlideTransition(position: Tween(Offset(0.4, 0), Offset.zero))`).
    - Circular send button `(↑)`.
- **Bottom Row (Tier 2):**
  - Full-width multiline `TextField`.
  - Extends from far left to far right (zero horizontal margin restrictions).
  - Dynamic vertical growth up to `maxHeight: 180px`.
  - Line height: 1.45, font size: 14.5px, color: `Colors.white`.

---

## 2. The Chained Capture Overlay Wireframe

```text
════════════════════════════════════════════════════════════════════════════
 [ Background: LifeOS Center Defocused & Dimmed with 80% Dark Scrim ]
════════════════════════════════════════════════════════════════════════════

  ┌──────────────────────────────────────────────────────────────────────┐
  │  [↳ @Progetto Alfa]                                     [✏️ Modifica] │
  │  Stiamo definendo le specifiche per la nuova release e dobbiamo      │
  │  rivedere insieme l'architettura dei grafi...                        │
  └──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼  (Connessione parte_di / catena)
  ─────────────── 🔗 Raccogli una catena di semi ───────────────────────

  ┌──────────────────────────────────────────────────────────────────────┐
  │  (🌿)   Aggiungi il prossimo anello della catena...             (↑)  │
  └──────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────┐
  │                          [ CONCLUDI CATENA ✓ ]                       │
  └──────────────────────────────────────────────────────────────────────┘

  [ === SOFTWARE KEYBOARD PINNED IMMEDIATELY BELOW === ]
```

### Overlay Details:
1. **Committed Card ("Box Definitivo"):**
   - Background: Solid dark surface `#18181B` with subtle border `Colors.white12`.
   - Top right: Action button `[ ✏️ Modifica ]` in primary violet color.
   - Tapping "Modifica" reverts the card back into an active editable state.
2. **Chain Connector:**
   - Subtle vertical dotted line or chain link icon linking the parent card to the new input bar.
   - Text banner: `"Raccogli una catena di semi"`, 12px uppercase, letter-spacing 1.1, color `Colors.white60`.
3. **Active Next-Link Bar:**
   - Fresh instance of `DynamicCaptureBar` with autofocus.
   - Submitting a second seed appends it to the chain and resets the input bar for link #3.
4. **Finalize Action:**
   - A sticky button `"Concludi Catena (N semi raccolti)"` or tapping the background scrim finishes the workflow with haptic confirmation.

---

## 3. Tag Chip & Relation Switcher Popover

### Tag Chip Anatomy:
- **Child Relation (`partOf`):**
  - Background: `Color(0xFF8B5CF6).withOpacity(0.18)`
  - Border: `Color(0xFF8B5CF6).withOpacity(0.4)`
  - Icon: `Icons.subdirectory_arrow_right_rounded`
  - Text: `@NomeEntità`
- **Simple Relation (`relatesTo`):**
  - Background: `Colors.white.withOpacity(0.08)`
  - Border: `Colors.white.withOpacity(0.15)`
  - Icon: `Icons.link_rounded`
  - Text: `@NomeEntità`

### Popover Switcher Sheet (On Tap):
- **Title:** `Collegamento: @NomeEntità`
- **Description:** *"Scegli come questo seme è collegato all'entità selezionata:"*
- **Segmented Toggle:**
  - Option 1: `🌱 Figlio di (part_of)` — *"Questo seme appartiene o deriva da questa entità"*.
  - Option 2: `⚯ Semplice (relates_to)` — *"Questo seme è semplicemente associato come riferimento"*.
- **Destructive Button:** `Rimuovi collegamento` (rimuove il tag e il chip).
