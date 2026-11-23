---
checkpoint: "Life OS v0.1"
document: "11"
title: "Decision Register & Open Questions"
canonical_pdf: "../11_Decision_Register_Open_Questions.pdf"
---

# 11 — Decision Register & Open Questions

**Decision Register  
& Open Questions**

Design governance and epistemic state - Checkpoint v0.1

| **Purpose** Preservare cosa e stato deciso, cosa e ancora Working, cosa e stato deliberatamente rinviato e quali domande devono restare aperte prima dell Ontologia Minimum v0.1. |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

| **Status**            | Governance / canonical design log                     |
|-----------------------|-------------------------------------------------------|
| **Reading mode**      | Evolution, decision recovery, uncertainty tracking    |
| **Canonical sources** | Master Extraction v0.1 §§101-105 plus Coverage Review |
| **Boundary**          | Pre-Ontology Minimum v0.1                             |

# 0. Governance rules

Il registro impedisce due errori opposti: dimenticare decisioni gia motivate e trasformare ipotesi esplorative in fatti retroattivamente consolidati.

- Established - decisione usata come base corrente.

- Working - modello corrente promettente, ancora da stressare.

- Exploratory - possibilita considerata ma non adottata.

- Open - problema riconosciuto senza soluzione.

- Deferred - deliberatamente rinviato; non significa sbagliato.

- Rejected - valutato e non adottato.

| **Evolution rule** Il Checkpoint v0.1 deve restare una fotografia fedele dello stato pre-ontologia. Le versioni future possono cambiare status, ma non devono riscrivere il passato come se le decisioni successive fossero gia inevitabili. |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

## 0.1 Decision summary

| **ID**   | **Title**                                      | **Status**  |
|----------|------------------------------------------------|-------------|
| **D001** | System as Mirror                               | Established |
| **D002** | Rails over rigid scheduling                    | Established |
| **D003** | Planned vs Actual is a reality check           | Established |
| **D004** | Progressive Structuring                        | Established |
| **D005** | Derive rather than duplicate                   | Established |
| **D006** | Phase is distinct from Temporal Period         | Established |
| **D007** | Inspiration is not first-class                 | Established |
| **D008** | User controls Idea -\> Project promotion       | Established |
| **D009** | Project deserves Entity-level identity         | Established |
| **D010** | Generic knowledge vs contextual state          | Established |
| **D011** | Operationality is capability-driven            | Established |
| **D012** | Self-model remains revisable                   | Established |
| **D013** | Session samples lived experience               | Working     |
| **D014** | Metric is structured measurement               | Working     |
| **D015** | Observation is optional and emergent           | Working     |
| **D016** | Concept as Knowledge Entity                    | Working     |
| **D017** | Value as Concept / Interest as relation        | Working     |
| **D018** | Ceremony as maintenance session-like construct | Working     |
| **D019** | Passion not modeled now                        | Deferred    |
| **D020** | Hypothesis/Evidence not universal types        | Deferred    |

# Part A - Decision Register

## D001 - System as Mirror

| **Status**       | Established                                                                                                                                                       |
|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | The system may observe, organize, compare, surface patterns and suggest interpretations, but it must not make value-laden life decisions on behalf of the person. |
| **Context**      | The user wants awareness and guidance without surrendering autonomy to an optimizer.                                                                              |
| **Rationale**    | Recurring across prioritization, Idea promotion, inactivity, value alignment and ceremony design.                                                                 |
| **Consequences** | Signals must be explainable and suggestions must preserve explicit choice.                                                                                        |
| **Revisit when** | If future automation needs to act autonomously in low-stakes operational domains.                                                                                 |
| **Related**      | DP01, SR02, SR11, SR16; Views & System Intelligence.                                                                                                              |

## D002 - Rails over rigid scheduling

| **Status**       | Established                                                                                                                      |
|------------------|----------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Planning should define directional rails, allocations and compatible actions rather than a minute-by-minute schedule by default. |
| **Context**      | Free time varies by duration, place, resources and physical/mental energy; local choice matters.                                 |
| **Rationale**    | Weekly planning can prepare compatible options while monthly/bi-monthly ceremonies choose higher-level commitments.              |
| **Consequences** | Scheduling is a tool, not the core ontology of intentional action.                                                               |
| **Revisit when** | If a domain genuinely benefits from exact scheduling or external deadlines require it.                                           |
| **Related**      | DP02; SR03, SR08, SR14; Planning & Ceremonies.                                                                                   |

