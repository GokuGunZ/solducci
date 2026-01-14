# Piano di Refactoring UI/UX - Divisione Spese

**Data Creazione:** 2026-01-14
**Stato:** In Implementazione
**Priorità:** Alta

---

## 1. ANALISI DEI REQUISITI

### 1.1 Problema Attuale
L'interfaccia di creazione spese presenta diversi flussi confusi basati sul contesto (personale, gruppo singolo, vista):
- UI frammentata con troppi stati e condizioni
- Esperienza utente non uniforme tra i diversi contesti
- Mancanza di feedback visivo chiaro durante la selezione
- Logica di split custom complessa e non intuitiva

### 1.2 Obiettivi del Refactoring
- ✅ **Unificare l'esperienza**: Single entry point con switch Personale/Di Gruppo
- ✅ **Semplificare la selezione**: Animazioni fluide e feedback visivo immediato
- ✅ **Ottimizzare la divisione**: Toggle "equamente" con calcolo automatico
- ✅ **Migliorare performance**: Integrare caching framework per caricamento membri
- ✅ **Mantenere compatibilità**: Nessuna breaking change nel database

---

## 2. SPECIFICHE UI/UX DETTAGLIATE

### 2.1 ExpenseTypeSwitch Component
**Descrizione:** Slidable switch full-width per scegliere tipo spesa

**Comportamento:**
- Due opzioni: "Personale" (viola) e "Di Gruppo" (verde)
- Bottone di selezione largo metà riga, contiene il testo dell'opzione selezionata
- Altra metà mostra il testo dell'opzione non selezionata (clickabile)
- Animazione smooth di slide quando si cambia opzione
- Colore di sfondo cambia da viola (personal) a verde (group)

**Stati:**
```dart
enum ExpenseType { personal, group }
```

**Design Specs:**
- Height: 56px
- Border radius: 12px
- Padding interno: 4px
- Animazione duration: 300ms (Curves.easeInOut)
- Viola: Color(0xFF6B46C1) / Purple.shade700
- Verde: Color(0xFF059669) / Green.shade600

**Proprietà:**
```dart
ExpenseTypeSwitch({
  required ExpenseType initialType,
  required ValueChanged<ExpenseType> onTypeChanged,
  bool enabled = true,
})
```

---

### 2.2 GroupSplitCard Component
**Descrizione:** Card espandibile per rappresentare un gruppo nella divisione spesa

**Comportamento:**

**Stato NON selezionato:**
- Mostra nome gruppo
- Leading: Avatar/icona gruppo
- Trailing: Badge con icona "user" + numero utenti (es: "👤 4")
- Altezza compatta: 64px
- Border leggero, sfondo grigio chiaro

**Stato SELEZIONATO:**
- Border colorato (verde/blu più evidente)
- Background leggermente colorato
- Espande verso il basso con animazione (300ms)
- Mostra sezione "Chi paga" e "Diviso tra"

**Struttura Espansa:**
```
┌─────────────────────────────────────┐
│ [Avatar] Nome Gruppo         [👤 4] │  ← Header sempre visibile
├─────────────────────────────────────┤
│                                     │
│ Pagato da 💰:                       │  ← "Chi paga" section
│ [Chip User1] [Chip User2] ...       │
│                                     │
│ ─────────────────────────────────── │  ← Divider
│                                     │
│ equamente diviso tra:               │  ← "Diviso tra" section
│   ^^^^^^^                           │     (equamente = toggle)
│ [UserSplitChip1] [UserSplitChip2]   │
│ [UserSplitChip3] [UserSplitChip4]   │
│                                     │
│ Totale: 45.00 / 50.00 €             │  ← Summary (se non equo)
└─────────────────────────────────────┘
```

**Proprietà:**
```dart
GroupSplitCard({
  required Group group,
  required List<GroupMember> members,
  required double totalAmount,
  bool isSelected = false,
  String? selectedPayer,
  Map<String, double>? splits,
  bool equalSplit = true,
  ValueChanged<bool>? onSelectionChanged,
  ValueChanged<String>? onPayerChanged,
  ValueChanged<Map<String, double>>? onSplitsChanged,
})
```

---

