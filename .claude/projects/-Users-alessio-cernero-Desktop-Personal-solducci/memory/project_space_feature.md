---
name: Spazio Feature
description: Feature "Spazio" pianificata — 5a tab dell'app con 5 tipologie di contenuti condivisi (Task, Note, Asterischi, Risorse, Dispensa)
type: project
---

La feature "Spazio" è stata progettata completamente (requisiti + architettura tecnica) ma non ancora implementata.

**Documentazione completa in:**
- `docs/SPACE_PRODUCT_REQUIREMENTS.md` — requisiti business e funzionali
- `docs/SPACE_TECHNICAL_DESIGN.md` — schema DB, modelli Dart, services, routing, RLS
- `docs/SPACE_IMPLEMENTATION_GUIDE.md` — guida step-by-step per l'implementazione

**Why:** L'app ha bisogno di uno spazio per condividere contenuti non-finanziari tra i membri del gruppo (argomenti da discutere, link, inventario casa, task, note).

**How to apply:** Prima di implementare qualsiasi parte di Spazio, leggere i 3 file sopra. Il piano è suddiviso in 7 fasi ordinate per dipendenza.

Le 5 tipologie:
1. Task (assorbe Documents esistente, aggiunge assigned_to e liste multiple)
2. Note (titolo + corpo, modificabili da tutti)
3. Asterischi (placeholder per argomenti da discutere; corpo visibile solo al creatore)
4. Risorse (link con tag e stato "visto" per membro)
5. Dispensa (inventario con quantità multiple, soglie, lista della spesa)
