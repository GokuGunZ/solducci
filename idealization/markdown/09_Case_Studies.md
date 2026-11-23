---
checkpoint: "Life OS v0.1"
document: "09"
title: "Case Studies"
canonical_pdf: "../09_Case_Studies.pdf"
---

# 09 — Case Studies

Reality grounding and conceptual stress tests - Checkpoint v0.1

| **Purpose** Preservare i casi reali che hanno generato il modello, cosi che le future astrazioni possano essere verificate contro comportamenti, frizioni e bisogni concreti. |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

| **Status**            | Foundation / evidence corpus                                                 |
|-----------------------|------------------------------------------------------------------------------|
| **Reading mode**      | Reality grounding / stress tests                                             |
| **Canonical sources** | Master Extraction v0.1 §§60-74, §107                                         |
| **Cases**             | Solducci, LaGenteStrana, Agrivoltaico, HistoryExplorer, Speedcubing, Crochet |

*Case studies are not implementation specifications. They preserve the lived problem before theory and identify what future ontology must be able to represent.*

# 0. How to use the case studies

Questi casi funzionano come integration tests concettuali: quando un modello cambia, deve essere possibile tornare qui e verificare se il comportamento reale resta rappresentabile senza boilerplate o special case arbitrari.

- Preservare il comportamento naturale prima della formalizzazione.

- Separare frizione reale da soluzione ipotizzata.

- Registrare i concetti emersi dal caso, senza trasformarli automaticamente in primitive.

- Mantenere anche cio che si e deciso di non modellare.

- Usare le stress-test questions per Ontology Minimum v0.1 e versioni successive.

## 0.1 Coverage and current gaps

| **Strong coverage**          | Solducci, Speedcubing                                             |
|------------------------------|-------------------------------------------------------------------|
| **Good coverage**            | Crochet, Agrivoltaico                                             |
| **Medium coverage**          | LaGenteStrana, HistoryExplorer                                    |
| **Future second-wave tests** | Health, Relationships, Bureaucracy, Travel, Recurring maintenance |

# CS01 - Solducci

Da shared-expense tracker a piattaforma per la gestione di risorse condivise; caso principale per Project, Idea, Knowledge contestuale e visione progressiva.

| **WORKING** | Reality-grounding case study. The representation below preserves observed behavior before final ontology formalization. |
|-------------|-------------------------------------------------------------------------------------------------------------------------|

## 1. Why this case matters

- Nasce da un bisogno reale e immediato, poi espande la propria identita nel tempo.

- Combina utilita personale, design di prodotto, imprenditorialita e apprendimento tecnico/normativo.

- Produce molti livelli di struttura: visione, feature, open points, idee, knowledge, implementation e reusable patterns.

## 2. Natural behavior before the system

- Origine in un Google Sheet condiviso per tracciare spese con la partner.

- Trasformazione progressiva in app e poi in idea piu ampia di gruppi e spazi condivisi.

- Le nuove feature emergono da bisogni, brainstorming, sinergie e osservazione di come il prodotto potrebbe ridurre boilerplate nella vita.

- Le idee vengono annotate con granularita variabile e possono macerare prima di entrare in backlog.

## 3. Original friction

- Visione ampia con idee sparse e componenti temporanei che cambiano forma.

- Knowledge generica (mobile app, GDPR, security, publishing) si intreccia con blocker specifici di Solducci.

- Difficolta nel vedere contemporaneamente stato consolidato, open points, next steps e future possibilities.

- Rischio di duplicare conoscenza generica dentro ogni progetto.

## 4. Desired support

- Project vitrine con identita, fase corrente, milestone, stato consolidato e next actions.

- Visione componibile in aree/feature che possano apparire, fondersi o essere archiviate senza perdere memoria strutturale.

- Collegare generic Knowledge e mostrare, con gli occhi di Solducci, quali parti sono rilevanti o blocker.

- Idea Inbox con crescita progressiva delle idee e promozione volontaria quando diventano abbastanza concrete.

- Post-implementation comparison tra aspettative, realta e requisiti ancora non implementati.

## 5. Information and entities involved

- Project: Solducci.

- Vision/Product components: Financial Hub, Spaces, Notes, Pantry, Shopping, Tasks, Canvas, Bento Dashboard, Context Manager.

- Generic Concepts: App Mobile, GDPR, authentication, privacy/data handling, publishing standards, backend/resource distribution.

