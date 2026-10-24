# Life OS - Master Extraction v0.1

**Checkpoint boundary:** pre-Ontology Minimum v0.1  
**Purpose:** canonical intermediate extraction of context, requirements, principles, structures, decisions, hypotheses, examples, rationales and unresolved questions accumulated during the design conversation.

> This is a source document, not the final ontology, UI specification, database schema or implementation plan. It preserves the state of thought that the 13 checkpoint PDFs synthesize.

## 1. Context and motivation

Life OS is intended for a deliberately multidirectional life containing work, entrepreneurial projects, learning, hobbies, creative practices, health, relationships, experiences, logistics, bureaucracy and personal maintenance. The problem is not lack of interests but the simultaneous coexistence of many relevant directions.

Recurring frictions:

- ideas disappear before receiving a basic evaluation;
- paused projects become expensive to resume because context is lost;
- resources accumulate without distillation and knowledge can accumulate without application;
- attention drifts from declared priorities without becoming visible;
- long-horizon goals are either too vague or decomposed too early into brittle plans;
- planning can become more expensive than the work it supports;
- health, relationships, bureaucracy and maintenance compete for time while remaining invisible in traditional productivity systems;
- the Life OS itself has a maintenance cost that must remain justified.

### 1.1 Life landscape

- **Work:** employee role plus personal/entrepreneurial direction.
- **Health & survivor:** physical and mental health, self-care, finances, bureaucracy, logistics.
- **Relationships:** partner, friends, close people, maintenance and reconnection.
- **Experiences:** travel, events, social and exploratory experiences.
- **Hobbies & passions:** creative, cognitive, recreational and learning activities.

### 1.2 Representative interests and domains

Computer science, economics, finance, startups, product management, anthropology, technology, world energy/economic equilibria, music, piano, electronic music, TV, films, books, videogames, board games, Rubik's cube/speedcubing, sewing, crochet, beads, painting and other crafts, human interaction and progressive/non-traditional relationship structures.

### 1.3 Professional/entrepreneurial context

Computer Engineering background, Backend -> Fullstack Engineering, with the aim of progressively becoming an entrepreneur working across multiple products and collaborations. Projects may require simultaneous learning in business, economics, GDPR, privacy, security, publishing, infrastructure, product design and distribution.

## 2. System responsibilities

The canonical requirement set is preserved in `02_Context_Responsibilities_Design_Principles.pdf`.

- **SR01 - Whole-life map.** Rendere navigabile aree, progetti, conoscenze, interessi, responsabilita, relazioni, esperienze e direzioni senza tassonomia rigida.
- **SR02 - Conscious prioritization.** Presentare abbastanza contesto da permettere scelte consapevoli tra direzioni concorrenti senza delegare la decisione al sistema.
- **SR03 - Consistent progress.** Trasformare priorita dichiarate in avanzamento reale preservando flessibilita rispetto a energia, contesto e desiderio locale.
- **SR04 - Idea preservation and evaluation.** Cattura a bassissimo attrito, successiva revisione e almeno una valutazione prima che una buona idea scompaia.
- **SR05 - Attention alternation.** Alternare interessi e progetti senza perdere il senso di cosa sia avanzato e senza trattare la varieta come fallimento.
- **SR06 - Low-friction resume.** Mettere in pausa e riprendere entita con memoria operativa sufficiente: stato, struttura, decisioni, fase e next steps.
- **SR07 - Progressive decomposition.** Decomporre goal e progetti con dettaglio crescente verso il presente.
- **SR08 - Ceremony support.** Preparare e guidare retrospective, pianificazione e manutenzione con contesto, domande, blockers e materiali.
- **SR09 - Debt and imbalance detection.** Evidenziare consumo senza distillazione, knowledge senza azione, idee senza sviluppo e aree importanti trascurate.
- **SR10 - Synergy surfacing.** Rendere visibili collegamenti riutilizzabili tra progetti, conoscenze, skills, persone, esperienze e risorse.
- **SR11 - Emerging importance.** Segnalare quando una cosa sembra acquisire importanza attraverso ricorrenza, note, studio, idee, attivita o connessioni.
- **SR12 - Inactivity and parking management.** Rendere visibile l inattivita pesandola con importanza, commitment e cadenza attesa.
- **SR13 - Planned vs actual awareness.** Confrontare intenzione dichiarata e comportamento osservato come strumento di apprendimento, non di giudizio.
- **SR14 - Contextual action selection.** Negli slot liberi offrire azioni compatibili con durata, luogo, strumenti ed energia, filtrate dalle priorita scelte.
- **SR15 - Knowledge reuse.** Fare in modo che studio, esperienza e progetti producano conoscenza generalizzabile che riduca il lavoro futuro.
- **SR16 - Self-model reflection.** Supportare una rappresentazione leggera e revisionabile di valori, interessi, resonance, direzioni e vissuto.
- **SR17 - Life maintenance visibility.** Integrare salute, finanze, burocrazia, self-care, relazioni e logistica nel quadro complessivo.
- **SR18 - System maintenance awareness.** Rendere percepibile il costo del Life OS affinche la complessita non cresca oltre il valore prodotto.