## D003 - Planned vs Actual is a reality check

| **Status**       | Established                                                                                                                 |
|------------------|-----------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Compare declared intention with observed behavior to learn, not to label deviation as failure.                              |
| **Context**      | The system must help recalibrate estimates, priorities and self-understanding without turning plans into moral obligations. |
| **Rationale**    | Retrospective is a learning loop between intention, reality and subjective experience.                                      |
| **Consequences** | Analytics and ceremony language must avoid punitive interpretation.                                                         |
| **Revisit when** | If some domain requires compliance-style tracking rather than reflective planning.                                          |
| **Related**      | DP03; SR13; Planning & Ceremonies, Self Model.                                                                              |

## D004 - Progressive Structuring

| **Status**       | Established                                                                                                                                                  |
|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Information should be allowed to grow from loose text to property/value, structured value, Entity and relational network as complexity and utility increase. |
| **Context**      | GDPR/App Mobile, F2L, crochet ideas and Goal all showed that useful structure often emerges after initial capture.                                           |
| **Rationale**    | Upfront rigid schemas create boilerplate and force premature ontology decisions.                                                                             |
| **Consequences** | Promotion and schema growth become central mechanisms; simple things stay simple.                                                                            |
| **Revisit when** | If an implementation cannot support promotion without destructive migration.                                                                                 |
| **Related**      | DP04, DP05, DP18; Information & Knowledge; R01.                                                                                                              |

## D005 - Derive rather than duplicate

| **Status**       | Established                                                                                                                              |
|------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Do not store information as independent truth when it can be derived reliably from existing structure.                                   |
| **Context**      | Examples include F2L progress from algorithms, project completion from current vision, and inherited relevance through generic concepts. |
| **Rationale**    | Reduces inconsistency, maintenance and semantic drift.                                                                                   |
| **Consequences** | Derived values need explainable provenance and recomputation rules.                                                                      |
| **Revisit when** | When derivation is too expensive, unstable or context-dependent to reproduce reliably.                                                   |
| **Related**      | DP06; Information & Knowledge; R11.                                                                                                      |

## D006 - Phase is distinct from Temporal Period

| **Status**       | Established                                                                                                                         |
|------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Phase describes configuration, focus or development stage; Temporal Period describes when. They may overlap but are not equivalent. |
| **Context**      | Monthly/bimonthly planning windows and project phases do not necessarily start/end together.                                        |
| **Rationale**    | Separating them preserves semantic correctness and allows project phases to cross planning windows.                                 |
| **Consequences** | Future ontology must relate rather than merge the two constructs.                                                                   |
| **Revisit when** | If later evidence shows Phase is merely a relation/state and not an Entity; distinction in meaning should still remain.             |
| **Related**      | Time & Experience; Intentionality & Progress; R06.                                                                                  |

## D007 - Inspiration is not first-class

| **Status**       | Established                                                                                          |
|------------------|------------------------------------------------------------------------------------------------------|
| **Decision**     | Do not introduce Inspiration as a dedicated Entity type in the current model.                        |
| **Context**      | Crochet/Pinterest showed inspiration can be an image/resource or simply a connection between things. |
| **Rationale**    | No distinct lifecycle or operation currently justifies a dedicated type.                             |
| **Consequences** | Use Resource/Entity plus semantic relation such as inspires when useful.                             |
| **Revisit when** | If repeated workflows require independent lifecycle, status or queries for inspiration objects.      |
| **Related**      | Crochet case; Deferred concepts.                                                                     |

## D008 - User controls Idea -\> Project promotion

