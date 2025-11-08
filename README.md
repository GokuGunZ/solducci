# Solducci

App per il tracciamento delle spese personali condivise tra Carl e Pit.

## Features

### Core
- ✅ Gestione spese con categorizzazione dettagliata
- ✅ Tracking flussi di denaro tra utenti
- ✅ Autenticazione tramite Supabase
- ✅ Sincronizzazione real-time dei dati
- ✅ Supporto per spese condivise e individuali
- ✅ Creazione ed eliminazione spese
- ✅ Logout con conferma

### Dashboard & Analytics (Sprint 2)
- ✅ **Vista Mensile**: Raggruppa spese per mese con totali
- ✅ **Vista Categorie**: Breakdown per categoria con percentuali
- ✅ **Vista Saldo**: Calcolo automatico debiti/crediti tra Carl e Pit
- ✅ **Vista Timeline**: Cronologia con separatori temporali ("Oggi", "Ieri", date)
- ✅ **Dashboard Home**: Navigazione centrale verso tutte le analytics

### UI/UX
- ✅ Swipe-to-delete con conferma
- ✅ Form full-screen per nuove spese
- ✅ Dettagli spesa in modal bottom sheet
- ✅ Empty states con illustrazioni
- ✅ Loading states per operazioni async
- ✅ Feedback visivo con SnackBar colorati

## Setup

1. **Installa le dipendenze:**
   ```bash
   flutter pub get
   ```

2. **Configura le variabili d'ambiente:**
   - Copia `assets/dev/.env.example` in `assets/dev/.env`
   - Inserisci le tue credenziali Supabase e Google Cloud Platform

3. **Esegui l'app:**
   ```bash
   flutter run
   ```

## Architettura

- **Models**:
  - `Expense`: Modello principale spese con user_id
  - `ExpenseForm`: Form fields e validazione
  - `DashboardData`: Modelli analytics (MonthlyGroup, CategoryBreakdown, DebtBalance)
- **Services**:
  - `ExpenseService`: CRUD spese + stream real-time
  - `AuthService`: Login, signup, logout Supabase
  - `DashboardService`: Aggregazione dati per analytics
- **Views**:
  - `ExpenseList`: Lista principale con navigazione dashboard
  - `DashboardHome`: Hub centrale analytics
  - `MonthlyView`: Raggruppamento mensile
  - `CategoryView`: Breakdown categorie
  - `BalanceView`: Calcolo debiti/crediti
  - `TimelineView`: Cronologia temporale
  - `LoginPage`, `SignupPage`: Autenticazione
- **Backend**: Supabase (PostgreSQL + Auth + Real-time)

## Categorie Spese

- Affitto
- Cibo
- Utenze
- Prodotti Casa
- Ristorante
- Tempo Libero
- Altro

## Flussi di Denaro

- Carl → Pit
- Pit → Carl
- Carl /2 (spesa condivisa pagata da Carl)
- Pit /2 (spesa condivisa pagata da Pit)
- Carlucci (spesa di Carl)
- Pitucci (spesa di Pit)

## Debug & Logging

L'app include un sistema di logging completo che mostra informazioni dettagliate nella console in modalità debug:

### Tipi di Log

- 🔧 **Operazioni di sistema**: Inizializzazione app, caricamento .env, setup Supabase
- ✅ **Operazioni riuscite**: Creazione/modifica/eliminazione spese
- ⚠️ **Avvisi**: Parsing formati date legacy, valori enum sconosciuti
- ❌ **Errori**: Problemi di parsing, errori database, operazioni fallite
- 📊 **Dati**: Numero di spese ricevute dallo stream

### Esempio Output Console

```
🔧 Loading environment variables...
✅ Environment variables loaded successfully
🔧 Initializing Supabase...
   URL: https://fpvzviseqayuxbxjvxea.supabase.co
✅ Supabase initialized successfully
🚀 Starting Solducci app...
📊 Received 15 expenses from stream
✅ Expense created successfully: Spesa Coop
⚠️ Parsed legacy date format: 08/01/2025 -> 2025-01-08 00:00:00.000
```

### Note

- I log sono visibili **solo in modalità debug** (`kDebugMode`)
- In produzione, tutti i log vengono automaticamente disabilitati
- Il parsing delle date supporta sia formato ISO 8601 che formato italiano (dd/MM/yyyy) per retrocompatibilità