## 3. Core design principles

- **DP01 - System as Mirror.** Il sistema osserva, organizza, confronta e suggerisce; la persona mantiene scelta e interpretazione.
- **DP02 - Rails, not rigid schedules.** Pianificazione come direzioni, allocazioni e azioni compatibili, non calendario minuto-per-minuto.
- **DP03 - Planned vs Actual is a reality check.** La distanza tra intenzione e realta e informazione, non giudizio morale.
- **DP04 - Progressive Structuring.** Struttura e informazione crescono solo quando emerge una necessita concreta.
- **DP05 - Complexity proportional to maturity.** Oggetti embrionali restano leggeri; schema e workflow crescono con maturita e uso.
- **DP06 - Derive, do not duplicate.** Informazioni derivabili affidabilmente non vanno memorizzate una seconda volta.
- **DP07 - One reality, many views.** Le viste sono proiezioni contestuali dello stesso modello sottostante.
- **DP08 - Formalization must earn its cost.** Ogni struttura deve giustificare costo cognitivo e manutenzione.
- **DP09 - Preserve unstructured lived experience.** Testo, sensazioni e vissuto non devono essere forzati in concetti rigidi.
- **DP10 - Revisable Self-model.** Valori e interpretazioni di se sono modelli correnti, non assiomi.
- **DP11 - Measure only when useful.** Misurare solo se sostiene decisione, confronto, apprendimento, consapevolezza o retrospective.
- **DP12 - Future abstract, present detailed.** La traiettoria aumenta di dettaglio avvicinandosi all azione.
- **DP13 - User-controlled promotion.** Il sistema puo proporre una promozione strutturale, ma la scelta significativa resta all utente.
- **DP14 - Avoid premature complexity.** Non modellare oggi complessita richiesta solo da scenari ipotetici futuri.
- **DP15 - Context belongs where it is true.** Lo stato specifico di un progetto vive nel contesto o relazione che lo rende vero.
- **DP16 - Past work should reduce future work.** Progetti, pratica ed esperienza devono poter produrre conoscenza riutilizzabile.
- **DP17 - Sampling over exhaustive logging.** Campionare momenti e risultati significativi invece di registrare ogni micro-evento.
- **DP18 - Emergence before taxonomy.** Categorie e schema possono essere scoperti dall uso; nessuna tassonomia perfetta iniziale.
- **DP19 - Make uncertainty visible.** Established, Working, Open, Deferred e Rejected devono restare distinguibili.
- **DP20 - Autonomy over optimization.** Il fine e aumentare consapevolezza e agency; l efficienza e solo uno strumento locale.

## 4. Temporal operating model and ceremonies

Life OS uses a nested cadence rather than a rigid schedule.