### 2.3 UserSelectionChip Component
**Descrizione:** Chip per selezionare chi ha pagato (sezione "Chi paga")

**Design:**
- Compact chip con avatar circolare
- Nickname utente
- Selectable con border highlight quando selezionato
- Badge "Admin" se applicabile

**Stati:**
- Non selezionato: Background grigio chiaro, border grigio
- Selezionato: Background verde chiaro, border verde bold

**Proprietà:**
```dart
UserSelectionChip({
  required GroupMember member,
  required bool isSelected,
  required VoidCallback onTap,
  bool showAdminBadge = true,
})
```

---

### 2.4 EquallySplitToggle Component
**Descrizione:** Toggle inline nel testo "equamente diviso tra"

**Comportamento:**
- Testo normale: "equamente diviso tra"
- Quando disattivato: "~~equamente~~ diviso tra" (strikethrough)
- Clickabile solo sulla parola "equamente"
- Animazione di strikethrough (200ms)

**Stati:**
```dart
bool isEqualSplit = true;  // Default
```

**Trigger Disattivazione:**
1. Click manuale sull'inline toggle
2. Modifica manuale di un importo in UserSplitChip

**Trigger Riattivazione:**
1. Click manuale sull'inline toggle (ricalcola equamente)
2. Selezione/deselezione di un utente (ricalcola equamente)

**Proprietà:**
```dart
EquallySplitToggle({
  required bool isEqual,
  required VoidCallback onToggle,
})
```

---

### 2.5 UserSplitChip Component
**Descrizione:** Chip con importo editabile per divisione spesa

**Design:**
```
┌────────────────────────────────┐
│ [Avatar] Nickname     │ 12.50€ │
│                       └────────┘
└────────────────────────────────┘
     ^                      ^
   Chip base          Importo editabile
```

**Comportamento:**

**Stato SELEZIONATO:**
- Chip visibile con avatar e nickname
- Parte destra con importo editabile (separatore verticale visivo)
- Click su importo: apre tastierino numerico inline
- Modifica importo: disattiva automaticamente "equamente"
- Bottone (+) visibile se c'è resto da distribuire

**Stato NON SELEZIONATO:**
- Chip visibile in grigio (non selectable nella UI ma mostra stato)
- Parte importo NASCOSTA (slide out animation dietro chip)
- Click su chip: lo seleziona e mostra importo

**Animazioni:**
- Selezione: importo slide-in da destra (250ms)
- Deselezione: importo slide-out verso destra (250ms)

**Importo Editing:**
- TextField inline con formato "0.00"
- Validation: max 2 decimali
- Auto-format con simbolo € fisso
- Comportamento scrittura da destra (come CurrencyTextInputFormatter)
- Focus automatico su tap

**Bottone (+) per Resto:**
- Appare solo se: `(totalAmount - currentSplitsTotal) > 0.01`
- Posizionato a destra dell'importo
- Click: assegna tutto il resto rimanente a questo utente
- Tooltip: "Assegna resto (X.XX€)"

**Proprietà:**
```dart
UserSplitChip({
  required GroupMember member,
  required bool isSelected,
  required double amount,
  required double totalAmount,
  required double currentSplitsTotal,
  required ValueChanged<bool> onSelectionChanged,
  required ValueChanged<double> onAmountChanged,
  bool showAddRemaining = false,
})
```

---

## 3. LOGICA DI BUSINESS

### 3.1 Comportamento Divisione Equa

**Preselection (Gruppo singolo):**
- Tutti gli utenti del gruppo sono pre-selezionati
- Toggle "equamente" attivo di default
- Importi pre-calcolati: `amount = totalAmount / members.length`
- Arrotondamento a 2 decimali

**Selezione/Deselezione Utente:**
```dart
void onUserToggled(String userId, bool isSelected) {
  if (isEqualSplit) {
    // Ricalcola equamente tra utenti selezionati
    final selectedCount = selectedUsers.length;
    final amountPerPerson = totalAmount / selectedCount;

    for (var user in selectedUsers) {
      splits[user.id] = double.parse(amountPerPerson.toStringAsFixed(2));
    }

    // Rimuovi utente deselezionato
    if (!isSelected) {
      splits.remove(userId);
    }
  } else {
    // Modalità custom: non ricalcolare
    if (isSelected) {
      splits[userId] = 0.0;  // Aggiungi con 0
    } else {
      splits.remove(userId);  // Rimuovi
    }
  }

  notifyListeners();
}
```