- Ideas con body, sub-ideas, screenshots, requirements, advantages, KPI links e feature influence.

- Technical choices and design patterns come knowledge/progetto riutilizzabile.

## 6. Processes and activities

- Feature ideation tramite domande ricorrenti: cosa voglio ottenere, come, quale interazione umana, come integra, quali sinergie.

- Exploration di open points e knowledge gaps.

- Execution attraverso backlog, milestone, task e development sessions.

- Retrospective/post-mortem su implementazione vs aspettative.

- Extraction di reusable knowledge e pattern.

## 6.1 Current vision sample

- Financial Area / Hub.

- Spaces come contenitore temporaneo di Notes, Pantry, Shopping Lists e Tasks.

- Canvas come note-file system.

- Bento widget homescreen.

- Context Manager come infrastruttura di contesto selezionato persona/gruppo.

## 7. Concepts this case helped discover

- Project come Entity con identity, evolution, operational memory e progressive decomposition.

- Generic Knowledge separata dal contextual state: GDPR non e globalmente blocker; Solducci-GDPR puo esserlo.

- Relation metadata per relevance, blocker, addressed/partial.

- Progressive structuring e Entity promotion.

- Structural history: preservare la struttura passata senza snapshot completi del contenuto.

- Goal/progress relativo alla visione corrente.

## 8. Deliberately not modeled

- Snapshot completi di ogni versione del contenuto.

- Schema rigido e definitivo delle feature.

- Duplicazione di tutte le regole mobile dentro Solducci.

- Promozione automatica delle idee a Project/Feature.

## 9. Ontology stress-test questions

- Un Entity/Relation model minimo riesce a rappresentare App Mobile come conoscenza generica e Solducci come caso concreto senza duplicazione?

- Una feature temporanea puo essere riorganizzata mantenendo una memoria strutturale utile?

- Goal, Scenario, Milestone e Phase possono essere distinti senza introdurre troppi tipi?

- Relation metadata e sufficiente per rappresentare relevance, blocker e partial coverage?

# CS02 - LaGenteStrana

AI software-development tool costruito con un amico stretto; caso per collaborazione, progetto ad alto valore e requirements che emergono dall uso.

| **WORKING** | Reality-grounding case study. The representation below preserves observed behavior before final ontology formalization. |
|-------------|-------------------------------------------------------------------------------------------------------------------------|

## 1. Why this case matters

- Rappresenta la direzione imprenditoriale e il desiderio di aumentare autonomia attraverso automazione.

- E collaborativo e nasce da pratiche gia esistenti, non da un idea astratta isolata.

- Il tool puo essere usato per scoprire le proprie funzionalita mancanti, creando un loop progetto-strumento.

## 2. Natural behavior before the system

- Entrambi i collaboratori automatizzavano separatamente workflow software.

- Condivisione di scoperte, brainstorming e repository fino all emergere di un vero Project.

- La priorita attuale e raggiungere un punto realmente utilizzabile.

- Molte idee rimangono sparse e vengono valutate attraverso il valore che aggiungono all uso concreto.

## 3. Original friction

- Idee eterogenee e evolving requirements.

- Need to preserve shared context without forcing excessive project administration.

- Learning e execution si alimentano reciprocamente.

- Priorita alta ma molte possibili direzioni tecniche/prodotto.

## 4. Desired support

- Resume chiaro del progetto e current missing functionality.

- Milestone e next actions vicino al presente, visione piu astratta sul futuro.

- Collegamenti con knowledge e lessons utili anche ad altri software projects.

- Rappresentazione del contributo collaborativo senza trasformare il Life OS in project-management enterprise.

## 5. Information and entities involved

- Project, collaborators, repositories, ideas, features, technical knowledge, blockers, usage observations.

- Potential relations to other projects that can learn from LaGenteStrana.

## 6. Processes and activities

- Collaborative exploration.

- Dogfooding / use-driven discovery.

- Execution and iteration.

- Knowledge extraction and transfer.

## 7. Concepts this case helped discover

- Project identity can emerge from repeated activity and shared commitment.

- System should surface synergies between projects.

- Current phase and missing functionality are valuable resume signals.

## 8. Deliberately not modeled

- Fine-grained permissions, ownership or enterprise collaboration model at this checkpoint.

- Full issue-tracker replacement.

## 9. Ontology stress-test questions

- Can the ontology represent collaboration lightly, without making every relationship a workflow object?

