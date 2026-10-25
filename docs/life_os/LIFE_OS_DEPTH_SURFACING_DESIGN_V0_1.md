# LifeOS Depth Surfacing Design v0.1: From Note-Taking to an Experienced Continuity System

**Date:** 2026-10-25  
**Context:** Solducci LifeOS — Step 3.2 Strategic Design  
**Originating Feedback:** User Observed Requirement — *"LifeOS currently feels mostly like a somewhat more evolved note-taking system; its deeper power is not yet evident."*

---

## 1. Executive Diagnosis: Why Does LifeOS Feel Like "Just Notes"?

Currently, LifeOS provides:
1. Universal Capture of text seeds into a list.
2. A Vitrine view with editable title, description, custom properties, and sequential thought blocks.
3. Bento projections of recent seeds, active entities, and pinned tiles.

To a user interacting purely with text boxes and cards, this looks structurally indistinguishable from Apple Notes, Bear, or Notion with tags.

The profound difference between a **notes app** and a **Life Operating System** does not lie in more text formatting, folders, or AI summaries. It lies in **behavioral and perceptual continuity loops**:
- A notes app is a **passive repository** where text accumulates and decays into an unorganized attic.
- LifeOS is a **living substrate** that actively assists human re-entry, maintains relational context across operational domains (tasks, finances, time), and reflects lived reality back to the human without requiring administrative gardening.

To make this depth perceptible, LifeOS must manifest **four closed cognitive loops**.

---

## 2. Analysis of the Four Foundational Loops

```mermaid
flowchart TD
    subgraph LoopA["Loop A: Capture → Return → Structure"]
        A1["Raw Thought"] --> A2["Resting Seed"]
        A2 --> A3["Attentive Return"]
        A3 --> A4["Progressive Structuring"]
    end

    subgraph LoopB["Loop B: Connection → Context Recovery"]
        B1["Entity"] <--> B2["Operational Nodes (Task/Expense/Time)"]
        B2 --> B3["Context Recovery"]
        B3 --> B4["Zero Reconstruction Cost"]
    end

    subgraph LoopC["Loop C: Action → Continuity → Resume"]
        C1["Entity Focus"] --> C2["Lived Session / Work"]
        C2 --> C3["Trace & Inactivity"]
        C3 --> C4["Return ('Where was I?')"]
        C4 --> C5["Instant Contextual Resume"]
    end

    subgraph LoopD["Loop D: Intention → Actual → Mirror"]
        D1["Weekly Rail Intention"] --> D2["Observed Allocation"]
        D2 --> D3["Mirror Reflection"]
        D3 --> D4["Human Calibration"]
    end
```

---

### Loop A — Capture → Return → Structure
> *How raw, transient mental sparks mature into ongoing life realities without upfront cognitive tax.*

1. **Human Problem Solved:** The paradox of capture: when an idea occurs, any requirement to categorize it (choose project, tags, deadlines, priority) kills the impulse; but uncategorized captures become a graveyard that is never revisited.
2. **Minimum Data Required:** Title string, creation timestamp, resting state marker.
3. **Existing Domain Primitives Already Available:**
   - `LifeEntity` with `semanticRole: SemanticRole.seed`, `lifecycleState: LifecycleState.active`.
   - `UniversalCaptureWidget` and `UniversalCaptureSheet`.
   - `LifeOsRecentSeedsWidget`.
4. **Missing Primitives:**
   - Explicit "Maturation Affordance": An effortless, single-gesture bridge from Seed to Structured Entity (e.g. promoting a seed by tapping "Coltiva" directly from the Bento feed or Vitrine header).
5. **Vitrine Manifestation:**
   - When a Seed is opened, the Vitrine displays a warm "Maturazione" banner: *"Questo pensiero è ancora a riposo. Vuoi dargli una forma (Progetto, Pratica, Concetto, Idea)?"* with human intentions that add property packs on demand.
6. **Bento Manifestation:**
   - `RecentSeedsWidget` (2x1 and 2x2): displays resting time (e.g. "Catturato 3 giorni fa"). A subtle swipe or long-press offers "Inizia a lavorarci" without deep menu diving.