### Annual / semiannual

Retrospective on the previous period, major achievements, projects and areas grown, blockers, prediction quality, attention that now feels missing or wasted, desired goals/areas/knowledge/milestones, stimulating experiences, relationships, lessons and broad 6/12-month direction.

### Monthly / bimonthly (flexible cadence)

- show actual vs planned time/energy distribution;
- retrospective on what advanced, concluded, remained open or was abandoned;
- detailed summaries of the most active projects;
- show active projects, studies and explorations that can improve them;
- surface new/uncertain ideas to confirm, macerate or archive;
- choose next-period allocations (e.g. productive/recreational/social/maintenance and internal project weights);
- review life maintenance, relationships and upcoming events;
- surface long-inactive items;
- suggest maintenance when process imbalance appears (consumption without distillation, ideas without development, knowledge without action).

### Weekly

Review the previous week, estimate available time/days, define free-time slots by duration, location/resources and physical/mental energy, then prepare compatible actions from previously chosen priorities. The system creates rails, not a rigid calendar.

### Daily

Light end-of-day sample: what happened, how it went, how it felt, what is worth remembering and how to prepare mentally for tomorrow. It may be skipped or batched, but should not be delayed indefinitely.

### Ceremony philosophy

Broader ceremonies are important but postponable inside larger windows; daily reflection is lighter and recoverable. Planned vs actual is a reality check, not a failure score.

## 5. Views and lenses

Views are projections over the same underlying structure.

- **Temporal distance:** Vision <-> Task; detail increases toward action.
- **Focus width:** Person -> Area -> Project -> Milestone -> Phase -> Task.
- **Mode:** Exploration, Study, Execution, Practice, Reflection, Maintenance, etc.
- **Activity/inactivity:** recently active entities receive compact execution views; long-inactive entities receive broad resume/context reconstruction.

Project resume/vitrine should be able to show: short identity, milestones/structure, current phase, where work stopped, consolidated decisions/structures, blockers, relevant knowledge and immediate next actions.

## 6. Information architecture direction

### 6.1 Candidate primitives

Current candidates are **Entity**, **Relation**, **Property/Literal** and **Time**. This is a Working hypothesis, not yet the ontology.

### 6.2 Entity

Working definition: something with sufficient identity to be referred to, found, linked and potentially deepened independently.

### 6.3 Progressive structuring and promotion

A central mechanism is:

`raw text -> property/simple value -> structured value -> Entity -> network of Entities`

This is not a mandatory workflow. Promotion becomes useful when a value acquires independent reuse, incoming/outgoing links, nested structure, lifecycle, operations, queryability or a need for independent resume.

### 6.4 Relation

Relations connect entities and may carry contextual metadata. Example: generic GDPR knowledge is not globally a blocker; the Solducci<->GDPR contextual relation can be a blocker, partially addressed, relevant, etc.

### 6.5 Property -> capability -> operation

Operationality should not require attaching a complete fixed schema. Individual properties/relations permit operations: status permits transitions; scheduling permits placement; duration permits slot matching; temporal placement permits aggregation; metrics permit quantitative analysis.

### 6.6 Derivation

Do not persist facts that can be reliably derived. Example: a Session using a method that contains F2L does not necessarily need a second explicit Session->F2L relation. Progress can be derived from current composition where appropriate.

## 7. Knowledge model

- **Concept** is a candidate Entity type representing something known, being understood or independently deepen-able.
- **Knowledge** is currently understood as an organized relational family/network of Concepts, contents and relations rather than necessarily a duplicate container object.
- Generic knowledge stays context-independent; project/application-specific state belongs to contextual relations.
- Knowledge grows progressively from lists/text into richer linked structures.
- Resource is an external information object (book, article, video, paper, course, image, document, etc.) that can feed knowledge.
- Activities can generate knowledge, observations, metrics, artifacts, ideas and decisions; a simple `produced-by` mechanism may be more useful than many rigid output types.