- Can observations generated while using the tool become ideas or knowledge without forced typing?

- Can project-to-project learning be represented as relations rather than duplication?

# CS03 - Agrivoltaico

Idea imprenditoriale ad alta incertezza e alto commitment potenziale; caso principale per Exploration, Scenario, knowledge gaps e parking.

| **WORKING** | Reality-grounding case study. The representation below preserves observed behavior before final ontology formalization. |
|-------------|-------------------------------------------------------------------------------------------------------------------------|

## 1. Why this case matters

- Dimostra che una cosa puo essere importante per anni senza essere attivamente eseguita.

- Richiede competenze lontane dal dominio professionale corrente e investimenti rilevanti.

- La decisione di commitment dovrebbe richiedere piu evidenza e reality check rispetto a un hobby economico.

## 2. Natural behavior before the system

- Pensiero intermittente per mesi/anni, con poche note e molta elaborazione mentale.

- L idea ritorna per attrazione verso sostenibilita, profitto, scalabilita e accessibilita.

- Viene spesso deprioritizzata per mancanza di competenze, capitale e spazio mentale.

## 3. Original friction

- Manca una visione completa delle parti da comprendere.

- Knowledge gaps non sono visibili in modo strutturato.

- L inattivita puo far sembrare il progetto dimenticato anche quando resta significativo.

- Rischio di studiare casualmente senza raggiungere una soglia di decisione.

## 4. Desired support

- Exploration view con domande, unknowns, resource paths e scenarios.

- Macro decomposition: agricoltura, fotovoltaico, distribuzione energia, terreno, finanziamento.

- Commitment threshold esplicito: quali informazioni/condizioni servono prima di investire seriamente.

- Parking che preservi il quadro e faccia emergere il tema quando torna rilevante.

## 5. Information and entities involved

- Idea/Project candidate, scenarios, domain concepts, resources, financial assumptions, land, regulation, energy distribution, risks, required skills.

## 6. Processes and activities

- Exploration.

- Scenario comparison.

- Feasibility study.

- Knowledge acquisition.

- Long-term parking and periodic review.

## 7. Concepts this case helped discover

- Exploration as mode/process rather than universal Entity.

- Scenario as alternative high-level configuration.

- Large commitments require stronger evidence/reality checks.

- Importance-weighted inactivity.

## 8. Deliberately not modeled

- Hypothesis or Evidence as mandatory universal types.

- Detailed financial model before the project reaches that maturity.

- Automatic commitment based on recurring interest.

## 9. Ontology stress-test questions

- Can an entity remain in Exploration for years without becoming a Project full of empty fields?

- Can scenarios share substructures rather than duplicate entire trees?

- Can parking preserve significance while avoiding noisy reminders?

- Can required knowledge be shown as contextual gaps without contaminating generic concepts?

# CS04 - HistoryExplorer

Interactive history exploration tool with a history-enthusiast friend; case for low-intensity collaboration, delegation and synergy.

| **WORKING** | Reality-grounding case study. The representation below preserves observed behavior before final ontology formalization. |
|-------------|-------------------------------------------------------------------------------------------------------------------------|

## 1. Why this case matters

- Shows a project that is meaningful but intentionally low effort.

- Value includes fun, learning and niche empowerment, not only entrepreneurship.

- May be handed off after initial setup, testing whether the model tolerates asymmetric commitment.

## 2. Natural behavior before the system

- One brainstorming session generated ideas and wireframes.

- Potential plan: create the initial setup and let the friend carry more development.

- Can generate learning useful for LaGenteStrana.

## 3. Original friction

- Too much formal project management would cost more than the project deserves.

- Need to preserve brainstorming and resumption context despite low activity.

- Need to express that ownership/effort may differ between collaborators.

## 4. Desired support

- Very light Project representation.

- Clear current state and next enabling action.

- Links to transferable knowledge and other projects.

- Ability to remain dormant without appearing broken.

## 5. Information and entities involved

- Project, collaborator, wireframes, ideas, initial setup, learning links.

## 6. Processes and activities

- Brainstorming/exploration.

- Light execution.

- Delegation/handoff.

- Knowledge transfer.

## 7. Concepts this case helped discover

- Complexity must be proportional to commitment and maturity.

- A Project can be real even with low cadence.

- Synergy is a first-class system responsibility even if not a first-class ontology type.

## 8. Deliberately not modeled

- Detailed ownership model.

- Heavy recurring ceremony specific to the project.

