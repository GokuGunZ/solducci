import 'package:flutter/foundation.dart';
import 'package:solducci/models/group.dart';

/// State management per la divisione di una spesa tra membri di un gruppo
///
/// Gestisce:
/// - Selezione di chi ha pagato (payer)
/// - Selezione di chi partecipa alla divisione (splitters)
/// - Calcolo automatico della divisione equa
/// - Modifica manuale degli importi (custom split)
/// - Validazione del totale
class ExpenseSplitState extends ChangeNotifier {
  // Core data
  final List<GroupMember> members;
  double totalAmount;

  // Split state
  String? _selectedPayer;
  final Set<String> _selectedSplitters = {};
  final Map<String, double> _splits = {};
  bool _isEqualSplit = true;

  ExpenseSplitState({
    required this.members,
    required this.totalAmount,
    String? initialPayer,
    Set<String>? initialSplitters,
    Map<String, double>? initialSplits,
    bool initialIsEqualSplit = true,
  })  : _selectedPayer = initialPayer,
        _isEqualSplit = initialIsEqualSplit {
    // Initialize splitters
    if (initialSplitters != null) {
      _selectedSplitters.addAll(initialSplitters);
    }

    // Initialize splits
    if (initialSplits != null) {
      _splits.addAll(initialSplits);
    }

    // If equal split and splits not provided, calculate
    if (_isEqualSplit && _splits.isEmpty && _selectedSplitters.isNotEmpty) {
      _calculateEqualSplits();
    }
  }

  // Getters
  String? get selectedPayer => _selectedPayer;
  Set<String> get selectedSplitters => Set.unmodifiable(_selectedSplitters);
  Map<String, double> get splits => Map.unmodifiable(_splits);
  bool get isEqualSplit => _isEqualSplit;

  // Computed properties
  double get currentTotal => _splits.values.fold(0.0, (a, b) => a + b);
  double get remaining => totalAmount - currentTotal;
  bool get isValid => (remaining).abs() < 0.01 && _selectedSplitters.isNotEmpty;
  bool get hasRemaining => remaining > 0.01;

  /// Seleziona chi ha pagato la spesa
  void selectPayer(String? userId) {
    if (_selectedPayer == userId) return;

    _selectedPayer = userId;
    notifyListeners();
  }

  /// Toggle selezione di un utente per la divisione
  void toggleSplitter(String userId) {
    if (_selectedSplitters.contains(userId)) {
      // Rimuovi utente
      _selectedSplitters.remove(userId);
      _splits.remove(userId);

      // Se equal split è attivo, ricalcola per i rimanenti
      if (_isEqualSplit && _selectedSplitters.isNotEmpty) {
        _calculateEqualSplits();
      }
    } else {
      // Aggiungi utente
      _selectedSplitters.add(userId);

      if (_isEqualSplit) {
        // Ricalcola equamente con il nuovo utente
        _calculateEqualSplits();
      } else {
        // Modalità custom: inizializza a 0
        _splits[userId] = 0.0;
      }
    }

    notifyListeners();
  }

  /// Aggiorna l'importo per un utente specifico (modalità custom)
  void updateSplitAmount(String userId, double amount) {
    if (!_selectedSplitters.contains(userId)) return;

    _splits[userId] = amount;

    // Disattiva automaticamente "equal split" quando si modifica manualmente
    if (_isEqualSplit) {
      _isEqualSplit = false;
    }

    notifyListeners();
  }

  /// Toggle modalità divisione equa
  void toggleEqualSplit() {
    _isEqualSplit = !_isEqualSplit;

    if (_isEqualSplit) {
      // Ricalcola equamente tra utenti selezionati
      _calculateEqualSplits();
    }

    notifyListeners();
  }

  /// Assegna il resto rimanente a un utente specifico
  void assignRemainingTo(String userId) {
    if (!_selectedSplitters.contains(userId)) return;

    final remainingAmount = remaining;
    if (remainingAmount > 0.01) {
      final currentAmount = _splits[userId] ?? 0.0;
      _splits[userId] = double.parse((currentAmount + remainingAmount).toStringAsFixed(2));

      // Disattiva equal split quando si assegna manualmente
      if (_isEqualSplit) {
        _isEqualSplit = false;
      }

      notifyListeners();
    }
  }

  /// Calcola la divisione equa tra gli utenti selezionati
  void _calculateEqualSplits() {
    if (_selectedSplitters.isEmpty) {
      _splits.clear();
      return;
    }

    final amountPerPerson = totalAmount / _selectedSplitters.length;
    final roundedAmount = double.parse(amountPerPerson.toStringAsFixed(2));

    // Assegna importo equo a tutti
    for (final userId in _selectedSplitters) {
      _splits[userId] = roundedAmount;
    }

    // Gestisci arrotondamenti: assegna differenza al primo utente
    final difference = totalAmount - (_splits.values.fold(0.0, (a, b) => a + b));
    if (difference.abs() > 0.01) {
      final firstUser = _selectedSplitters.first;
      _splits[firstUser] = double.parse(
        ((_splits[firstUser] ?? 0.0) + difference).toStringAsFixed(2),
      );
    }
  }

  /// Pre-seleziona tutti i membri per la divisione equa
  void preselectAllMembers({String? payerId}) {
    _selectedSplitters.clear();
    _selectedSplitters.addAll(members.map((m) => m.userId));

    if (payerId != null) {
      _selectedPayer = payerId;
    }

    _isEqualSplit = true;
    _calculateEqualSplits();

    notifyListeners();
  }

  /// Aggiorna il totale della spesa e ricalcola gli split
  void updateTotalAmount(double newAmount) {
    if ((totalAmount - newAmount).abs() < 0.01) return; // No change

    totalAmount = newAmount;

    // Ricalcola splits se in modalità equal
    if (_isEqualSplit && _selectedSplitters.isNotEmpty) {
      _calculateEqualSplits();
    }

    notifyListeners();
  }

  /// Reset dello stato
  void reset() {
    _selectedPayer = null;
    _selectedSplitters.clear();
    _splits.clear();
    _isEqualSplit = true;
    notifyListeners();
  }

  /// Ottieni il membro con l'userId specificato
  GroupMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Verifica se un utente è selezionato per lo split
  bool isSplitterSelected(String userId) {
    return _selectedSplitters.contains(userId);
  }

  /// Ottieni l'importo per un utente
  double getSplitAmount(String userId) {
    return _splits[userId] ?? 0.0;
  }

  @override
  String toString() {
    return 'ExpenseSplitState('
        'total: $totalAmount, '
        'payer: $_selectedPayer, '
        'splitters: ${_selectedSplitters.length}, '
        'splits: ${_splits.length}, '
        'isEqual: $_isEqualSplit, '
        'currentTotal: ${currentTotal.toStringAsFixed(2)}, '
        'valid: $isValid'
        ')';
  }
}