### F2L example

F2L is structured knowledge/resolution step composed of algorithms and can be viewed through different method lenses (CFOP/Friedrich vs layer method) without duplicating the underlying entity. Aggregate knowledge/completion may be derived from constituent algorithms.

### App Mobile / GDPR example

`Solducci --is--> App Mobile`; generic `App Mobile --requires--> regulations/laws`; regulations contain GDPR/privacy/etc. Solducci-specific relevance or blocker state belongs to the application relation, not the generic concept.

## 8. Intentionality and progress

### Idea

Low-friction object for capturing something that may grow. It can contain notes, links, resources, requirements and subideas. User explicitly controls promotion to Project; the system may mirror that the idea is already being treated like one.

### Inspiration

No dedicated type is currently needed; inspiration may be a Resource or relation/connection between things.

### Project

Project passed the identity test: it needs intention, evolution, operational memory, decomposition, current state, resume and reusable outputs. Project structure may evolve; temporary containers may disappear or reform.

### Goal

Goal need not be a primitive type. It may begin as a property/simple value and become a structured entity if complexity justifies it. Its function is to define an end/condition, expose distance and support progress.

### Milestone

A meaningful checkpoint/portion of a Goal that reduces overload and focuses energy. Milestones can overlap or reorder as evidence changes.

### Task

A Task is deeper than a label: it is an entity with enough operational properties/capabilities to support status, scheduling, duration, blockers, resource readiness, etc. No fixed full schema is required.

### Scenario

A possible high-level configuration of an entity/goal. Multiple scenarios can share components or contain reusable sub-scenarios. Exact representation remains Open.

### Trajectory

Important but not formalized; likely a derived direction/decomposition from goal, milestones, phases and tasks with increasing detail toward the present.

### Exploration vs Commitment

Exploration is a mode/process used to discover value, unknowns, scenarios and conditions for moving forward. Commitment is the decision to dedicate time/energy/resources and may be modeled as a relation between an entity and a Temporal Period.

## 9. Time, experience and practice

### Session

Working definition: a moment/span of life of which the system takes a sample. Possible properties include temporal placement, involved entities, activity, comments, observations, feelings, metrics and outputs, none universally mandatory.

### Metric

Structured measurable sample of reality, often associated with a Session. Metrics are useful only when they improve awareness, decision or learning.

### Observation

Reflective information noticed during activity/experience. It need not be predefined; repeated use can cause the system to suggest it as an emergent schema element.

### Insight

A stronger summarizing/deductive understanding emerging from study, observations, knowledge creation or sessions. It may be semantic Knowledge; no mandatory Observation->Insight workflow.

### Practice

A process organizing sets of Sessions to maintain, observe and improve a capability. Practice can produce artifacts as well as skill growth.

### Temporal Period vs Phase

Established distinction: **Temporal Period != Phase**. A period says when/what interval is aggregated; a Phase says which configuration/stage/focus an entity is in. A project phase may cross planning periods and a planning period may contain several phases.

### Ceremony

A maintenance Session-like construct for self and system, with context presentation, reflection and decision/preparation workflow. Exact ontology is still Working.

## 10. Decision, commitment and planned-vs-actual

Decisions are often taken during ceremonies and can be treated as statements/acts that establish intentional relations between entities and planning periods. Commitment may be the temporal relation itself, carrying target, allocation or expected milestone. Retrospectives compare declared intention with observed behavior without turning the comparison into moral scoring.

## 11. Self, values, interests and resonance

The self-model must be light, emergent and revisable rather than a prerequisite taxonomy.

### Values currently expressed

Autonomy; creativity; freedom of expression; understanding; growth in a broad sense; human connection; giving one's essence space to express and expand.

### Interests currently expressed

Computer science, economics, music, TV series, books/knowledge, board games, videogames, Rubik's cubes, technology, people/human interactions, progressive relationship/family structures, energy/world equilibria, creative crafts, piano and electronic music.