7. **Time Dial Manifestation:** Not applicable (seeds do not consume allocated calendar time).
8. **What Should Remain Invisible / Derived:** Version history of transitions, taxonomy models, schema adjustments.
9. **Potential Friction:** Feeling forced to categorize before one is ready.
10. **Evidence Needed Before Implementation:** User confirmation that resting seeds in Bento are actually clicked and promoted during daily routines.

---

### Loop B — Connection → Context Recovery
> *How an Entity serves as the gravitational center for tasks, expenses, and temporal constraints without duplicate entry.*

1. **Human Problem Solved:** Fragmentation of life. A personal project (e.g. "Ristrutturazione Casa", "Agrivoltaico") has expenses in Solducci, tasks in the todo list, documents in Notes, and events on the calendar. The human must mentally reconstruct the web every time.
2. **Minimum Data Required:** `EntityRelation` record linking `source_id: entity_uuid` to `target_id: polymorphic_id` (`target_type: task | expense | time_scenario | entity`) with `relation_type` and `context_status` (`blocker | active | reference`).
3. **Existing Domain Primitives Already Available:**
   - `EntityRelation` model, `EntityRelationRepository`, PostgreSQL table `entity_relations` with RLS and target cleanup triggers.
4. **Missing Primitives:**
   - Lightweight relational projection surface inside the Vitrine: a section *"COSTELLAZIONE COLLEGATA"* showing linked expenses, tasks, and notes without entering their separate full-blown views.
   - Quick-link affordance: typing `/task` or linking a transaction from Solducci to an Entity.
5. **Vitrine Manifestation:**
   - Compact chips under properties: `[ 3 Task attivi (1 blocker) ]`, `[ Spese: 1.450 € ]`. Tapping reveals an inline bottom drawer showing the connected items in place.
6. **Bento Manifestation:**
   - Pinned Entity in `4x2` projects these cross-domain indicators directly on the dashboard (e.g. *"Prossimo passo bloccato da Task X"*).
7. **Time Dial Manifestation:**
   - Time blocks on the dial glow with the entity's color when scheduled.
8. **What Should Remain Invisible / Derived:** Foreign key mappings, target type enums, bidirectional graph indexing.
9. **Potential Friction:** Tedious manual relationship creation. Must be automated via natural mentions or quick picks.
10. **Evidence Needed Before Implementation:** Observation that users want to see finance/task state inside an entity rather than visiting separate tabs.

---

### Loop C — Action → Continuity → Resume (The Primary Depth Differentiator)
> *How a human can leave a project for 3 weeks, return, and resume in 10 seconds without cognitive paralysis.*

1. **Human Problem Solved:** The "Re-entry Cost". When life forces a pause on an endeavor, returning produces anxiety because the working memory of "where was I?", "what was the next step?", and "what were the key open threads?" has decayed.
2. **Minimum Data Required:**
   - `LifeSession`: `started_at`, `duration_minutes`, `activity_summary`, `observations` (notes on where one stopped).
   - `last_meaningful_activity_at`: derived timestamp.
   - `ResumeSurfaceData`: calculated resume card (last session observation, active blocker, next step).
3. **Existing Domain Primitives Already Available:**
   - `LifeSession` model, `LifeSessionRepository`, `user_entity_overlays`, `ResumeCapability` domain logic (`isResumeWorthy` when inactive > 21 days).
4. **Missing Primitives:**
   - Session Runner surface: A simple, focused timer/runner ("Sto lavorando su questo") that finishes with a single prompt: *"Dove sei arrivato? Cosa farai alla prossima ripresa?"*.
   - Vitrine Resume Card: A prominent top banner displayed when returning to an entity after >3 days of pause: *"Ultima sessione (12 ott): 'Mappata retention policy. Prossimo step: verificare con DPO' [ Riprendi da qui ]"*.
5. **Vitrine Manifestation:**
   - Dedicated "Riprendi" hero surface above the title or below semantic chips, showing the last operational bookmark.
6. **Bento Manifestation:**
   - Pinned Entity and Active Entities highlight dormant entities that have a clear next step: *"Pronto per rientrare"*.