| **Status**       | Established                                                                                                          |
|------------------|----------------------------------------------------------------------------------------------------------------------|
| **Decision**     | The system can mirror that an Idea behaves like a Project, but meaningful promotion remains an explicit user choice. |
| **Context**      | Signals such as repeated edits, references, research, task creation and time investment may indicate maturation.     |
| **Rationale**    | Preserves autonomy and avoids turning system inference into commitment.                                              |
| **Consequences** | Promotion UI should be suggestive, not automatic; historical context should be preserved.                            |
| **Revisit when** | If user explicitly opts into auto-promotion for a narrow domain.                                                     |
| **Related**      | DP01, DP13; SR04; Intentionality & Progress.                                                                         |

## D009 - Project deserves Entity-level identity

| **Status**       | Established                                                                                                                         |
|------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Project is treated as something with identity, intention, evolution, operational memory and reusable structure.                     |
| **Context**      | Solducci, LaGenteStrana, Agrivoltaico and HistoryExplorer all require resumption, decomposition and state beyond a simple property. |
| **Rationale**    | Removing Project identity loses continuity, lifecycle and navigability.                                                             |
| **Consequences** | Project may still be compositional rather than a rigid storage class.                                                               |
| **Revisit when** | If ontology later expresses Project entirely through capabilities without a semantic type; identity requirement remains.            |
| **Related**      | SR03, SR06; Intentionality & Progress; R04.                                                                                         |

## D010 - Generic knowledge is separate from contextual state

| **Status**       | Established                                                                                                                                                           |
|------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Generic Knowledge stays context-independent; relevance, blocker status, addressed state and project-specific decisions belong to the contextual application/relation. |
| **Context**      | App Mobile requires regulations generically; GDPR is not globally a Solducci blocker, but the Solducci-GDPR relation can be.                                          |
| **Rationale**    | Avoids duplicating generic concepts and contaminating them with project-specific truth.                                                                               |
| **Consequences** | Relations or contextual objects must be able to carry metadata/state.                                                                                                 |
| **Revisit when** | If some contextual state proves intrinsic to a specialized Concept rather than relation metadata.                                                                     |
| **Related**      | DP15; Information & Knowledge; R03.                                                                                                                                   |

## D011 - Operationality is capability-driven

| **Status**       | Established                                                                                                                                             |
|------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Do not require an Entity to adopt a complete Operational schema. Properties/relations should enable the operations that depend on them.                 |
| **Context**      | A Task-like thing may need status for transitions, duration for slot matching or schedule for calendar placement, without needing every possible field. |
| **Rationale**    | Supports compositional behavior and progressive complexity.                                                                                             |
| **Consequences** | Ontology must explore schema -\> capability -\> operation and avoid all-or-nothing inheritance.                                                         |
| **Revisit when** | If capability discovery becomes too implicit or ambiguous for implementation.                                                                           |
| **Related**      | DP04, DP05, DP08; Capability System; R10.                                                                                                               |

## D012 - Self-model remains revisable

| **Status**       | Established                                                                                                                        |
|------------------|------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Values, interests and interpretations of identity are current models, not immutable truths or mandatory bootstrap taxonomy.        |
| **Context**      | Reflections on autonomy, creativity, understanding, growth, connection and impact showed values can emerge through lived examples. |
| **Rationale**    | A system intended to increase awareness should not make current convictions into controlling axioms.                               |
| **Consequences** | Ceremonies can surface discrepancies between declared model, behavior and subjective experience.                                   |
| **Revisit when** | If user explicitly chooses stable commitments/values that should be treated as constraints for a period.                           |
| **Related**      | DP10, DP20; SR16; Self, Values & Resonance.                                                                                        |

# Part A.2 - Working decisions / current interpretations

## D013 - Session samples lived experience

| **Status**       | Working                                                                                                          |
|------------------|------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Session currently means a bounded moment/activity of life that the system samples rather than exhaustively logs. |
| **Context**      | Speedcubing required retaining activity, metrics and observations without copying every solve from cstimer.      |
| **Rationale**    | Generalizes to development, crochet and ceremonies.                                                              |
| **Consequences** | Need to formalize relation to Temporal Period, Activity and Ceremony.                                            |
| **Revisit when** | After Time ontology stress test.                                                                                 |
| **Related**      | Time & Experience; Speedcubing; R05.                                                                             |

## D014 - Metric is structured measurement

