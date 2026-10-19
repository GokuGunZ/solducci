import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/models/wallet_transfer.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/service/wallet_transfer_service.dart';
import 'package:solducci/service/app_navigation_coordinator.dart';
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

  int _wallet1Index = 0; // Left wallet
  int _wallet2Index = 1; // Right wallet
  double _arrowTurns = 0.0;
  double _selectedAmount = 50.0;
  double? _customAmount;

  bool get _isReversed => (_arrowTurns % 1.0) != 0.0;
  Wallet get _fromWallet => _isReversed ? _wallets[_wallet2Index] : _wallets[_wallet1Index];
  Wallet get _toWallet => _isReversed ? _wallets[_wallet1Index] : _wallets[_wallet2Index];

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
      if (_wallet1Index >= _wallets.length) _wallet1Index = 0;
      if (_wallet2Index >= _wallets.length || _wallet2Index == _wallet1Index) {
        _wallet2Index = (_wallet1Index + 1) % _wallets.length;
      }
    }
  }

  void _swapWallets() {
    HapticFeedback.selectionClick();
    setState(() {
      _arrowTurns += 0.5;
    });
  }

  void _selectWallet({required bool isLeft}) {
    HapticFeedback.selectionClick();
    if (_wallets.length < 2) return;

    final targetIndex = isLeft ? _wallet1Index : _wallet2Index;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.65,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF18181D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white12, width: 1),
              left: BorderSide(color: Colors.white12, width: 1),
              right: BorderSide(color: Colors.white12, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isLeft ? 'Seleziona conto di sinistra' : 'Seleziona conto di destra',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final wallet = _wallets[idx];
                      final isCurrent = idx == targetIndex;
                      final isOther = isLeft ? (idx == _wallet2Index) : (idx == _wallet1Index);

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (isOther) {
                              // If they tap the one currently in the other slot, swap positions
                              final temp = _wallet1Index;
                              _wallet1Index = _wallet2Index;
                              _wallet2Index = temp;
                            } else {
                              if (isLeft) {
                                _wallet1Index = idx;
                              } else {
                                _wallet2Index = idx;
                              }
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF06B6D4).withOpacity(0.15)
                                : const Color(0xFF27272A).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent ? const Color(0xFF06B6D4) : Colors.white.withOpacity(0.06),
                              width: isCurrent ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: wallet.color.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(wallet.type.icon, size: 18, color: wallet.color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wallet.name,
                                      style: TextStyle(
                                        color: isCurrent ? Colors.white : Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '€ ${wallet.currentBalance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isCurrent ? const Color(0xFF22D3EE) : Colors.white60,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF06B6D4), size: 20)
                              else if (isOther)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Inverti',
                                    style: TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomAmountDialog() {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(
      text: _customAmount != null ? (_customAmount! % 1 == 0 ? _customAmount!.toInt().toString() : _customAmount!.toStringAsFixed(2)) : '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF18181D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Colors.white12, width: 1),
                left: BorderSide(color: Colors.white12, width: 1),
                right: BorderSide(color: Colors.white12, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Importo personalizzato',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Inserisci la cifra da trasferire',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: '€ ',
                      prefixStyle: const TextStyle(
                        color: Color(0xFF22D3EE),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: '0',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF27272A).withOpacity(0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 1.6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final val = double.tryParse(controller.text.replaceAll(',', '.').trim());
                        if (val != null && val > 0) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _customAmount = val;
                            _selectedAmount = val;
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Conferma importo',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _executeTransfer(double amount) async {
    if (_wallets.length < 2 || _isTransferring) return;

    final fromWallet = _fromWallet;
    final toWallet = _toWallet;

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
        notes: 'Giroconto Bento',
      );

      await _transferService.createTransfer(newTrf);

      if (mounted) {
        final amountText = amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Spostati € $amountText da ${fromWallet.name} a ${toWallet.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF18181D),
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
      onTap: () => AppNavigationCoordinator().navigateToEconomy(context, section: 'wallets'),
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
    final fromWallet = _fromWallet;
    final toWallet = _toWallet;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _swapWallets,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: AnimatedRotation(
                  turns: _arrowTurns,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic,
                  child: const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF22D3EE)),
                ),
              ),
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
                    'Sposta €${_selectedAmount % 1 == 0 ? _selectedAmount.toInt() : _selectedAmount.toStringAsFixed(1)}',
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
    final walletA = _wallets[_wallet1Index];
    final walletB = _wallets[_wallet2Index];
    final isSourceA = !_isReversed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Header
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

        // Accounts overview
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A).withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left wallet
              Expanded(
                child: InkWell(
                  onTap: () => _selectWallet(isLeft: true),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          walletA.name,
                          style: TextStyle(
                            color: isSourceA ? Colors.white : Colors.white70,
                            fontSize: 10.5,
                            fontWeight: isSourceA ? FontWeight.w600 : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '€ ${walletA.currentBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isSourceA ? const Color(0xFF22D3EE) : Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Interactive rotating arrow button
              InkWell(
                onTap: _swapWallets,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withOpacity(0.4),
                      width: 0.8,
                    ),
                  ),
                  child: AnimatedRotation(
                    turns: _arrowTurns,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    child: const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF22D3EE)),
                  ),
                ),
              ),

              // Right wallet
              Expanded(
                child: InkWell(
                  onTap: () => _selectWallet(isLeft: false),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          walletB.name,
                          style: TextStyle(
                            color: !isSourceA ? Colors.white : Colors.white70,
                            fontSize: 10.5,
                            fontWeight: !isSourceA ? FontWeight.w600 : FontWeight.w500,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '€ ${walletB.currentBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: !isSourceA ? const Color(0xFF22D3EE) : Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
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

  // Taglia 2x3 (Altezza 3)
  Widget _buildExpandedView() {
    final walletA = _wallets[_wallet1Index];
    final walletB = _wallets[_wallet2Index];
    final isSourceA = !_isReversed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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
              'Giroconto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Conti overview (senza Da/A e senza barra colorata per ottimizzare lo spazio)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A).withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Wallet A (Sinistra)
              Expanded(
                child: InkWell(
                  onTap: () => _selectWallet(isLeft: true),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                walletA.name,
                                style: TextStyle(
                                  color: isSourceA ? Colors.white : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: isSourceA ? FontWeight.w600 : FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down_rounded, size: 14, color: Colors.white38),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '€ ${walletA.currentBalance.toStringAsFixed(2)}',
                            maxLines: 1,
                            style: TextStyle(
                              color: isSourceA ? const Color(0xFF22D3EE) : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottone interattivo freccia che ruota su se stesso
              InkWell(
                onTap: _swapWallets,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: AnimatedRotation(
                    turns: _arrowTurns,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: Color(0xFF22D3EE),
                    ),
                  ),
                ),
              ),

              // Wallet B (Destra)
              Expanded(
                child: InkWell(
                  onTap: () => _selectWallet(isLeft: false),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.arrow_drop_down_rounded, size: 14, color: Colors.white38),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                walletB.name,
                                style: TextStyle(
                                  color: !isSourceA ? Colors.white : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: !isSourceA ? FontWeight.w600 : FontWeight.w500,
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '€ ${walletB.currentBalance.toStringAsFixed(2)}',
                            maxLines: 1,
                            style: TextStyle(
                              color: !isSourceA ? const Color(0xFF22D3EE) : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Selettore importo: 10, 25, 50 + chip "__" personalizzabile
        Row(
          children: [
            ...[10.0, 25.0, 50.0].map((amt) {
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
            }),
            _buildCustomAmountChip(),
          ],
        ),

        const Spacer(),
        const SizedBox(height: 8),

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
                        'Trasferisci € ${_selectedAmount % 1 == 0 ? _selectedAmount.toInt() : _selectedAmount.toStringAsFixed(2)}',
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

  Widget _buildCustomAmountChip() {
    final isCustomSel = _selectedAmount == _customAmount && _customAmount != null;
    final customLabel = _customAmount != null
        ? '€${_customAmount! % 1 == 0 ? _customAmount!.toInt() : _customAmount!.toStringAsFixed(1)}'
        : '__';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: InkWell(
          onTap: () {
            if (_customAmount == null || isCustomSel) {
              _showCustomAmountDialog();
            } else {
              HapticFeedback.selectionClick();
              setState(() => _selectedAmount = _customAmount!);
            }
          },
          onLongPress: _showCustomAmountDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isCustomSel ? const Color(0xFF06B6D4).withOpacity(0.25) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCustomSel ? const Color(0xFF06B6D4) : Colors.white12,
                width: isCustomSel ? 1.4 : 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              customLabel,
              style: TextStyle(
                color: isCustomSel ? const Color(0xFF22D3EE) : (_customAmount != null ? Colors.white70 : Colors.white38),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: _customAmount == null ? 1.5 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
