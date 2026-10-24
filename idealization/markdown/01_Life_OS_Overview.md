---
checkpoint: "Life OS v0.1"
document: "01"
title: "Life OS Overview"
canonical_pdf: "../01_Life_OS_Overview.pdf"
---

# 01 — Life OS Overview

*Whole-system synthesis - Checkpoint v0.1*

> **Purpose**  
> Explain the entire Life OS at high level: why it exists, how the major model areas fit together, what is established, and where the design frontier currently sits.

| Metadata | Value |
| --- | --- |
| Status | Checkpoint synthesis |
| Reading mode | Global comprehension |
| Canonical sources | Foundation 02; Models 03-08; Case Studies 09; Rationales 10; Design Log 11 |
| Checkpoint boundary | Pre-Ontology Minimum v0.1 |

_This Overview compresses the checkpoint. Canonical definitions and detailed uncertainty live in the referenced model and design-log documents._

## 0. Executive summary

Life OS is a personal operating and reflection system for a life with many simultaneous interests, projects, responsibilities, knowledge domains, relationships and maintenance needs. Its goal is not to optimize every minute. Its goal is to externalize enough context that conscious direction, flexible action, low-friction resumption and self-understanding become easier.

> **CORE IDEA [ESTABLISHED]**  
> A progressively structured personal graph of things, knowledge, intentions, experiences and time, combined with ceremonies, contextual views and derived signals. The system makes complexity visible without deciding on behalf of the person.

The checkpoint deliberately stops before Ontology Minimum v0.1. The current corpus defines the problems, design constraints, models, cases, decisions and open questions that the ontology must satisfy.

## 1. Why the system exists

The life being supported is not organized around one career track or one hobby. It includes software engineering, entrepreneurship, software products, economics, music, creative crafts, games, speedcubing, books and media, world understanding, health, logistics, relationships, travel and recurring maintenance. The challenge is preserving breadth without paying for it with fragmentation and cognitive overload.

### Original friction

- Interesting ideas disappear before they receive even a basic evaluation.
- Projects and hobbies can remain paused long enough that resumption requires reconstructing context from scratch.
- Resources can accumulate without distillation; knowledge can accumulate without application.
- Attention can drift away from declared priorities without the drift becoming visible.
- Rigid planning can become more expensive than the work it was meant to support.
- Life-maintenance work competes with creative/professional goals but is often invisible in productivity systems.

## 2. System responsibilities

The Foundation document defines 18 canonical system responsibilities. They cluster into six themes:

| Theme | Responsibilities |
| --- | --- |
| Orientation | Whole-life map; conscious prioritization; emerging importance. |
| Continuity | Idea preservation; attention alternation; low-friction resume; inactivity management. |
| Progress | Consistent progress; progressive decomposition; contextual action selection. |
| Learning | Debt/imbalance detection; synergy surfacing; knowledge reuse. |
| Reflection | Ceremony support; planned-vs-actual awareness; self-model reflection. |
| Maintenance | Life-maintenance visibility; system-maintenance awareness. |

## 3. What Life OS is not

- Not only a task manager, calendar, PKM, CRM, habit tracker or quantified-self system.
- Not a rigid taxonomy that must be completed before use.
- Not exhaustive life logging.
- Not an AI optimizer that infers the correct life from behavior.
- Not a fixed schedule that treats deviation as failure.

## 4. Core philosophy

| Principle | Meaning in practice |
| --- | --- |
| System as Mirror | Expose context, patterns and evidence; interpretation and commitment remain human. |
| Rails, not rigid schedules | Predefine useful constraints and options, not every action minute-by-minute. |
| Progressive Structuring | A thing can remain text until identity, structure, reuse or operations justify promotion. |
| Derive, do not duplicate | Prefer canonical facts and computed secondary state. |
| One reality, many views | Context changes presentation, not underlying truth. |
| Formalization must earn its cost | Every property, type, metric or workflow must justify maintenance burden. |
| Revisable Self-model | Values and interests are reflective constructs, not immutable axioms. |

## 5. High-level mental model

The current direction can be summarized as a small set of compositional layers:

```text
Entity + Relations + Properties/Literals + Time
  -> partial schemas
  -> Capabilities and Operations
  -> domain patterns such as Concept, Project, Task, Session
  -> Processes/Modes such as Exploration, Practice, Execution, Retrospective
  -> Views and derived Signals
```

> **WORKING**  
> Entity, Relation, Property/Literal and Time are candidate primitives. Their exact formalization is intentionally left to Ontology Minimum v0.1.

## 6. Information and Knowledge

Information is allowed to mature. A sentence may remain a sentence forever; a property may acquire nested structure; a structured value may eventually deserve independent Entity identity. Knowledge is currently modeled as relational and compositional: Concepts can be connected, reused and viewed through multiple contexts rather than copied into separate knowledge trees.

```text
Loose information -> Property/simple value -> Structured value -> Entity -> Relational network
```

Generic knowledge remains generic. Contextual relevance belongs to the relation/application. For example, App Mobile may require regulatory knowledge generically; Solducci becomes connected to that knowledge because it is a concrete mobile app. Whether GDPR is currently a blocker is contextual to Solducci, not intrinsic to GDPR.

## 7. Intentionality and progress

The system must distinguish curiosity from commitment without forcing a single workflow. An Idea may remain light indefinitely. Exploration helps clarify unknowns and scenarios. A Project exists when persistent identity, evolution, operational memory and realization structure become useful. Goal, Scenario, Milestone, Task and Trajectory describe progressively more concrete aspects of direction, but several remain Working/Open ontologically.

