# LifeOS Progressive Properties Design v0.1

**Status:** Approved Specification  
**Date:** 2026-10-24  
**Scope:** Specification and domain invariants for progressive, non-destructive properties on `LifeEntity`.  
**Companion Documents:**  
- [DECISION_REGISTER.md](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/docs/life_os/DECISION_REGISTER.md)  
- [INTEGRATION_FOUNDATION_GATE_V0_1.md](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/docs/life_os/INTEGRATION_FOUNDATION_GATE_V0_1.md)  

---

## 1. Modello Concettuale & Filosofia

Nei sistemi tradizionali di produttività (Notion, database relazionali, ontologie rigide), definire o cambiare la natura di un oggetto impone schemi prefissati:
- se una nota diventa progetto, compaiono improvvisamente 10 campi vuoti (*deadline, status, priority, owner...*);
- se un progetto viene riclassificato come concetto o idea, i campi operativi vengono spesso nascosti, rimossi o invalidati.

In **LifeOS**, l'approccio è governato da due principi fondanti:

> **1. Absence of structure is valid structure.**  
> Nessuna entità deve nascere con campi vuoti da compilare. Una cattura grezza è completa col solo titolo.

> **2. Structure is earned through returned attention, never imposed by taxonomy.**  
> Le proprietà emergono quando l'utente sente il bisogno reale di qualificare l'entità, oppure quando accetta un suggerimento contestuale.

---

## 2. Invarianti di Dominio Obbligatorie

### Invariante 1: Conservazione Non-Distruttiva (Role Change Preservation)
Quando cambia il `SemanticRole` di una `LifeEntity` (es. da `project` a `concept`), **nessuna proprietà esistente viene distrutta o rimossa**.

*Esempio concreto:*
```text
Entity: "Capire auth GDPR per Solducci"
role = project
properties:
  goal: "Autenticazione a norma senza account centralizzati forzati"
  deadline: "2026-11-15"
  next_step: "Mappare schema group_members"

[Azione utente: cambia Natura in "Concetto"]

role = concept
properties rimangono integre:
  goal: "Autenticazione a norma..."
  deadline: "2026-11-15"
  next_step: "Mappare schema group_members"
```
Ciò che cambia è esclusivamente il pacchetto di proprietà **suggerite** per quel ruolo.

---

### Invariante 2: Identità Semantica e Riuso (Deduplication by Key)
Ogni proprietà possiede una chiave semantica normalizzata (`key`, es. `'goal'`, `'deadline'`, `'next_step'`).

Se un nuovo ruolo suggerisce una proprietà (es. `Goal`), e l'entità possiede già una proprietà con chiave `'goal'`:
- il sistema **riusa** la proprietà esistente;
- **non** crea un duplicato (nessun `goal_2` o `goal_project`);
- l'utente vede il valore attuale e può semplicemente raffinarlo.

---

### Invariante 3: Assenza Valida (No Schema Tyranny)
L'assenza di una proprietà suggerita non invalida l'entità né genera warning o placeholder rumorosi. I suggerimenti rimangono accessibili con un tocco leggero (`+ Aggiungi proprietà`), senza occupare spazio visivo invasivo nella Vitrine.

---

### Invariante 4: Compatibilità con la Strutturazione Progressiva
Il tipo e valore di una proprietà supporta la scala evolutiva:

```text
Text Value 
  → Structured Value (es. data, lista) 
  → Entity (promozione a entità autonoma) 
  → Network (relazione polimorfica via entity_relations)
```

In v0.1 ogni proprietà è rappresentata come valore scalare (`text`, `date`, `number`, `url`), predisposta per essere promossa in futuro a link di primo livello senza richiedere migrazioni distruttive.

---

## 3. Role Property Packs (Suggerimenti per Natura)

I pacchetti di proprietà sono **suggerimenti euristici ergonomici**, non schemi obbligatori:

### Progetto (`SemanticRole.project`)
- `goal`: *Cosa definisce il compimento o il successo di questo progetto?*
- `next_step`: *Qual è la primissima mossa concreta da compiere?*
- `deadline`: *Entro quale orizzonte temporale o data target?*

### Pratica (`SemanticRole.practice`)
- `cadence`: *Con quale frequenza (es. quotidiana, 3 volte a settimana, weekend)?*
- `method`: *Qual è il rituale o la modalità di esecuzione?*
- `metric`: *Quale parametro di costanza o volume viene osservato?*

### Concetto (`SemanticRole.concept`)
- `understanding`: *Qual è l'intuizione o il principio fondamentale da ricordare?*
- `open_questions`: *Cosa rimane ancora da chiarire o approfondire?*
- `resources`: *Riferimenti, libri, link o citazioni chiave.*

### Idea (`SemanticRole.idea`)
- `spark`: *Cosa ha acceso questa intuizione?*
- `potential`: *Quale valore o risvolto futuro potrebbe generare?*