### Emergent deeper themes

- **Autonomy / self-determination:** enough awareness of self/world to choose how to live rather than being governed by shallow inherited conventions.
- **Creativity / expression:** value in the autonomous mental process of figuring out, combining technical/creative capability and producing something personally meaningful.
- **Understanding:** local niches are lenses on the whole; recurring structures can transfer across domains.
- **Growth:** allowing experience to transform the person, worldview and future possibilities, not merely optimizing the current self.
- **Human connection:** shared moments build bonds and close people are irreplaceable lenses on reality.
- **Impact / empowerment:** improve people's agency, mental load, time and room to live/create rather than merely exploit needs for profitability.
- **Participation:** autonomy is not isolation; there is a desire to navigate society, know people and have positive, perceivable impact.

### Resonance

Value can remain a Concept; what matters is the relation between Self/other entities and those concepts. Interest may similarly be a temporal relation (`Me --interested-in--> Music`) rather than a rigid class. Passion is Deferred as a distinct type.

### Being <-> Acting

The system must preserve both self-knowledge/growth/connection and construction/achievement/participation/impact. Neither a pure output retrospective nor a pure introspective retrospective is sufficient.

## 12. System intelligence / mirror behavior

Signals the system may derive and present without deciding:

- Idea becoming Project-like;
- long inactivity weighted by importance/commitment;
- repeated observations;
- knowledge consolidation opportunities;
- repeated project-specific lessons becoming general knowledge;
- substantial investment without explicit commitment;
- resource consumption without distillation;
- knowledge without action;
- attention imbalance;
- declared intention vs behavior;
- recurring value resonance;
- synergies across projects/areas.

Signal != View != Decision. A signal is derived; a view presents context; the user decides.

## 13. Case studies preserved as conceptual tests

### Solducci

Shared-expense sheet evolved into a broader shared-resource mobile app. Stresses Project/Idea/Feature, generic vs contextual knowledge, progressive product vision, reuse and empowerment values. Vision pieces include Financial Hub, Spaces/Notes/Pantry/Shopping/Tasks, Canvas, Bento Dashboard, Context Manager, technical choices, GDPR/auth and publishing/infrastructure open points.

### LaGenteStrana

AI software-development tool with a close friend, emerging from parallel homemade workflow automation and shared discoveries. Stresses collaborative project identity, entrepreneurial value, evolving requirements and using the tool to discover its own missing capabilities.

### Agrivoltaico

Long-running entrepreneurial idea around land, agriculture and photovoltaic energy. Stresses exploration, scenarios, large knowledge gaps, feasibility/risk/capital, long-term parking and higher commitment thresholds.

### HistoryExplorer

Interactive history exploration tool with a friend; one brainstorming/wireframe session and low current commitment. Stresses lightweight collaboration, delegation and learning synergy with LaGenteStrana.

### Speedcubing

Stresses Practice, Session, Metric, Observation, knowledge composition and overlapping/reorderable milestones. Important metrics are session summaries (Single/Ao5/Ao12), not exhaustive per-solve logging. Current progression includes PLL, OLL, finger tricks, recognition/lookahead and F2L.

### Crochet

Inspiration links -> Idea -> progressively structured design -> Project -> artifact -> generalized reusable pattern/Knowledge. Demonstrates that past project work should reduce future work and that not every mistake deserves promotion to Knowledge.

### Future/second-wave stress tests

Health, relationships, bureaucracy, travel, recurring maintenance/routines, Area, Artifact and collaborative ownership/permissions remain deliberately underexplored.

## 14. Established decisions (checkpoint-level)

- System mirrors and proposes; it does not decide.
- Views are projections of shared underlying structure.
- Progressive structuring and derivation are core principles.
- Phase and Temporal Period remain distinct.
- Inspiration does not need a first-class type.
- Idea -> Project promotion remains user-controlled.
- Project deserves entity-level identity.
- Generic knowledge remains context-independent; contextual state belongs to application/relations.
- Operationality should emerge from properties/capabilities, not a mandatory full schema.
- Self-model remains revisable and values are not mandatory bootstrap configuration.

