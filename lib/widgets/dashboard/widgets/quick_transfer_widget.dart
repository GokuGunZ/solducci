import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/models/wallet_transfer.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/service/wallet_transfer_service.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

class QuickTransferWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const QuickTransferWidget({super.key, required this.def});

  @override
  State<QuickTransferWidget> createState() => _QuickTransferWidgetState();
}

class _QuickTransferWidgetState extends State<QuickTransferWidget> {
  final _walletService = WalletService();
  final _transferService = WalletTransferService();

  StreamSubscription? _walletSub;
  List<Wallet> _wallets = [];
  bool _isLoading = true;
  bool _isTransferring = false;

  int _fromIndex = 0;
  int _toIndex = 1;
  double _selectedAmount = 50.0;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _walletSub = _walletService.stream.listen((wallets) {
      if (mounted) {
        setState(() {
          _wallets = wallets;
          _isLoading = false;
          _ensureValidIndices();
        });
      }
    });
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    final wallets = await _walletService.fetchWallets();
    if (mounted) {
      setState(() {
        _wallets = wallets;
        _isLoading = false;
        _ensureValidIndices();
      });
    }
  }

  void _ensureValidIndices() {
    if (_wallets.length >= 2) {
      if (_fromIndex >= _wallets.length) _fromIndex = 0;
      if (_toIndex >= _wallets.length || _toIndex == _fromIndex) {
        _toIndex = (_fromIndex + 1) % _wallets.length;
      }
    }
  }

  void _swapWallets() {
    HapticFeedback.selectionClick();
    setState(() {
      final temp = _fromIndex;
      _fromIndex = _toIndex;
      _toIndex = temp;
    });
  }

  Future<void> _executeTransfer(double amount) async {
    if (_wallets.length < 2 || _isTransferring) return;

    final fromWallet = _wallets[_fromIndex];
    final toWallet = _wallets[_toIndex];

    HapticFeedback.lightImpact();
    setState(() => _isTransferring = true);

    try {
      final newTrf = WalletTransfer(
        id: '',
        userId: '',
        fromWalletId: fromWallet.id,
        toWalletId: toWallet.id,
        amount: amount,
        date: DateTime.now(),
        notes: 'Giroconto Rapido Bento',
      );

      await _transferService.createTransfer(newTrf);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Spostati € ${amount.toStringAsFixed(0)} da ${fromWallet.name} a ${toWallet.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF18181B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF10B981), width: 1),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore giroconto: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTransferring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.def.size;
    final isHeight1 = size.mainAxisCellCount <= 1;

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: size,
      isLoading: _isLoading,
      onTap: () => context.push('/economy/wallets'),
      child: Padding(
        padding: isHeight1
            ? const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0)
            : const EdgeInsets.all(12.0),
        child: _wallets.length < 2
            ? _buildNotEnoughWallets()
            : (isHeight1
                ? _buildMiniBanner()
                : (size.mainAxisCellCount <= 2 ? _buildCompactView() : _buildExpandedView())),
      ),
    );
  }

  Widget _buildNotEnoughWallets() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.swap_horiz_rounded, size: 20, color: Color(0xFF06B6D4)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Servono 2 conti per il giroconto',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Taglia 2x1 (Altezza 1, Mini-Banner Azione Puntiforme)
  Widget _buildMiniBanner() {
    final fromWallet = _wallets[_fromIndex];
    final toWallet = _wallets[_toIndex];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_horiz_rounded, size: 13, color: Color(0xFF22D3EE)),
            ),
            const SizedBox(width: 8),
            Text(
              '${fromWallet.name} ➔ ${toWallet.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isTransferring ? null : () => _executeTransfer(_selectedAmount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.55)),
            ),
            child: _isTransferring
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF22D3EE)),
                  )
                : Text(
                    'Sposta €${_selectedAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF22D3EE),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Taglia 2x2 (Altezza 2, Bottone Arricchito con Contorno Attivo)
  Widget _buildCompactView() {
    final fromWallet = _wallets[_fromIndex];
    final toWallet = _wallets[_toIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF22D3EE)),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Giroconto',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: _swapWallets,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_alt_rounded, size: 11, color: Colors.white60),
                    SizedBox(width: 3),
                    Text('Inverti', style: TextStyle(color: Colors.white60, fontSize: 9.5)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Accounts overview
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A).withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fromWallet.name,
                      style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '€ ${fromWallet.currentBalance.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF22D3EE)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      toWallet.name,
                      style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '€ ${toWallet.currentBalance.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick amounts & action
        Row(
          children: [
            ...[10.0, 25.0, 50.0].map((amt) {
              final isSel = _selectedAmount == amt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedAmount = amt);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF06B6D4).withOpacity(0.25) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel ? const Color(0xFF06B6D4) : Colors.white10,
                          width: isSel ? 1.2 : 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '€${amt.toInt()}',
                        style: TextStyle(
                          color: isSel ? const Color(0xFF22D3EE) : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isTransferring ? null : () => _executeTransfer(_selectedAmount),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isTransferring
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black),
                      )
                    : const Icon(Icons.send_rounded, size: 12, color: Colors.black),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Taglia 2x3 (Altezza 3, Due Livelli a Confronto)
  Widget _buildExpandedView() {
    final fromWallet = _wallets[_fromIndex];
    final toWallet = _wallets[_toIndex];
    final total = fromWallet.currentBalance + toWallet.currentBalance;
    final shareA = total > 0 ? (fromWallet.currentBalance / total).clamp(0.0, 1.0) : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF22D3EE)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Giroconto Rapido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: _swapWallets,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_alt_rounded, size: 12, color: Colors.white70),
                    SizedBox(width: 4),
                    Text('Inverti', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Livello 1: Conti & Bilanciamento Liquidità
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A).withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DA: ${fromWallet.name}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '€ ${fromWallet.currentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF22D3EE)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'A: ${toWallet.name}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '€ ${toWallet.currentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Split bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Row(
                  children: [
                    Expanded(
                      flex: (shareA * 100).toInt(),
                      child: Container(height: 4, color: const Color(0xFF06B6D4)),
                    ),
                    Expanded(
                      flex: ((1 - shareA) * 100).toInt(),
                      child: Container(height: 4, color: const Color(0xFF8B5CF6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Livello 2: Selettore importo + Bottone di trasferimento
        Row(
          children: [10.0, 25.0, 50.0, 100.0].map((amt) {
            final isSel = _selectedAmount == amt;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedAmount = amt);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF06B6D4).withOpacity(0.25) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel ? const Color(0xFF06B6D4) : Colors.white12,
                        width: isSel ? 1.4 : 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '€${amt.toInt()}',
                      style: TextStyle(
                        color: isSel ? const Color(0xFF22D3EE) : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const Spacer(),

        // Action button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isTransferring ? null : () => _executeTransfer(_selectedAmount),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _isTransferring
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.black),
                      const SizedBox(width: 6),
                      Text(
                        'Trasferisci € ${_selectedAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
