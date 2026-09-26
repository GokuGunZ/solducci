import 'dart:async';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/models/wallet_type.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/income_service.dart';
import 'package:solducci/service/wallet_transfer_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;

  WalletService._internal() {
    // Ricalcola i saldi quando cambiano le spese
    ExpenseServiceCached().stream.listen((_) => _recalculateBalances());
    // Ricalcola quando cambiano entrate o trasferimenti
    IncomeService().stream.listen((_) => _recalculateBalances());
    WalletTransferService().stream.listen((_) => _recalculateBalances());
  }

  final _supabase = Supabase.instance.client;
  final _walletsStreamController = StreamController<List<Wallet>>.broadcast();

  Stream<List<Wallet>> get stream => _walletsStreamController.stream;
  List<Wallet> _cachedWallets = [];
  List<Wallet> get currentWallets => _cachedWallets;

  /// Recupera tutti i portafogli attivi dell'utente con saldi aggiornati
  Future<List<Wallet>> fetchWallets() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', false)
          .order('is_default', ascending: false)
          .order('created_at', ascending: true);

      var list = (response as List)
          .map((item) => Wallet.fromMap(item as Map<String, dynamic>))
          .toList();

      // Se l'utente non ha portafogli, creiamo automaticamente i default (BNL/Principale + Contanti)
      if (list.isEmpty) {
        list = await _createInitialDefaultWallets(userId);
      }

      _cachedWallets = list;
      await _recalculateBalances();
      return _cachedWallets;
    } catch (e) {
      return _cachedWallets;
    }
  }

  /// Crea un nuovo portafoglio
  Future<Wallet> createWallet(Wallet wallet) async {
    final userId = _supabase.auth.currentUser?.id;
    final map = wallet.toMap();
    map['user_id'] = userId;
    map.remove('id');

    // Se questo è impostato come default, rimuovi il default dagli altri
    if (wallet.isDefault) {
      await _clearDefaults(userId!);
    }

    final response = await _supabase
        .from('wallets')
        .insert(map)
        .select()
        .single();

    final created = Wallet.fromMap(response);
    _cachedWallets.add(created);
    await _recalculateBalances();
    return created;
  }

  /// Aggiorna un portafoglio esistente
  Future<void> updateWallet(Wallet wallet) async {
    final userId = _supabase.auth.currentUser?.id;
    if (wallet.isDefault && userId != null) {
      await _clearDefaults(userId);
    }

    final map = wallet.toMap();
    await _supabase
        .from('wallets')
        .update(map)
        .eq('id', wallet.id);

    final idx = _cachedWallets.indexWhere((w) => w.id == wallet.id);
    if (idx >= 0) {
      _cachedWallets[idx] = wallet;
      await _recalculateBalances();
    }
  }

  /// Archivia un portafoglio (soft-delete per preservare la cronologia spese)
  Future<void> archiveWallet(String walletId) async {
    await _supabase
        .from('wallets')
        .update({'is_archived': true, 'is_default': false})
        .eq('id', walletId);

    _cachedWallets.removeWhere((w) => w.id == walletId);
    await _recalculateBalances();
  }

  /// Imposta un portafoglio come predefinito
  Future<void> setDefaultWallet(String walletId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _clearDefaults(userId);
    await _supabase
        .from('wallets')
        .update({'is_default': true})
        .eq('id', walletId);

    for (final w in _cachedWallets) {
      w.copyWith(isDefault: w.id == walletId);
    }
    await fetchWallets();
  }

  /// Restituisce il portafoglio predefinito dell'utente (o il primo disponibile)
  Wallet? getDefaultWallet() {
    if (_cachedWallets.isEmpty) return null;
    return _cachedWallets.firstWhere(
      (w) => w.isDefault,
      orElse: () => _cachedWallets.first,
    );
  }

  /// Calcola deterministamente il saldo per ogni portafoglio
  Future<void> _recalculateBalances() async {
    if (_cachedWallets.isEmpty) return;

    final expenses = ExpenseServiceCached().getAllCachedExpenses();
    final incomes = IncomeService().currentIncomes;
    final transfers = WalletTransferService().currentTransfers;

    for (final wallet in _cachedWallets) {
      // 1. Saldo Iniziale
      var balance = wallet.initialBalance;

      // 2. Sottrai Spese associate a questo wallet
      final walletExpenses = expenses.where((e) => e.walletId == wallet.id);
      for (final exp in walletExpenses) {
        balance -= exp.amount;
      }

      // 3. Aggiungi Entrate associate a questo wallet
      final walletIncomes = incomes.where((i) => i.walletId == wallet.id);
      for (final inc in walletIncomes) {
        balance += inc.amount;
      }

      // 4. Gestisci Giroconti (Entrate e Uscite da altri portafogli)
      final incomingTransfers = transfers.where((t) => t.toWalletId == wallet.id);
      for (final t in incomingTransfers) {
        balance += t.amount;
      }

      final outgoingTransfers = transfers.where((t) => t.fromWalletId == wallet.id);
      for (final t in outgoingTransfers) {
        balance -= t.amount;
      }

      wallet.currentBalance = balance;
    }

    _walletsStreamController.add(List.from(_cachedWallets));
  }

  /// Somma della liquidità di tutti i portafogli attivi
  double get totalLiquidity {
    return _cachedWallets.fold(0.0, (sum, w) => sum + w.currentBalance);
  }

  Future<void> _clearDefaults(String userId) async {
    await _supabase
        .from('wallets')
        .update({'is_default': false})
        .eq('user_id', userId);
  }

  Future<List<Wallet>> _createInitialDefaultWallets(String userId) async {
    final mainWallet = Wallet(
      id: '',
      userId: userId,
      name: 'Conto Principale (BNL)',
      type: WalletType.bank,
      initialBalance: 0.0,
      colorHex: '#10B981',
      iconName: 'account_balance',
      isDefault: true,
    );

    final cashWallet = Wallet(
      id: '',
      userId: userId,
      name: 'Portafoglio Contanti',
      type: WalletType.cash,
      initialBalance: 0.0,
      colorHex: '#F59E0B',
      iconName: 'payments',
      isDefault: false,
    );

    final w1 = await createWallet(mainWallet);
    final w2 = await createWallet(cashWallet);
    return [w1, w2];
  }
}
