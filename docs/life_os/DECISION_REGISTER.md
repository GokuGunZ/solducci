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
| **INT-D007** | `currentMode` Has No Semantic Default (`null` is Valid) | **Established** | Domain / Ontologia |
| **INT-D008** | Single Source of Truth for User-Specific State | **Established** | Architecture / Overlay |
| **INT-D009** | Enforced Target Integrity for `entity_relations` | **Established** | Storage / Integrity |
| **INT-D010** | Meaningful Activity Policy v0.1 (Derived Cache) | **Established** | Domain / Experience |

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

---

### INT-D007: `currentMode` Has No Semantic Default (`null` is Valid)
* **Status:** Established (Amendment A)
* **Decision:** `currentMode` è opzionale (`OperationMode? currentMode`). Una cattura grezza (`seed`) non riceve `mode = exploration` arbitrariamente. L'assenza di struttura è una struttura valida (`DP04`).
* **Rationale:** Non assegnare strutture premature a ciò che è solo una nota rapida (es. "comprare filo di rame").
* **Related:** DP04, DP05, INT-D003.

---

### INT-D008: Single Source of Truth for User-Specific State
* **Status:** Established (Amendment B)
* **Decision:** Qualsiasi stato classificato come `USER-SPECIFIC` (`is_in_weekly_rail`, `commitment_weight`, `snoozed_signals`, personal notes) risiede esclusivamente in `user_entity_overlays`, sia che l'entità sia personale sia che sia condivisa in un gruppo. L'overlay è creato in modalità lazy (nessuna riga finché l'utente non salva preferenze personali).
* **Rationale:** Unica fonte di verità senza biforcazioni (shared entity vs personal entity). Due utenti possono condividere un progetto senza che le loro pianificazioni settimanali collidano.
* **Related:** DP06, DP15, INT-D002.

---

### INT-D009: Enforced Target Integrity for `entity_relations`
* **Status:** Established (Amendment C)
* **Decision:** `source_id` mantiene una FK reale su `documents(id)`. I target supportati in v0.1 sono limitati a `'entity'`, `'task'`, `'expense'`, `'time_scenario'`. L'integrità all'eliminazione è garantita da trigger PostgreSQL discriminati per `target_type`. L'autorizzazione è garantita da RLS: l'utente non può creare relazioni verso oggetti a cui non ha accesso.
* **Rationale:** Previene riferimenti orfani e violazioni di sicurezza senza imporre un motore di grafi universale.
* **Related:** DP08, INT-D005.

---

### INT-D010: Meaningful Activity Policy v0.1 (Derived Cache)
* **Status:** Established (Amendment D)
* **Decision:** La policy v0.1 definisce come fonti canoniche di attività significativa esclusivamente: 1) `LifeSession` registrata, 2) `Task` completato / progresso operativo. `last_meaningful_activity_at` è una cache materializzata aggiornata al salvataggio e ricalcolabile in ogni momento tramite auto-healing dalle fonti canoniche.
* **Rationale:** Prestazioni O(1) in lettura sulla dashboard preservando la purezza del dato canonico.
* **Related:** DP03, DP11, INT-D002.

---

### INT-D011: Repository Error Contract Canon (Direct Return with Exception Propagation)
* **Status:** Established (Step 2.1 Re-alignment)
* **Decision:** In conformità ai repository esistenti di Solducci (`TaskRepository`, `DocumentService`, `GroupService`), i repository LifeOS adottano il contratto canonico di ritorno diretto (`Future<T>` / `Future<T?>`) propagando le eccezioni di rete e database. I presentation controller (Cubit / Bloc) gestiscono `try-catch` traducendo gli errori in stati UI espliciti e veritieri (Amendment B), con retry immediato. `OperationResult<T>` è mantenuto come wrapper di utilità per composizioni funzionali ma non è imposto alle interfacce repository.
* **Rationale:** Elimina discrepanze architetturali e preserva la coerenza con il resto dell'applicazione.
* **Related:** INT-D006, INT-D008.

---

### INT-D012: Strict Orthogonality between Semantic Role and Current Mode
* **Status:** Established (Step 2.1 Rule)
* **Decision:** `SemanticRole` (cosa rappresenta l'entità: seed, project, practice, concept, idea) e `OperationMode` (come la si sta affrontando: null, exploration, execution, practice, reflection) sono rigidamente ortogonali. Nessuna azione umana ("Trattalo come progetto", "Coltivalo come pratica", "Esplora") può mutare implicitamente l'altra dimensione.
* **Rationale:** Previene assunzioni indebite (es. progetto = esecuzione forzata, o esplora = idea forzata) e rispetta il fatto che una cattura può essere esplorata rimanendo seme, o lavorata rimanendo progetto.
* **Related:** INT-D007, DP02.

---

### INT-D013: Evidence Authority Boundary
* **Status:** Established (Step 2.1 Meta-Rule)
* **Decision:** Un livello di evidenza può essere promosso solo da un attore o strumento capace di osservare direttamente quel fenomeno.
```text
compiler                 → build evidence
unit test                → isolated behavior evidence
DB integration test      → database behavior evidence
physical device/emulator → device behavior evidence
human report             → subjective/lived-use evidence
```
Nessun livello inferiore può essere usato come sostituto narrativo di quello superiore. Quando l'evidenza richiesta non è disponibile, l'agente deve marcare il livello come `PENDING` o `WAITING FOR EXTERNAL ACTION`, descrivere ciò che è necessario e fermarsi.
* **Rationale:** Previene false attestazioni, proiezioni narrative o simulazioni non verificate di stati soggettivi ed empirici.
* **Related:** INT-D001, INT-D006.