## 9. Ontology stress-test questions

- Can Project exist with minimal schema and still be resumable?

- Can low cadence be distinguished from accidental neglect?

- Can project synergy be derived from shared knowledge/relations?

# CS05 - Speedcubing

Practice domain used to distinguish skill progression, sessions, metrics, observations and knowledge from project completion.

| **WORKING** | Reality-grounding case study. The representation below preserves observed behavior before final ontology formalization. |
|-------------|-------------------------------------------------------------------------------------------------------------------------|

## 1. Why this case matters

- Introduces repeated practice rather than a finite artifact-focused Project.

- Performance can be measured, but measurement must remain subordinate to learning and awareness.

- Combines theory, algorithms, motor technique, free solves and reflective practice.

## 2. Natural behavior before the system

- Learned layer method and part of CFOP/Friedrich.

- Studies videos/articles to understand possible improvement paths before deciding what to train.

- Mixed sessions: timed solves, slow reflective solves, algorithm learning/review, finger movement practice, news/content.

- Milestones can overlap and be reordered based on observed bottlenecks.

## 3. Original friction

- cstimer stores solve data but not conveniently the qualitative observations that matter.

- Tracking every solve in Life OS would be redundant and high-maintenance.

- Practice quantity is useful to understand attention distribution but is not the value of the goal.

- Need to resume what algorithms are learned/learning and what current bottleneck is.

## 4. Desired support

- Where am I view: current phase, milestones, algorithms learned/learning, trends and recent practice.

- What can I do view: task, review knowledge, read, timed solve, slow solve, practice algorithm.

- Session-level metrics such as Single, Ao5, Ao12 plus optional observations/sensations.

- Retrospectives that aggregate recurring bottlenecks, e.g. how often F2L was identified as limiting.

## 5. Information and entities involved

- Practice, Session, Metric, Observation, algorithms, solving methods, F2L/OLL/PLL Concepts, milestones, resources.

## 6. Processes and activities

- Practice consisting of heterogeneous sessions.

- Study.

- Performance observation.

- Retrospective and milestone reprioritization.

## 6.1 Current milestone sample

- All PLL reasonably well.

- Most OLL.

- Finger tricks/movements.

- Improve cube perception / lookahead before moves.

- Train F2L and review algorithms.

## 7. Concepts this case helped discover

- Session as a sample of lived activity, not exhaustive event logging.

- Metric as structured measure of reality associated with a Session.

- Observation as optional reflective property/content, often attached to sessions.

- Practice as process over multiple sessions.

- Knowledge completion can be derived from subparts.

- Do not model method-per-session until multiple methods make the distinction useful.

## 8. Deliberately not modeled

- Every individual solve in Life OS.

- Mandatory comments after every session.

- Hypothesis and Evidence as formal types.

- Future timing metrics per individual algorithm before they are needed.

## 9. Ontology stress-test questions

- Can the ontology represent Practice without forcing it into Project completion semantics?

- Can metrics be optional and session-scoped?

- Can F2L be one Concept reused across solving-method views?

- Can knowledge/progress be derived from algorithm-level state without redundant percentages?

# CS06 - Crochet

Creative case that connects inspiration, Idea, progressive structure, Project execution, Artifact and reusable Knowledge.

| **WORKING** | Reality-grounding case study. The representation below preserves observed behavior before final ontology formalization. |
|-------------|-------------------------------------------------------------------------------------------------------------------------|

## 1. Why this case matters

- Shows how inspiration can remain a simple connection rather than dedicated type.

- Demonstrates a natural transformation from vague creative intent to executable Project.

- Shows that a finished Project can be dehydrated into reusable pattern/knowledge.

## 2. Natural behavior before the system

- Pinterest collections store visual references by hobby.

- When an idea appears, a lightweight note is created and linked to relevant inspiration.

- Generic crochet knowledge contains base structures/methods, stitch types, steps and intermediate photos.

- An idea can reference known structures inline, e.g. square -\> cone -\> triangle.

- Once vision is clear and time is available, the idea can be transformed into an active Project.

## 3. Original friction

- Active creative projects can be forgotten between bursts of attention.

- Ideas on paper or image boards are disconnected from executable structure.

- Repeated learning may remain trapped inside one project instead of becoming a reusable pattern.

- A rigid project template would be disproportionate while the idea is still only a sketch.

## 4. Desired support

- Very cheap capture of Idea and inspiration links.

