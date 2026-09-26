import 'dart:async';
import 'package:solducci/models/wallet_transfer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletTransferService {
  static final WalletTransferService _instance = WalletTransferService._internal();
  factory WalletTransferService() => _instance;
  WalletTransferService._internal();

  final _supabase = Supabase.instance.client;
  final _transfersStreamController = StreamController<List<WalletTransfer>>.broadcast();

  Stream<List<WalletTransfer>> get stream => _transfersStreamController.stream;
  List<WalletTransfer> _cachedTransfers = [];
  List<WalletTransfer> get currentTransfers => _cachedTransfers;

  Future<List<WalletTransfer>> fetchTransfers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('wallet_transfers')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      final list = (response as List)
          .map((item) => WalletTransfer.fromMap(item as Map<String, dynamic>))
          .toList();

      _cachedTransfers = list;
      _transfersStreamController.add(list);
      return list;
    } catch (e) {
      return _cachedTransfers;
    }
  }

  Future<WalletTransfer> createTransfer(WalletTransfer newTransfer) async {
    final userId = _supabase.auth.currentUser?.id;
    final map = newTransfer.toMap();
    map['user_id'] = userId;
    map.remove('id');

    final response = await _supabase
        .from('wallet_transfers')
        .insert(map)
        .select()
        .single();

    final created = WalletTransfer.fromMap(response);
    _cachedTransfers.insert(0, created);
    _transfersStreamController.add(_cachedTransfers);
    return created;
  }

  Future<void> deleteTransfer(String id) async {
    await _supabase.from('wallet_transfers').delete().eq('id', id);
    _cachedTransfers.removeWhere((t) => t.id == id);
    _transfersStreamController.add(_cachedTransfers);
  }
}