| **Status**       | Working                                                                                                |
|------------------|--------------------------------------------------------------------------------------------------------|
| **Decision**     | Metric is a structured datum that samples a measurable aspect of reality, often attached to a Session. |
| **Context**      | Single, Ao5 and Ao12 are useful session-level measures distinct from qualitative observations.         |
| **Rationale**    | Allows quantitative analysis without making Session itself purely metric.                              |
| **Consequences** | Need to define measurement schema, units and aggregation only when required.                           |
| **Revisit when** | When multiple metric domains are modeled.                                                              |
| **Related**      | Time & Experience; Speedcubing.                                                                        |

## D015 - Observation is optional and emergent

| **Status**       | Working                                                                                                                    |
|------------------|----------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Observation is reflective content about something noticed; it should not be a mandatory property on all relevant entities. |
| **Context**      | Users may add observations only when meaningful; repeated use may justify schema suggestions or queries.                   |
| **Rationale**    | Supports emergent schema and low-friction capture.                                                                         |
| **Consequences** | Need to determine whether Observation is a semantic property, Entity, note role or relation pattern.                       |
| **Revisit when** | During ontology tests for raw content and Entity promotion.                                                                |
| **Related**      | DP18; Time & Experience.                                                                                                   |

## D016 - Concept as Knowledge Entity

| **Status**       | Working                                                                                                                                |
|------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Concept is the leading candidate Entity type for structured Knowledge: something known, being understood or independently deepen-able. |
| **Context**      | F2L, GDPR, App Mobile and Values all behave like referencable reusable concepts.                                                       |
| **Rationale**    | Knowledge may be a network/family of Concepts rather than a separate duplicated container.                                             |
| **Consequences** | Need to test identity threshold, composition and literal/raw content.                                                                  |
| **Revisit when** | Information ontology formalization.                                                                                                    |
| **Related**      | Information & Knowledge; R02.                                                                                                          |

## D017 - Value as Concept; Interest as relation

| **Status**       | Working                                                                                                                                      |
|------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Personal Values may be Concepts related to Self; Interests may be relations between Self and Concepts/Entities rather than rigid types.      |
| **Context**      | Music is not intrinsically an Interest; it is something the person is interested in. Autonomy can be a Concept that resonates with projects. |
| **Rationale**    | Keeps identity model compositional and dynamic.                                                                                              |
| **Consequences** | Need to define Self and temporal/intensity metadata.                                                                                         |
| **Revisit when** | Self ontology test.                                                                                                                          |
| **Related**      | Self, Values & Resonance; R09.                                                                                                               |

## D018 - Ceremony as maintenance session-like construct

| **Status**       | Working                                                                                                                                         |
|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| **Decision**     | Ceremony is currently understood as a structured maintenance session for self/system, with context presentation, reflection and decision steps. |
| **Context**      | Daily/weekly/monthly/annual ceremonies all have temporal placement and experiential sampling, but also elaborate workflow and planning outputs. |
| **Rationale**    | This interpretation unifies experience and maintenance while preserving ceremony-specific behavior.                                             |
| **Consequences** | Need to avoid equating Ceremony with the Planning Period it governs.                                                                            |
| **Revisit when** | Time/Ceremony formalization.                                                                                                                    |
| **Related**      | Planning & Ceremonies; Time & Experience.                                                                                                       |

# Part B - Deferred / deliberately not modeled now

| **Deferred does not mean rejected** These concepts may become useful later. The current decision is that they do not yet justify dedicated ontology or workflow cost. |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|

## D019 - Passion as dedicated type

**Why deferred:** Passion appears derivable from interest, resonance, investment over time, motivation and identity; no unique operation currently requires a type.

**Revisit when:** If passion-specific lifecycle, ceremony behavior or queries become necessary.

## D020 - Hypothesis / Evidence as universal types

**Why deferred:** Hypotheses may be useful in entrepreneurial exploration but feel unnecessary in low-commitment hobbies; Evidence has not shown distinct universal value.

**Revisit when:** If formal exploration/scientific decision workflows become recurrent.

## Individual speedcube solve tracking

**Why deferred:** cstimer already owns detailed solve data; Life OS needs session summaries and observations, not duplication.

**Revisit when:** If a dedicated statistical study requires solve-level integration.