### Seme (`SemanticRole.seed`)
- Nessun suggerimento di default. Il seme rimane nudo e leggero.

---

## 4. Specifiche del Modello Dart

```dart
enum PropertyType { text, date, number, url }

class EntityProperty extends Equatable {
  final String key;
  final String label;
  final Object value;
  final PropertyType type;

  const EntityProperty({
    required this.key,
    required this.label,
    required this.value,
    this.type = PropertyType.text,
  });

  /// Accesso type-safe per proprietà numeriche
  num? get asNumber => value is num ? value as num : num.tryParse(value.toString());

  /// Accesso type-safe per proprietà data
  DateTime? get asDate => value is DateTime ? value as DateTime : DateTime.tryParse(value.toString());

  /// Rappresentazione stringa per display ed editing testuale
  String get displayValue => value.toString();

  /// Canonical JSON encoding (INT-D016):
  /// text   → JSON string
  /// url    → JSON string
  /// date   → ISO-8601 string
  /// number → JSON number
  dynamic get canonicalJsonValue {
    switch (type) {
      case PropertyType.number:
        return asNumber ?? 0;
      case PropertyType.date:
        final d = asDate;
        return d != null ? d.toIso8601String() : value.toString();
      case PropertyType.text:
      case PropertyType.url:
        return value.toString();
    }
  }

  Map<String, dynamic> toJson() => {
    'key': key.trim(),
    'label': label,
    'value': canonicalJsonValue,
    'type': type.name,
  };

  factory EntityProperty.fromJson(Map<String, dynamic> json) { ... }
}
```
  );

  @override
  List<Object?> get props => [key, label, value, type];
}
```

---

## 5. Rappresentazione Canonica & Storage Pragmatico

In conformità al principio di **Minimum Commitment Architecture**:
- **Namespace Canonico Normalizzato:** Le proprietà e i blocchi evolutivi sono memorizzati rigorosamente sotto il namespace dell'applicazione:
  ```json
  metadata['life_os']['properties'] = [
    {
      "key": "goal",
      "label": "Obiettivo",
      "value": "Autenticazione conforme GDPR",
      "type": "text"
    }
  ]
  metadata['life_os']['blocks'] = [
    {
      "id": "uuid-v4",
      "content": "Verificare retention policy",
      "position": 0,
      "created_at": "2026-10-24T22:30:00.000Z"
    }
  ]
  ```
- **Codec dei Valori (Tipi Canonici JSON):**
  - `text` $\rightarrow$ JSON string
  - `url` $\rightarrow$ JSON string
  - `date` $\rightarrow$ ISO-8601 string (`DateTime.toIso8601String()`)
  - `number` $\rightarrow$ JSON number (`num`)
- **Deduplicazione Semantica & Gestione Chiavi:**
  - `one entity + one semantic key → at most one active property with that key`.
  - `upsertProperty(property)` aggiorna la proprietà se `key` è già presente, altrimenti la inserisce in coda.
  - *Deduplication Policy nel Mapper:* Se il payload JSON contiene accidentalmente record duplicati con la stessa chiave, si applica deterministicamente la policy **Last-Write-Wins**.
- **Retrocompatibilità:** `LifeEntityMapper` gestisce la conversione bidirezionale mantenendo compatibilità totale con entità che non hanno ancora alcuna proprietà (`properties: []`);
- Zero alterazioni dello schema SQL e zero migrazioni database necessarie per supportare le proprietà progressive.

---

## 6. Strategia di Persistenza Blocchi & Revisit Triggers

La persistenza dei blocchi sequenziali all'interno di `metadata['life_os']['blocks']` è una deliberata strategia v0.1 ottimizzata per volumi ridotti e contesti a singolo autore prevalente (*predominantly single-writer entity evolution*).

> **Chiarimento Concorrenza:** La serializzazione atomica su metadata JSONB non garantisce assenza di race condition in presenza di scrittori concorrenti simultanei su nodi diversi.

### Revisit Triggers per Storage Dedicato
La creazione di una tabella relazionale dedicata (es. `entity_blocks`) sarà valutata qualora emerga uno o più dei seguenti bisogni reali:
1. **Concurrent editing:** Scritture collaborative contemporanee frequenti sullo stesso documento.
2. **High block volume:** Accumulo di decine/centinaia di blocchi per entità con impatto sul payload.
3. **Independent block queries:** Ricerca full-text o filtraggio per singoli blocchi senza caricare l'entità intera.
4. **Block-level relations:** Necessità di creare archi `entity_relations` che puntano a un singolo blocco e non all'intera entità.
5. **Block-specific lifecycle:** Stati di completamento, archiviazione o assegnazione specifici per singolo blocco.
6. **Collaborative ordering:** Algoritmi CRDT o riordino multi-utente distribuito.
7. **Multiple rich block types:** Blocchi multimediali complessi (immagini, checklist interattive, snippet audio).

La transizione a uno storage dedicato futuro non richiederà alterazioni al contratto del domain model puro `EntityBlock`.