**Modifica Manuale Importo:**
```dart
void onAmountChanged(String userId, double newAmount) {
  splits[userId] = newAmount;

  // Disattiva automaticamente "equamente"
  if (isEqualSplit) {
    isEqualSplit = false;
    notifyListeners();
  }
}
```

**Toggle "Equamente":**
```dart
void onEqualSplitToggled() {
  isEqualSplit = !isEqualSplit;

  if (isEqualSplit) {
    // Ricalcola equamente tra utenti selezionati
    final selectedCount = splits.keys.length;
    final amountPerPerson = totalAmount / selectedCount;

    for (var userId in splits.keys) {
      splits[userId] = double.parse(amountPerPerson.toStringAsFixed(2));
    }
  }

  notifyListeners();
}
```

**Assegna Resto:**
```dart
void assignRemainingToUser(String userId) {
  final remaining = totalAmount - currentTotal;
  if (remaining > 0.01) {
    splits[userId] = (splits[userId] ?? 0.0) + remaining;
    notifyListeners();
  }
}
```

### 3.2 Validazione

**Regole:**
- Almeno 1 utente deve essere selezionato in "Diviso tra"
- Esattamente 1 utente deve essere selezionato in "Chi paga"
- Somma splits deve essere uguale a totalAmount (±0.01€ tolleranza)

**Feedback Visivo:**
- Testo rosso se somma non corrisponde
- Warning message sotto: "Mancano X.XX€" o "Totale supera di X.XX€"
- Bottone submit disabilitato se non valido

---

## 4. INTEGRAZIONE CON CONTESTI ESISTENTI

### 4.1 Contesto Personale
**Comportamento:**
- ExpenseTypeSwitch pre-selezionato su "Personale" (viola)
- Nessuna UI aggiuntiva visibile
- Form base: Descrizione, Importo, Data, Categoria
- Submit crea spesa con `userId`, senza `groupId`, `paidBy`, `splitType`

### 4.2 Contesto Gruppo Singolo
**Comportamento:**
- ExpenseTypeSwitch pre-selezionato su "Di Gruppo" (verde)
- Mostra 1 solo GroupSplitCard, già selezionato e espanso
- Card non collapsabile (always expanded)
- Membri caricati via cache da GroupServiceCached
- Submit crea spesa con `groupId`, `paidBy`, `splitType`, `splitData`

**Pre-fill:**
```dart
// Auto-select current user as payer
selectedPayer = currentUser.id;

// Pre-select all members for split
selectedSplitters = allMembers.map((m) => m.userId).toSet();

// Calculate equal splits
isEqualSplit = true;
splits = calculateEqualSplits(totalAmount, allMembers);
```

### 4.3 Contesto Vista (Multi-Gruppo)
**Comportamento:**
- ExpenseTypeSwitch parte da "Personale"
- Switch su "Di Gruppo": mostra lista di GroupSplitCard
- Ogni card rappresenta un gruppo della vista
- Cards collapsabili/espandibili
- Nessun gruppo pre-selezionato (utente sceglie)
- Se 1 gruppo selezionato: crea spesa singola
- Se >1 gruppo selezionato: dialog con opzioni (Spese Individuali / Crea Nuovo Gruppo)

**Lista Gruppi:**
```dart
ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  itemCount: view.groups.length,
  itemBuilder: (context, index) {
    final group = view.groups[index];
    return GroupSplitCard(
      group: group,
      members: cachedMembers[group.id] ?? [],
      isSelected: selectedGroups.contains(group.id),
      onSelectionChanged: (selected) => toggleGroupSelection(group.id, selected),
      // ... other callbacks
    );
  },
)
```

---

## 5. ARCHITETTURA COMPONENTI

