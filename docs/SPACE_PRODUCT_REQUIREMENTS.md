# 📋 Spazio Feature — Product Requirements

> **Audience**: Product Managers, Designers, Stakeholders
> **Level**: Business and functional requirements
> **Feature**: "Spazio" — quinta tab dell'app Solducci

---

## Executive Summary

**Spazio** è una nuova sezione dell'app Solducci che centralizza cinque tipologie di contenuti condivisi all'interno di un gruppo (o personali). L'obiettivo è creare **spazi mentali distinti** per diversi tipi di informazione, evitando un ambiente cluttered e aiutando gli utenti a gestire informazioni condivise in modo organizzato.

---

## Motivazione

Gli utenti di Solducci — coppie, coinquilini, gruppi di convivenza — hanno bisogno di condividere non solo spese, ma anche:
- Argomenti da discutere insieme
- Risorse (link, video, articoli) da condividere
- L'inventario della casa (dispensa, prodotti)
- Liste della spesa
- Task e to-do
- Note testuali

Questi contenuti oggi non hanno casa nell'app. "Spazio" li raccoglie in un unico posto mantenendoli **concettualmente separati**.

---

## Posizionamento nell'app

- **Nuova 5a tab** nel bottom navigation bar, con label "Spazio"
- **Schermata principale**: 5 card, una per tipologia, ognuna porta alla sua sezione
- **Context-aware**: tutto segue il `ContextManager` — ogni contenuto è personale o del gruppo/vista attualmente selezionata
- La tab **"ToDo"** attuale viene rinominata e assorbita dentro "Spazio"

---

## Le 5 Tipologie

### 1. Asterischi

**Cos'è**: Un sistema di "segnalibri mentali" per argomenti che si vogliono discutere con gli altri membri del gruppo.

**Comportamento**:
- Ogni asterisco ha un **titolo** (visibile a tutti) e un **corpo** (visibile e modificabile solo dal creatore)
- Ha uno **stato**: `attivo` → `archiviato`
- Viene archiviato dopo che l'argomento è stato discusso
- Possono esistere più liste di asterischi per contesto

**User story**:
> "Ho visto che le bollette stanno aumentando, voglio segnarlo per parlarne con il mio coinquilino stasera."

---

### 2. Risorse / Contenuti

**Cos'è**: Una raccolta di link (video, articoli, documenti) che un membro vuole condividere con il gruppo.

**Comportamento**:
- Ogni risorsa ha: **titolo**, **URL**, **descrizione** opzionale, **tag**
- Ogni membro può marcare una risorsa come **vista/letta** (stato individuale per membro)
- Possono esistere più raccolte per contesto (es. "Film da vedere", "Guide casa")

**User story**:
> "Ho trovato un ottimo video su come risparmiare energia, lo salvo nella nostra lista 'Da guardare insieme'."

---

### 3. Dispensa

**Cos'è**: Un inventario degli elementi disponibili in casa, con quantità e categorie.

**Comportamento**:
- Ogni elemento ha: **nome**, **categoria**, zero o più **quantità** (ognuna con tipo + valore)
- **Quantità multiple per elemento**: es. "Latte" = 2 confezioni da 1L + 1 da 0.5L
- **Categorie**: Frigo, Surgelati, Dispensa, Prodotti Pulizia, Oggetti Casa
- Un elemento è **mancante** se non ha quantità oppure è sotto la **soglia minima** configurabile
- Gli elementi possono essere **nascosti** dalla vista "Mancanti" (es. cose stagionali)
- Possono esistere più dispense per contesto (es. "Cucina", "Cantina")

**Lista della spesa rapida** (sottofunzionalità):
- Si crea a partire dagli elementi mancanti
- È **checkabile** (ogni elemento si spunta durante la spesa)
- Possono esistere più liste della spesa attive in parallelo
- Bottone **"Spesa fatta"**: aggiunge alla dispensa le quantità degli elementi spuntati
- È possibile aggiungere elementi manuali alla lista (non necessariamente dalla dispensa)

**User story**:
> "Guardo in dispensa: manca il latte e il detersivo. Creo una lista della spesa, la condivido col mio partner. Lui fa la spesa, spunta quello che compra, preme 'Spesa fatta' e la dispensa si aggiorna."

---

### 4. Task

**Cos'è**: Gestione di to-do list condivise o personali. Assorbe la sezione "Documents" attuale.

**Comportamento**:
- Ogni task ha: **titolo**, **stato** (pending/in progress/assigned/completed), **priorità**, **tag**, **scadenza**, **assegnatario** (membro del gruppo)
- Possono esistere più liste task per contesto (es. "Casa", "Progetto X")
- **NON** ha drag & drop
- L'assegnazione a un membro rende il task visibile come "assegnato a me" per quel membro

**User story**:
> "Creo il task 'Chiamare il padrone di casa' e lo assegno a Marco con scadenza venerdì."

---

### 5. Note Testuali

**Cos'è**: Note di testo semplice, modificabili da tutti i membri del gruppo.

**Comportamento**:
- Ogni nota ha: **titolo** + **corpo** (plain text)
- Modificabili da **tutti i membri** del gruppo
- Non esiste il concetto di nota privata dentro un gruppo — il contesto Personal/Group già separa le note
- Possono esistere più "quaderni" di note per contesto

**User story**:
> "Scriviamo le regole della casa in una nota condivisa, così tutti possono aggiornarle."

---

## Contesto e Visibilità

| Contesto | Comportamento |
|---|---|
| **Personale** | Tutte le 5 tipologie mostrano solo i contenuti dell'utente corrente |
| **Gruppo** | Tutte le 5 tipologie mostrano i contenuti condivisi del gruppo |
| **Vista** (multi-gruppo) | I contenuti di tutti i gruppi della vista sono aggregati e mostrati insieme |

---

## Regole di accesso (sintesi)

| Elemento | Chi può vedere | Chi può modificare |
|---|---|---|
| Titolo asterisco | Tutti i membri | Solo il creatore |
| Corpo asterisco | Solo il creatore | Solo il creatore |
| Stato asterisco | Tutti i membri | Solo il creatore |
| Nota testuale | Tutti i membri | Tutti i membri |
| Risorsa | Tutti i membri | Solo il creatore |
| Stato "visto" risorsa | Personale per membro | Ogni membro per sé |
| Elementi dispensa | Tutti i membri | Tutti i membri |
| Lista della spesa | Tutti i membri | Tutti i membri |
| Task | Tutti i membri | Tutti i membri |

---

## Non in scope (per ora)

- Formattazione rich text nelle note
- Allegati/foto a risorse o asterischi
- Notifiche push per nuovi contenuti
- Commenti su asterischi o risorse
- Ricorrenza automatica dei task (già presente in Documents, da valutare)
- Agendazione degli asterischi
- Archiviazione/export dei contenuti

---

## Roadmap suggerita

| Fase | Feature | Note |
|---|---|---|
| 1 | Scaffolding Spazio + navigazione | Prerequisito per tutto |
| 2 | Task (migrazione Documents) | Alta priorità — funzionalità esistente da portare |
| 3 | Note | Bassa complessità |
| 4 | Asterischi | Media complessità (logica visibilità corpo) |
| 5 | Risorse | Media complessità (tags + stato "visto") |
| 6 | Dispensa | Alta complessità (quantità multiple, soglie) |
| 7 | Lista della spesa | Alta complessità (dipende da Dispensa) |
