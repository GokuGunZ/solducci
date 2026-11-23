# 05 — ARCHITECTURE DECISION RECORD

**Run ID:** `run_20261123_045201_dynamic_capture_bar_and_chained_seed_overlay`  
**Decision:** Component Architecture for Dynamic Capture Bar, Mention System, and Chained Seed Overlay  

---

## 1. Context & Problem Statement

The user requires a comprehensive redesign of the LifeOS capture interface:
1. Smooth spatial morphing between single-line (inline) and multi-line (stacked 2-tier full-width) states.
2. Real-time mention detection (`@`) that distinguishes leading ("Figlio di") from mid-text ("Semplice") connections.
3. A modal chained capture overlay that freezes the committed seed, dims the background, and allows continuous seed chaining.

---

## 2. Alternatives Evaluated

### Alternative A: Global Monolithic Overlay with ModalBottomSheet
- *Approach:* Use Flutter's default `showModalBottomSheet` for both capture and chaining.
- *Pros:* Standard framework mechanism.
- *Cons:* Breaks the seamless feeling of the in-page capture bar; bottom sheet keyboard handling in Flutter often introduces jitter and re-layout delays; doesn't allow the exact in-place card transformation requested by the user.

### Alternative B: Dedicated Stateful Architecture with Clean Component Separation (RECOMMENDED)
- *Approach:*
  1. **`DynamicCaptureBar` Widget:** Evolves `UniversalCaptureBar` into an animated, state-aware widget using `AnimatedContainer`, `AnimatedSize`, and `LayoutBuilder`. It manages its line-state via text line evaluation.
  2. **`MentionTextController`:** A specialized `TextEditingController` that detects `@` typing, highlights mentions with distinct styling (`TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)`), and dispatches mention events to the suggestion overlay.
  3. **`ChainedCaptureOverlay`:** An in-page modal stack or animated full-viewport overlay anchored in `LifeOsCenterView`. When active, it renders a blurred/dimmed background, the committed seed card with an Edit button, and the active chained input bar positioned natively above the software keyboard.
- *Pros:*
  - Zero keyboard flickering.
  - Perfect continuity: the exact box the user was typing in becomes the committed card without route push/pop overhead.
  - Highly testable with widget tests.
  - Reusable: can be embedded into both `LifeOsCenterView` and Bento widgets.

---

## 3. Decision & Technical Claims

1. **Adopt Alternative B.**
2. **Text Line Detection Heuristic:**
   - Detect line wrapping using a hidden `TextPainter` or listening to `_controller.text` newline characters and layout width. When `lines >= 2`, switch `_isMultiline = true`.
3. **Animation Choreography:**
   - Spatial morph duration: 250ms with `Curves.easeInOutCubic`.
   - Text label slide: `SlideTransition` / `AnimatedAlign` (slide from right to left behind the send button).
4. **Data Persistence Guarantee:**
   - Chained captures are committed optimistically to `LifeEntityRepository` and `EntityRelationRepository` in sequential FIFO order.