## Exhaustive content snapshots

**Why deferred:** Historical value lies primarily in structural evolution; full snapshots create overhead and duplication.

**Revisit when:** If auditability or legal/history requirements appear.

## Rigid self taxonomy

**Why deferred:** Values and interests should emerge and remain revisable.

**Revisit when:** If a later stable classification produces concrete operation benefits.

## Mandatory complete Operational schema

**Why deferred:** Capabilities should emerge from properties actually needed.

**Revisit when:** If implementation requires explicit profiles for validation/performance.

## Automatic Idea -\> Project promotion

**Why deferred:** System should mirror and suggest, not declare commitment.

**Revisit when:** Only under explicit opt-in for a narrow workflow.

# Part C - Working Hypotheses

These are useful starting points for Ontology Minimum v0.1, not decisions to preserve at all costs.

| **ID**   | **Hypothesis**                           | **Current formulation**                                                                                                                          |
|----------|------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| **H001** | **Primitive core**                       | Entity, Relation, Property/Literal and Time may be sufficient as a minimal primitive base.                                                       |
| **H002** | **Compositional semantic profiles**      | Task, Session and possibly Project may combine semantic identity with capability/property profiles rather than rigid class inheritance.          |
| **H003** | **Relation metadata**                    | Relations may carry contextual state such as relevance, blocker, coverage or target.                                                             |
| **H004** | **Goal promotion**                       | Goal may begin as a property/simple statement and become structured/Entity only when independent identity becomes useful.                        |
| **H005** | **Commitment relation**                  | Commitment may be represented as a relation between Entity and Temporal Period with target/allocation metadata.                                  |
| **H006** | **Decision as act/event**                | Decision may be better understood as the act that creates/changes intentional relations, while its statement may be preserved for retrospective. |
| **H007** | **Knowledge as graph/family**            | Knowledge may be an organized network of Concepts/content/relations, not necessarily a separate container object.                                |
| **H008** | **Trajectory as derived structure**      | Trajectory may emerge from Goal + Milestones + Phases + Tasks rather than requiring first-class identity.                                        |
| **H009** | **Self as graph root or special Entity** | The model needs an explicit representation of Me/Self, but it is not yet clear whether this is a normal Entity or system root/context.           |
| **H010** | **Emergent schema learning**             | Repeated properties/relations in similar contexts may be observed by the system and proposed as reusable schema/capabilities.                    |

# Part D - Open Questions Register

The following questions are intentionally unresolved. Ontology work should answer them only through concrete tests against the requirements and case-study corpus.

## OQ-A - Primitive Ontology

**OQ-A01** What qualifies as an Entity strongly enough to justify independent identity?

**OQ-A02** Is Property a primitive, or syntactic sugar over Relation + Literal?

**OQ-A03** How should raw/unstructured text and literals be represented?

**OQ-A04** How rich can Relation become before it should itself be promotable to Entity?

**OQ-A05** Can Relations have identity/history independently of their endpoints?

**OQ-A06** What are the formal rules and user experience of Entity promotion?

## OQ-B - Capability System

**OQ-B01** How are properties/relations mapped to capabilities?

**OQ-B02** Are capabilities declared, derived or both?

**OQ-B03** Where do operations live: ontology, schema/profile, application layer or view?

**OQ-B04** Can an Entity adopt multiple behavior profiles without conflicting semantics?

**OQ-B05** How should required vs optional properties be expressed without recreating rigid classes?

## OQ-C - Knowledge

**OQ-C01** What exactly distinguishes Concept from Knowledge?

**OQ-C02** Does Knowledge itself need Entity identity or is it a family/network role?

**OQ-C03** How are nested/composed Concepts represented without imposing a taxonomy?

**OQ-C04** How is mastery/progress derived from subparts and current scope?

**OQ-C05** How is generic Knowledge applied to concrete entities while keeping contextual state separate?

**OQ-C06** When does an Observation or project lesson become reusable Knowledge?

## OQ-D - Time & Experience

**OQ-D01** What is the minimal formal structure of Session?

**OQ-D02** What is the exact role of Temporal Period?

**OQ-D03** What is Phase ontologically: Entity, relation/state, structured property or something else?