> **ESTABLISHED**  
> Idea -> Project promotion is controlled by the user. The system may recognize signals that an Idea is already being treated like a Project and offer the promotion as a mirror.

## 8. Time, experience and practice

Life OS samples experience rather than attempting exhaustive logging. Session is the current Working construct for a bounded lived activity sample; a Session may include Metrics, Observations, subjective comments and outputs when useful. Practice organizes repeated Sessions and supports trend/progression analysis.

Temporal Period is separate: it is an interval for aggregation or planning. Phase is also separate: it describes state, focus or stage and may cross one or more Temporal Periods.

## 9. Ceremonies: the operating rhythm

Ceremonies are periodic maintenance moments that make it unnecessary to hold the whole system in awareness continuously.

| Cadence | Primary purpose |
| --- | --- |
| Annual / Semiannual | Reflect on the person and life as a whole; update macro direction. |
| Monthly / Bimonthly | Review actual allocation, active projects, novelty and maintenance; define next-period commitments. |
| Weekly | Map real availability and create rails plus slot-compatible candidate actions. |
| Daily | Light reflection on what happened, feelings/observations and preparation for tomorrow. |

Planned vs Actual is treated as a reality check. A mismatch is data about estimation, desire, context, blockers or changing priorities - not a moral failure.

## 10. Self, Values and Resonance

The Self layer exists because direction is partly determined by resonance with values and interests. It remains intentionally lightweight. Current value themes include autonomy/self-determination, creativity/expression, understanding, growth, human connection, positive empowerment and participation in society. These are descriptive Working formulations, not a fixed hierarchy.

Values can potentially be Concepts; Interest may be a relation between Self and a Concept/Entity; Passion is Deferred because no distinct operation currently requires it.

## 11. Views and system intelligence

Views are contextual projections of one underlying structure. Useful lens dimensions include focus width, temporal distance, current mode and inactivity. The same Project can therefore have a compact execution view when active and a broad resume view after months of inactivity.

Signals are different from views. A signal is derived evidence such as emerging importance, long inactivity, imbalance, repeated observations, a consolidation opportunity, commitment mismatch or value-alignment tension. A suggestion is how the system presents that evidence and invites action.

> **RULE [ESTABLISHED]**  
> Signal != decision. Suggestion != automatic action. View != duplicate data.

## 12. Core feedback loops

### Intentional loop

```text
Values / Self-model -> Direction -> Goals / Commitments -> Weekly rails -> Sessions / Actions -> Metrics / Observations -> Retrospective -> updated Direction
```

### Epistemic loop

```text
Resource / Experience / Practice -> Observation -> Knowledge -> Application -> New Experience -> Refinement
```

### Self-awareness loop

```text
Declared intention -> lived behavior -> subjective experience -> retrospective -> updated understanding -> new intention
```

## 13. Case-study evidence

| Case | What it stress-tests |
| --- | --- |
| Solducci | Evolving Project, Idea/Feature structure, generic/contextual knowledge, progressive vision. |
| LaGenteStrana | Collaborative Project, entrepreneurial direction, evolving requirements. |
| Agrivoltaico | Long exploration, uncertainty, scenarios, knowledge gaps, commitment threshold. |
| HistoryExplorer | Low-intensity collaboration, delegation and cross-project learning synergy. |
| Speedcubing | Practice, Session, Metric, Observation, Knowledge structure and overlapping milestones. |
| Crochet | Inspiration as link, Idea->Project maturation, Artifact and reusable Knowledge. |

Second-wave domains still require stronger stress tests: health, relationships, bureaucracy, travel and recurring maintenance.

## 14. Epistemic status at checkpoint v0.1

| Status | Examples |
| --- | --- |
| Established | System as Mirror; Rails; Progressive Structuring; Derive not duplicate; Phase != Temporal Period; Project identity; user-controlled promotion. |
| Working | Session; Metric; Observation; Concept; Value-as-Concept; Ceremony session-like interpretation. |
| Deferred | Passion type; universal Hypothesis/Evidence; individual cube solve logging; exhaustive snapshots. |
| Open | Property vs Relation; Literal; Relation metadata; Capability formalization; Goal/Scenario/Trajectory; Phase representation; Self representation. |

## 15. Current frontier

> **NEXT [OPEN]**  
> Formalize Ontology Minimum v0.1 without breaking the behavior documented in this checkpoint. Begin with Entity, then Property/Literal vs Relation, promotion, relation metadata, capability-driven operations and Time.

Success means not merely producing a clean ontology, but preserving low friction, progressive structure, contextual reuse, derivation, resumability and user autonomy across all strong case studies.

## 16. Reading map

| If you need... | Read |
| --- | --- |
| Why / constraints | 02 - Context, Responsibilities & Design Principles |
| Information architecture | 03 - Information & Knowledge Model |
| Projects / goals / action | 04 - Intentionality & Progress Model |
| Sessions / practice / metrics | 05 - Time, Experience & Practice Model |
| Operating cadence | 06 - Planning & Ceremonies Model |
| Identity / values | 07 - Self, Values & Resonance Model |
| Views / signals | 08 - Views & System Intelligence Model |
| Concrete grounding | 09 - Case Studies |
| Why decisions emerged | 10 - Rationales & Design Evolution |
| What is decided/open | 11 - Decision Register & Open Questions |
| Where to continue | 12 - Ontology v0.1 Entry Point |