### 5.1 Struttura File
```
lib/
├── widgets/
│   ├── expense_split/
│   │   ├── expense_type_switch.dart          # NEW: Personale/Di Gruppo switch
│   │   ├── group_split_card.dart             # NEW: Card gruppo espandibile
│   │   ├── user_selection_chip.dart          # NEW: Chip per "Chi paga"
│   │   ├── user_split_chip.dart              # NEW: Chip con importo editabile
│   │   ├── equally_split_toggle.dart         # NEW: Toggle inline "equamente"
│   │   └── split_summary_bar.dart            # NEW: Barra riepilogo totale
│   ├── group_expense_fields.dart             # DEPRECATED (old UI)
│   └── custom_split_editor.dart              # DEPRECATED (old UI)
├── models/
│   ├── expense_form.dart                     # REFACTOR: nuova UI integration
│   └── split_state.dart                      # NEW: State management per split
└── service/
    ├── group_service_cached.dart             # EXISTING: Use for members cache
    └── expense_service_cached.dart           # EXISTING: Use for expense ops
```

### 5.2 State Management

**Opzione 1: Stateful Widget (Current)**
- Continua con setState per semplicità
- State locale in _ExpenseFormWidgetState
- Pro: Nessuna dipendenza aggiuntiva, facile debug
- Contro: Più verbose, state scattered

**Opzione 2: Provider/ChangeNotifier (Recommended)**
- Crea `ExpenseSplitState` con ChangeNotifier
- Centralizza logica di business
- Pro: Codice più pulito, testabile, riusabile
- Contro: Overhead setup, nuova dipendenza

**Scelta:** Provider con `ExpenseSplitState` per scalabilità

### 5.3 ExpenseSplitState Model

```dart
class ExpenseSplitState extends ChangeNotifier {
  // Core data
  final List<GroupMember> members;
  final double totalAmount;

  // Split state
  String? selectedPayer;
  Set<String> selectedSplitters = {};
  Map<String, double> splits = {};
  bool isEqualSplit = true;

  // Computed
  double get currentTotal => splits.values.fold(0.0, (a, b) => a + b);
  double get remaining => totalAmount - currentTotal;
  bool get isValid => (remaining).abs() < 0.01;

  // Methods
  void selectPayer(String userId) { ... }
  void toggleSplitter(String userId) { ... }
  void updateSplitAmount(String userId, double amount) { ... }
  void toggleEqualSplit() { ... }
  void assignRemainingTo(String userId) { ... }
  void reset() { ... }
}
```

---

## 6. CACHING FRAMEWORK INTEGRATION

### 6.1 Preload Members
```dart
class _ExpenseFormWidgetState extends State<_ExpenseFormWidget> {
  late ExpenseSplitState _splitState;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (widget.isGroupContext && widget.groupId != null) {
      // ✅ Use cached service - O(1) lookup after first load
      final members = await GroupServiceCached().getGroupMembers(widget.groupId!);

      setState(() {
        _splitState = ExpenseSplitState(
          members: members,
          totalAmount: widget.expenseForm.moneyField.getFieldValue() as double? ?? 0.0,
        );

        // Pre-fill current user as payer
        _splitState.selectPayer(Supabase.instance.client.auth.currentUser?.id);

        // Pre-select all members for equal split
        for (var member in members) {
          _splitState.toggleSplitter(member.userId);
        }
      });
    }
  }
}
```

### 6.2 Bulk Operations per Vista
```dart
class _ViewExpenseFormWidgetState extends State<_ViewExpenseFormWidget> {
  final Map<String, List<GroupMember>> _membersCache = {};

  Future<void> _loadAllMembers() async {
    final groupService = GroupServiceCached();

    // ✅ Parallel fetch with cache
    final futures = widget.view.groups.map((group) async {
      final members = await groupService.getGroupMembers(group.id);
      _membersCache[group.id] = members;
    });

    await Future.wait(futures);
    setState(() {});
  }
}
```

### 6.3 Performance Target
- **Cold start (cache miss):** <500ms per caricare 1 gruppo
- **Warm load (cache hit):** <50ms per caricare 1 gruppo
- **Vista (5 gruppi):** <200ms total (parallel + cache)

---

## 7. MIGRATION STRATEGY

### 7.1 Phase 1: Nuovi Componenti (2-3 giorni)
- ✅ Creare ExpenseTypeSwitch
- ✅ Creare ExpenseSplitState
- ✅ Creare GroupSplitCard
- ✅ Creare UserSelectionChip
- ✅ Creare UserSplitChip
- ✅ Creare EquallySplitToggle
- ✅ Testing isolato componenti