7. **Time Dial Manifestation:**
   - Allows dropping an entity onto the Time Dial to allocate a session.
8. **What Should Remain Invisible / Derived:** Inactivity duration calculations, metric aggregations, decay functions.
9. **Potential Friction:** Feeling evaluated or pressured by an app tracking inactivity. Tone must be compassionate and purely orienting, never guilt-inducing.
10. **Evidence Needed Before Implementation:** User lived feedback stating: *"I opened an entity I hadn't touched in a while and immediately knew what to do."*

---

### Loop D — Intention → Actual → Mirror
> *How a human compares their intentional life priorities with their actual lived allocation.*

1. **Human Problem Solved:** The illusion of time allocation. People believe they spend time on their high-value aspirations (practices, creative projects), while days disappear into operational friction and drift.
2. **Minimum Data Required:**
   - Weekly Rail intentions (`UserEntityOverlay.isInWeeklyRail = true`).
   - Recorded session minutes and task completions aggregated per entity and semantic role.
3. **Existing Domain Primitives Already Available:**
   - Weekly Rail overlays, `life_sessions` duration and timestamp aggregations.
4. **Missing Primitives:**
   - Mirror View / Signal Engine: A calm weekly mirror showing the delta between intended focus (Weekly Rails) and actual activity (recorded sessions/tasks).
5. **Vitrine Manifestation:**
   - Weekly Rail toggle (already present as `[ Weekly Rail ★ ]`).
6. **Bento Manifestation:**
   - Active Entities widget reflects weekly rail membership.
7. **Time Dial Manifestation:**
   - Dial tracks dedicated rails as visual arcs.
8. **What Should Remain Invisible / Derived:** Percentage algorithms, productivity scores, gamification.
9. **Potential Friction:** Shame or anxiety if actual does not match intention. The Mirror must be a neutral contemplative mirror, not a performance dashboard.
10. **Evidence Needed Before Implementation:** Genuine recorded session data from Loop C. Without real sessions, Loop D is an empty mathematical fantasy.

---

## 3. Rethinking the Step 4 Recommendation

### The Strategic Rule: One Complete Closed Loop Over Four Fragmented Features
Past roadmaps listed:
1. Session Runner
2. Weekly Rails on Time Dial
3. Weekly Ceremony
4. Mirror Signals

Implementing a timer, a ceremony sheet, and a signal card in parallel would produce fragmented UI without giving the user a single finished transformative experience.

### The Recommended Target: Loop C (Action → Continuity → Resume)

```text
Entity Focus 
  → Start Focused Session 
  → Log Finish Bookmark ("Dove mi sono fermato") 
  → Inactivity Period 
  → Return to Vitrine 
  → Instant Contextual Resume ("Riprendi da qui")
```

#### Why Loop C is the Game-Changer
1. **It directly cures the "just notes" perception:** No notes app knows where you stopped, what blocked you, or how to resume your flow after 2 weeks away.
2. **It requires zero external setup:** The user does not need to configure graphs or setup complex relations; they simply tap "Inizia sessione" on an entity they care about.
3. **It creates the real data needed for Loop D (Mirror):** You cannot mirror actual life without first sampling actual sessions.

### Proposed Step 4 Vertical Slice: "The Continuity Loop"
1. **Vitrine Continuity Bookmark ("Dove mi sono fermato"):**
   - Editable bookmark field and session log.
2. **Minimal Session Runner (In-Place / Floating):**
   - Start session on an entity $\rightarrow$ silent background timer $\rightarrow$ stop $\rightarrow$ prompt for single 1-line bookmark.
3. **Vitrine Resume Banner:**
   - When opening an entity that has a previous session bookmark, display the clear re-entry prompt at the top.

---

## 4. Grounded Epistemic Gate for Step 4 Authorization

Before implementing Loop C, the following prerequisites must hold:
1. **Step 3.2 Integrity Green:** Bento widgets, Pinned configuration, Custom Properties, and Keyboard positioning are physically validated on device.
2. **User Authorization:** The user explicitly reviews this Depth Surfacing Design and authorizes the Continuity Loop vertical slice as the canonical target of Step 4.