## 15. Strong Working hypotheses

- Primitive core may be Entity + Relation + Property/Literal + Time.
- Task and Session may be compositional behavior profiles rather than rigid storage classes.
- Goal can start as a property and be promoted.
- Commitment may be a temporal relation.
- Decision may be an event/act that creates intentional relations.
- Knowledge may be a graph/family rather than a container class.
- Value can be Concept; Interest can be a relation.
- Trajectory may be derived.
- Phase representation remains Working even though Phase != Temporal Period is Established.

## 16. Deferred / not modeled now

Passion as type; Hypothesis as universal type; Evidence as universal type; individual speedcube solves; exhaustive content snapshots; rigid self taxonomy; mandatory full Operational schema; forced value hierarchy; automatic Idea->Project promotion; automatic inference of behavior as true identity/values.

## 17. Open questions for Ontology Minimum v0.1

### Primitive ontology

- Is Property a primitive or syntactic sugar over Relation + Literal?
- What precisely qualifies as Entity?
- How rich can Relation be, and when can a relation gain independent identity?
- What represents raw/unstructured/literal content?
- How does promotion preserve references and history?

### Capabilities

- What formally is a Capability?
- Is capability declared or derived from schema?
- Where do Operations live: model, type/profile, system behavior or UI?
- Can an Entity adopt multiple behavior profiles?

### Knowledge

- Exact boundary between Concept and Knowledge.
- Whether Knowledge itself requires entity identity.
- Composition, mastery/progress derivation and contextual application.

### Time

- Exact ontology of Session, Temporal Period and Phase.
- Recurrence/cadence representation.
- Aggregation across nested temporal windows.

### Intentionality

- Goal identity and completion semantics.
- Scenario representation.
- Decision and Commitment representation.
- Trajectory representation.

### Self

- Is `Me` a normal Entity or a special root/context?
- How are values/interests revised and temporally dynamic?
- How much Self should be explicit?

### Views / intelligence

- How lenses are selected by context, mode, phase, inactivity and ceremony.
- Which signals can be derived reliably without over-measuring or annoying the user.

### Implementation

Deliberately deferred: storage, database, filesystem, graph DB, app architecture, UI, automation and AI mechanisms.

## 18. Rationale genealogies

- **Progressive Structuring:** App Mobile/GDPR -> F2L -> Crochet -> Goal.
- **Relational Knowledge:** regulations -> reusable generic concepts -> F2L across methods.
- **Project identity:** Solducci/LaGenteStrana/Agrivoltaico/HistoryExplorer.
- **Session:** speedcubing sampling -> generalization to development/crafts -> ceremony.
- **Phase vs Temporal Period:** planning windows vs project-development stages.
- **System as Mirror:** Idea promotion, inactivity, emerging knowledge, value/attention signals.
- **Self/Values:** Solducci impact -> creativity -> understanding -> connection -> growth -> participation.
- **Rails planning:** weekly variable-energy slots and the desire for local autonomy.

## 19. Documentation architecture

The checkpoint corpus is organized as:

`00 Re-entry` -> `01 Overview` -> `02 Foundation` -> models `03-08` -> `09 Case Studies` -> `10 Rationales` -> `11 Decisions/Open Questions` -> `12 Ontology Entry Point`.

Canonical ownership rule: one main home per fact; other documents summarize, contextualize or reference it. Epistemic markers are Established / Working / Exploratory / Open / Deferred / Rejected.

## 20. Current checkpoint boundary and next step

The checkpoint intentionally ends before formalizing the ontology. The next cycle should define and stress-test the smallest set of primitives beginning with **Entity**, then Property/Literal vs Relation, relation metadata, promotion, schema->capability->operation, Time, Session/Task/Concept/Project and finally the remaining composites.