### 7.2 Phase 2: Integration (1-2 giorni)
- ✅ Refactor _ExpenseFormWidget per gruppo singolo
- ✅ Refactor _ViewExpenseFormWidget per vista
- ✅ Integrazione caching
- ✅ Rimuovere old widgets (group_expense_fields, custom_split_editor)

### 7.3 Phase 3: Testing & Polish (1 giorno)
- ✅ Test funzionali end-to-end
- ✅ Test animazioni e transizioni
- ✅ Edge cases (0 membri, importi molto grandi, ecc.)
- ✅ Performance profiling

### 7.4 Backward Compatibility
- ✅ Database schema: NESSUNA modifica necessaria
- ✅ API ExpenseService: NESSUNA modifica
- ✅ Modelli Expense/Group: NESSUNA modifica
- ✅ Solo UI layer refactoring

---

## 8. CHECKLIST IMPLEMENTAZIONE

### Componenti UI
- [ ] ExpenseTypeSwitch component
- [ ] ExpenseSplitState model
- [ ] GroupSplitCard component
- [ ] UserSelectionChip component
- [ ] UserSplitChip component
- [ ] EquallySplitToggle component
- [ ] SplitSummaryBar component

### Logica Business
- [ ] Equal split calculation
- [ ] Custom split with manual editing
- [ ] Auto-disable equal on manual edit
- [ ] Assign remaining amount logic
- [ ] Validation rules
- [ ] Pre-fill logic per contesto

### Integrazioni
- [ ] _ExpenseFormWidget refactor (gruppo singolo)
- [ ] _ViewExpenseFormWidget refactor (vista)
- [ ] GroupServiceCached integration
- [ ] ExpenseServiceCached integration

### Testing
- [ ] Unit tests per ExpenseSplitState
- [ ] Widget tests per componenti
- [ ] Integration tests per form completo
- [ ] Performance benchmarks

### Cleanup
- [ ] Deprecate group_expense_fields.dart
- [ ] Deprecate custom_split_editor.dart
- [ ] Update documentation

---

## 9. STIMA TEMPI

| Fase | Tempo Stimato | Priorità |
|------|---------------|----------|
| Setup + ExpenseTypeSwitch | 3 ore | Alta |
| ExpenseSplitState model | 2 ore | Alta |
| GroupSplitCard | 4 ore | Alta |
| UserSelectionChip + UserSplitChip | 3 ore | Alta |
| EquallySplitToggle | 1 ora | Media |
| Logica divisione equa | 2 ore | Alta |
| Integration _ExpenseFormWidget | 3 ore | Alta |
| Integration _ViewExpenseFormWidget | 4 ore | Alta |
| Testing & Polish | 3 ore | Media |
| **TOTALE** | **25 ore (~3-4 giorni)** | |

---

## 10. RISCHI E MITIGAZIONI

| Rischio | Probabilità | Impatto | Mitigazione |
|---------|-------------|---------|-------------|
| Animazioni janky su device lenti | Media | Basso | Usa RepaintBoundary, testa su device fisico |
| Cache miss rallenta primo load | Alta | Medio | Preload in background, show loading spinner |
| Tastierino numerico copre UI | Media | Medio | Usa Scrollable, resizeToAvoidBottomInset |
| Utenti confusi da nuovo flow | Bassa | Alto | Tooltips, onboarding screen opzionale |
| Regression su spese esistenti | Bassa | Alto | Extensive testing, flag feature temporaneo |

---

## 11. SUCCESS METRICS

### Performance
- ✅ Load time gruppi: <500ms cold, <50ms warm
- ✅ Animazioni: 60fps costanti
- ✅ Memory usage: <50MB per form

### UX
- ✅ Tap target size: min 48x48dp
- ✅ Contrast ratio: WCAG AA compliant
- ✅ Keyboard navigation: fully supported

### Business
- ✅ 100% backward compatible
- ✅ 0 breaking changes in DB
- ✅ Codice coverage: >80%

---

**Creato da:** Claude Code Agent
**Review by:** Senior Frontend Engineer + Senior Software Architect
**Status:** Ready for Implementation ✅
