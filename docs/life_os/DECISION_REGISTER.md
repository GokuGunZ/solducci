# Life OS in Solducci — Integration Decision Register

> **Status:** Active Project Governance  
> **Contesto:** Branch `LIFE_OS` / Worktree `Projects/LIFE_OS`

---

## Decision Summary

| ID | Title | Status | Scope |
| :--- | :--- | :--- | :--- |
| **INT-D001** | The Living Core as First Vertical Slice | **Established** | Product / Scope |
| **INT-D002** | Separation of Domain `LifeEntity` from `Document` Storage | **Established** | Architecture / Domain |
| **INT-D003** | Hybrid Semantic Role + Dynamic Capabilities | **Established** | Domain / Ontologia |
| **INT-D004** | Primary Entity + Related Entities for `LifeSession` | **Established** | Domain / Experience |
| **INT-D005** | Polymorphic References in `entity_relations` | **Established** | Storage / Relazioni |
| **INT-D006** | Decoupled Policy from Signal Evaluation Mechanism | **Established** | Interaction / Mirror |

---

## Detailed Decision Records

### INT-D001: The Living Core as First Vertical Slice
* **Status:** Established
* **Decision:** La prima concretizzazione di Life OS in Solducci è incentrata sulla slice **The Living Core**: Universal Quick-Add, Project/Entity Vitrine con Resume Surface, Session Runner leggero, Weekly Rails e Cerimonia Settimanale.
* **Rationale:** Massimizza il rapporto tra valore umano immediato (azzeramento del costo di rientro dopo inattività) e complessità tecnica, testando i 4 casi d'uso cardine (Solducci, Agrivoltaico, Speedcubing, Crochet).
* **Related:** DP01, DP02, DP04, SR06.

---

### INT-D002: Separation of Domain `LifeEntity` from `Document` Storage
* **Status:** Established
* **Decision:** Trattare la tabella SQL `documents` e la classe base Flutter `Document` esclusivamente come adapter tecnico di persistenza iniziale. Il dominio espone concetti puri (`LifeEntity`, `LifeSession`, `EntityRelation`).
* **Rationale:** Evita leakage concettuale (un Progetto o una Pratica non sono semanticamente "un documento"). Preserva totale reversibilità qualora in futuro si adotti uno storage dedicato.
* **Related:** DP08, DP14.

---

### INT-D003: Hybrid Semantic Role + Dynamic Capabilities
* **Status:** Established
* **Decision:** Non creare tipi o tabelle SQL rigide per `Project`, `Idea`, `Practice`, `Concept`. Memorizzare il ruolo semantico in `metadata['semantic_role']` e derivare le capacità operative (azioni, grafici, resume) dai dati effettivamente presenti nell'entità.
* **Rationale:** Permette strutturazione progressiva (`DP04`). Un'Idea può diventare Progetto senza alterare tabelle o schemi di database.
* **Related:** DP04, DP05, DP13.

---

### INT-D004: Primary Entity + Related Entities for `LifeSession`
* **Status:** Established
* **Decision:** Ogni sessione campionata possiede una sola entità focale principale (`primary_entity_id`) e una lista facoltativa di entità collegate (`related_entity_ids`).
* **Rationale:** Rispecchia la realtà dell'azione umana (si lavora a un progetto principale toccando 1-2 concetti secondari) mantenendo query SQL semplici senza la complessità di una tabella N:M pura.
* **Related:** DP17, SR03, CS01, CS05.

---

### INT-D005: Polymorphic References in `entity_relations`
* **Status:** Established
* **Decision:** La tabella `entity_relations` supporta `target_type` e `target_id`, permettendo a una LifeEntity di connettersi non solo ad altre entità ma anche a `tasks`, `expenses` e `time_scenarios`.
* **Rationale:** Rende Life OS il vero tessuto connettivo dell'ecosistema Solducci senza dover costruire un motore a grafo universale.
* **Related:** DP06, DP15, SR10.

---

### INT-D006: Decoupled Policy from Signal Evaluation Mechanism
* **Status:** Established
* **Decision:** I segnali dello specchio (`InactivitySignal`, `MaturitySignal`, `DistillationDebtSignal`) sono valutati tramite un motore deterministico disaccoppiato da configurazioni di policy (soglie numeriche di giorni o conteggi note), e supportano il congedo temporaneo (`snooze/dismiss`).
* **Rationale:** Soglie numeriche come 14 giorni sono ipotesi di policy, non verità di dominio. Devono poter essere modificate senza migrazioni database.
* **Related:** DP01, DP19, SR09, SR11.