- Progressive decomposition into construction steps, materials and tasks only when needed.

- Sessions/comments/photos during execution.

- After completion, easy extraction of generalized pattern stripped of project-specific noise.

## 5. Information and entities involved

- Resource/image, Idea, crochet Concepts, structure/pattern, Project, Task, Session, progress photo, Artifact, Observation, reusable Knowledge.

## 6. Processes and activities

- Inspiration/connection.

- Idea development and maceration.

- Exploration of techniques.

- Project execution.

- Practice.

- Artifact creation.

- Knowledge extraction/generalization.

## 7. Concepts this case helped discover

- Inspiration need not be a first-class Entity type.

- Same object can mature rather than being copied through rigid workflow states.

- Activities generate information: artifact, observation, knowledge, idea.

- Specific mistakes can remain observations; repeated/generalized lessons can become Knowledge.

- Past work should reduce future work.

## 8. Deliberately not modeled

- Mandatory Inspiration type.

- Forced workflow Inspiration -\> Idea -\> Project -\> Pattern.

- Automatic conversion of every project observation into Knowledge.

## 9. Ontology stress-test questions

- Can a raw image/resource connect to an Idea without special-case ontology?

- Can a simple Idea acquire Project capabilities without duplication?

- Can an Artifact be represented as a normal Entity produced-by activity/project?

- Can generalized pattern knowledge reference current Concepts while preserving useful project history?

# 10. Cross-case synthesis

I casi non sono sei esempi dello stesso workflow. Il loro valore e mostrare quali meccanismi devono restare generali e quali differenze non devono essere appiattite.

| **Dimension**               | **Solducci** | **LaGenteStrana** | **Agrivoltaico** | **HistoryExplorer** | **Speedcubing** | **Crochet**           |
|-----------------------------|--------------|-------------------|------------------|---------------------|-----------------|-----------------------|
| **Project identity**        | Strong       | Strong            | Candidate        | Light               | Weak            | Strong when committed |
| **Exploration**             | Medium       | Medium            | Strong           | Medium              | Medium          | Medium                |
| **Practice / Session**      | Medium       | Medium            | Low              | Low                 | Strong          | Strong                |
| **Generic Knowledge**       | Strong       | Strong            | Strong           | Medium              | Strong          | Strong                |
| **Metrics**                 | Low          | Low               | Potential        | Low                 | Strong          | Optional              |
| **Scenario**                | Medium       | Low               | Strong           | Low                 | Low             | Low                   |
| **Resume after inactivity** | Strong       | Strong            | Strong           | Strong              | Strong          | Strong                |
| **Progressive structuring** | Strong       | Strong            | Strong           | Strong              | Strong          | Strong                |

## 10.1 Repeated design evidence

- Resume value is universal across active and dormant cases.

- Progressive structuring appears in projects, knowledge and creative ideas.

- A small set of reusable relations is preferable to domain-specific duplicated structures.

- Session/Practice are necessary for repeated activity but not for every Project.

- Metrics are useful in some domains and unnecessary in others; optionality is essential.

- Contextual state must stay separate from generic knowledge.

- Low-commitment cases are an important guard against over-engineering.

## 10.2 Missing test domains

| **Coverage gap** The current evidence corpus is strong on Projects, Knowledge and Practice, but weaker on Health, Relationships, Bureaucracy, Travel and recurring maintenance. These should become second-wave stress tests before considering the ontology broadly stable. |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

- Health: recurring checks, uncertain symptoms, appointments, private notes and maintenance without turning health into a project.

- Relationships: long-lived bonds, shared moments, maintenance, reconnection and subjective quality without scoring people.

- Bureaucracy/finance: recurring obligations, deadlines, documents and low-interest but high-importance tasks.

- Travel: temporary project-like logistics plus experience sampling.

- Recurring maintenance: cadence, expected frequency and debt without habit-tracker rigidity.

# 11. Case-study acceptance rule for Ontology Minimum v0.1

| **Acceptance rule** A candidate ontology is not successful because it can encode these cases in principle. It should represent them naturally, with low boilerplate, progressive depth, correct contextuality and no proliferation of special-case types. |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

- Represent the strong cases without losing behavior that motivated the model.

- Keep simple cases simple.

- Allow richer cases to deepen without migrating to a different universe of objects.

- Preserve optionality of metrics, observations and processes.

- Make resumability and reuse easier than in the original behavior.

- Keep open questions open when evidence is insufficient.