**OQ-D04** How do Phases overlap Temporal Periods and Sessions?

**OQ-D05** How should recurrence/cadence be represented for maintenance and ceremonies?

**OQ-D06** Should subjective experience remain mostly raw content, or does some recurring schema earn a place?

## OQ-E - Intentionality

**OQ-E01** When is Goal a simple property and when an Entity?

**OQ-E02** How is Goal completion represented and derived?

**OQ-E03** Is Scenario an Entity, structured Goal, graph fragment or view?

**OQ-E04** What exactly makes a Milestone different from a smaller Goal?

**OQ-E05** How should Task semantic identity interact with capability-driven operationality?

**OQ-E06** Is Commitment best modeled as relation, allocation object or temporal edge?

**OQ-E07** Does Decision need persistent Entity identity or only preserved statement/provenance?

**OQ-E08** Can Trajectory remain fully derived?

## OQ-F - Self

**OQ-F01** What is Me/Self in the graph?

**OQ-F02** How much personal identity should be explicit before maintenance becomes intrusive?

**OQ-F03** How are Values revised over time without turning revision into administrative work?

**OQ-F04** How should resonance be represented and contextualized?

**OQ-F05** How should Interest intensity/recency evolve temporally?

**OQ-F06** How should the system present discrepancies between declared values and behavior without over-interpreting them?

## OQ-G - Views & Intelligence

**OQ-G01** How is the preferred lens selected: context, phase, mode, inactivity, ceremony or user choice?

**OQ-G02** Which signals are sufficiently reliable to derive automatically?

**OQ-G03** How should importance weight inactivity without producing noisy reminders?

**OQ-G04** How can imbalance be estimated without over-measuring life?

**OQ-G05** How can suggestions remain explainable and non-annoying?

**OQ-G06** How are synergies surfaced without generating an overwhelming graph of weak connections?

## OQ-H - Under-tested domains

**OQ-H01** Does the model fit Health without turning care into a Project by default?

**OQ-H02** Can Relationships be represented without scoring or bureaucratizing people?

**OQ-H03** How do Bureaucracy and recurring obligations fit Task/Period/recurrence models?

**OQ-H04** Is Travel better represented as temporary Project, Experience structure, or a composition?

**OQ-H05** How should recurring maintenance debt and cadence work?

**OQ-H06** Do collaborative projects require ownership/permission concepts in the personal model?

## OQ-I - Implementation (intentionally deferred)

**OQ-I01** What storage architecture best supports progressive promotion and relational queries?

**OQ-I02** What parts belong in notes/files versus structured database?

**OQ-I03** What UI best supports progressive disclosure and multiple views?

**OQ-I04** What should AI derive automatically versus only suggest?

**OQ-I05** How should external tools such as calendar, trackers or source apps integrate without duplication?

# Part E - Current design frontier

| **Frontier** The next cycle is Ontology Minimum v0.1. It should not try to answer every open question. It should identify the smallest primitive/compositional model that survives the strongest case studies and preserves the foundation principles. |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

## Recommended investigation order

1.  Define Entity precisely enough to be operational.

2.  Test Property vs Relation and introduce Literal/raw content.

3.  Define Relation and contextual metadata.

4.  Define Entity promotion.

5.  Formalize schema -\> capability -\> operation.

6.  Introduce Time.

7.  Stress-test Session.

8.  Stress-test Task.

9.  Stress-test Concept/Knowledge.

10. Stress-test Project.

11. Test Goal/Milestone/Scenario/Trajectory.

12. Test Temporal Period/Phase/Commitment/Decision.

13. Run all six primary case studies.

14. Run secondary life-maintenance tests.

15. Remove any primitive or type that is not earning its cost.

## Success criteria

- Represent strong cases naturally, not merely technically.

- Keep simple entities lightweight.

- Support progressive depth without destructive migration.

- Avoid redundant state when derivation is reliable.

- Represent contextual truth correctly.

- Enable resume after inactivity.

- Preserve user autonomy in promotion, prioritization and self-interpretation.

- Keep maintenance cost proportional to value.

- Leave unresolved questions visibly unresolved when evidence is insufficient.
