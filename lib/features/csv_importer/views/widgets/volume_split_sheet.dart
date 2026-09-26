import 'package:flutter/material.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/theme/app_theme.dart';

class VolumeSplitSheet extends StatefulWidget {
  final StagingTransaction transaction;
  final ExpenseGroup group;
  final List<GroupMember> members;
  final String currentUserId;
  final void Function(SplitType splitType, Map<String, double>? splitData) onSplitConfirmed;

  const VolumeSplitSheet({
    super.key,
    required this.transaction,
    required this.group,
    required this.members,
    required this.currentUserId,
    required this.onSplitConfirmed,
  });

  @override
  State<VolumeSplitSheet> createState() => _VolumeSplitSheetState();
}

class _VolumeSplitSheetState extends State<VolumeSplitSheet> {
  late double _totalAmount;
  late List<GroupMember> _effectiveMembers;
  late GroupMember _activeUser;
  GroupMember? _otherMember; // Solo se esattamete 2 persone

  // Stato per 2 persone (Cross-fader)
  late double _activeUserAmount;

  // Stato per > 2 persone (Multi-channel Mixer)
  final Map<String, double> _channelAmounts = {};
  final Set<String> _excludedUserIds = {};
  final Set<String> _lockedUserIds = {};

  @override
  void initState() {
    super.initState();
    _totalAmount = widget.transaction.amount;

    // Se la lista membri fornita è vuota, creiamo fallback con l'utente corrente
    if (widget.members.isEmpty) {
      _effectiveMembers = [
        GroupMember(
          id: 'temp_active',
          groupId: widget.group.id,
          userId: widget.currentUserId,
          role: GroupRole.admin,
          joinedAt: DateTime.now(),
          nickname: 'Tu',
        ),
      ];
    } else {
      _effectiveMembers = List.from(widget.members);
    }

    // Trova o assegna l'utente attivo
    _activeUser = _effectiveMembers.firstWhere(
      (m) => m.userId == widget.currentUserId,
      orElse: () => _effectiveMembers.first,
    );

    if (_isTwoPeopleMode) {
      _otherMember = _effectiveMembers.firstWhere((m) => m.userId != _activeUser.userId);
      _initTwoPeopleAmounts();
    } else {
      _initMultiPeopleAmounts();
    }
  }

  bool get _isTwoPeopleMode => _effectiveMembers.length == 2;

  // -------------------------------------------------------------
  // INIZIALIZZAZIONE 2 PERSONE (Cross-fader)
  // -------------------------------------------------------------
  void _initTwoPeopleAmounts() {
    final existingCustom = widget.transaction.customSplitData;
    if (existingCustom != null && existingCustom.containsKey(_activeUser.userId)) {
      _activeUserAmount = existingCustom[_activeUser.userId]!;
      if (_activeUserAmount > _totalAmount) _activeUserAmount = _totalAmount;
      if (_activeUserAmount < 0) _activeUserAmount = 0;
    } else {
      // Default: 50%
      _activeUserAmount = double.parse((_totalAmount / 2).toStringAsFixed(2));
    }
  }

  double get _otherMemberAmount {
    final other = _totalAmount - _activeUserAmount;
    return other < 0 ? 0.0 : double.parse(other.toStringAsFixed(2));
  }

  // -------------------------------------------------------------
  // INIZIALIZZAZIONE > 2 PERSONE (Mixer)
  // -------------------------------------------------------------
  void _initMultiPeopleAmounts() {
    final existingCustom = widget.transaction.customSplitData;
    if (existingCustom != null && existingCustom.isNotEmpty) {
      for (final m in _effectiveMembers) {
        final amt = existingCustom[m.userId] ?? 0.0;
        _channelAmounts[m.userId] = amt;
        if (amt == 0.0) _excludedUserIds.add(m.userId);
      }
    } else {
      _setEqualSplitMulti();
    }
  }

  void _setEqualSplitMulti() {
    final activeCount = _effectiveMembers.length - _excludedUserIds.length;
    if (activeCount <= 0) return;

    final basePerPerson = (_totalAmount / activeCount);
    double accumulated = 0.0;
    final activeMembers = _effectiveMembers.where((m) => !_excludedUserIds.contains(m.userId)).toList();

    for (var i = 0; i < activeMembers.length; i++) {
      final m = activeMembers[i];
      if (i == activeMembers.length - 1) {
        // Assegna il residuo all'ultimo per garantire somma esatta al centesimo
        _channelAmounts[m.userId] = double.parse((_totalAmount - accumulated).toStringAsFixed(2));
      } else {
        final val = double.parse(basePerPerson.toStringAsFixed(2));
        _channelAmounts[m.userId] = val;
        accumulated += val;
      }
    }

    for (final id in _excludedUserIds) {
      _channelAmounts[id] = 0.0;
    }
  }

  double get _multiCurrentTotal {
    return _channelAmounts.values.fold(0.0, (sum, val) => sum + val);
  }

  bool get _isMultiBalanced {
    return (_multiCurrentTotal - _totalAmount).abs() < 0.015;
  }

  // -------------------------------------------------------------
  // LOGICA SLIDER 2 PERSONE (Scatti da 0.50€ sull'utente attivo)
  // -------------------------------------------------------------
  void _onTwoPeopleSliderChanged(double rawVal) {
    setState(() {
      // Arrotonda a step fissi di 0.50€
      double stepped = (rawVal / 0.50).round() * 0.50;
      if (stepped > _totalAmount) stepped = _totalAmount;
      if (stepped < 0) stepped = 0.0;
      _activeUserAmount = double.parse(stepped.toStringAsFixed(2));
    });
  }

  void _setExactFiftyFifty() {
    setState(() {
      _activeUserAmount = double.parse((_totalAmount / 2).toStringAsFixed(2));
    });
  }

  void _setFullActiveUser() {
    setState(() {
      _activeUserAmount = _totalAmount;
    });
  }

  void _setFullOtherUser() {
    setState(() {
      _activeUserAmount = 0.0;
    });
  }

  // -------------------------------------------------------------
  // LOGICA SLIDER > 2 PERSONE (Mixer con step da 0.50€ e ribilanciamento)
  // -------------------------------------------------------------
  void _onMultiSliderChanged(String userId, double rawVal) {
    if (_excludedUserIds.contains(userId)) return;

    setState(() {
      // Arrotonda a step di 0.50€
      double stepped = (rawVal / 0.50).round() * 0.50;
      if (stepped > _totalAmount) stepped = _totalAmount;
      if (stepped < 0) stepped = 0.0;

      final oldVal = _channelAmounts[userId] ?? 0.0;
      final diff = stepped - oldVal;
      _channelAmounts[userId] = stepped;

      // Trova gli altri canali sbloccati ed inclusi per ribilanciare
      final otherEligible = _effectiveMembers
          .where((m) => m.userId != userId && !_excludedUserIds.contains(m.userId) && !_lockedUserIds.contains(m.userId))
          .toList();

      if (otherEligible.isNotEmpty) {
        final deltaPerOther = diff / otherEligible.length;
        for (final other in otherEligible) {
          final cur = _channelAmounts[other.userId] ?? 0.0;
          double next = cur - deltaPerOther;
          if (next < 0) next = 0.0;
          _channelAmounts[other.userId] = double.parse(next.toStringAsFixed(2));
        }
      }
    });
  }

  void _toggleExcludeUser(String userId) {
    setState(() {
      if (_excludedUserIds.contains(userId)) {
        _excludedUserIds.remove(userId);
      } else {
        _excludedUserIds.add(userId);
        _lockedUserIds.remove(userId);
        _channelAmounts[userId] = 0.0;
      }
      _setEqualSplitMulti();
    });
  }

  void _toggleLockUser(String userId) {
    if (_excludedUserIds.contains(userId)) return;
    setState(() {
      if (_lockedUserIds.contains(userId)) {
        _lockedUserIds.remove(userId);
      } else {
        _lockedUserIds.add(userId);
      }
    });
  }

  void _autoBalanceMulti() {
    setState(() {
      final activeUnlocked = _effectiveMembers
          .where((m) => !_excludedUserIds.contains(m.userId) && !_lockedUserIds.contains(m.userId))
          .toList();

      if (activeUnlocked.isEmpty) return;

      final lockedTotal = _effectiveMembers
          .where((m) => _lockedUserIds.contains(m.userId))
          .fold(0.0, (sum, m) => sum + (_channelAmounts[m.userId] ?? 0.0));

      final remaining = _totalAmount - lockedTotal;
      if (remaining <= 0) {
        for (final m in activeUnlocked) {
          _channelAmounts[m.userId] = 0.0;
        }
        return;
      }

      final perPerson = remaining / activeUnlocked.length;
      double acc = 0.0;
      for (var i = 0; i < activeUnlocked.length; i++) {
        final m = activeUnlocked[i];
        if (i == activeUnlocked.length - 1) {
          _channelAmounts[m.userId] = double.parse((remaining - acc).toStringAsFixed(2));
        } else {
          final v = double.parse(perPerson.toStringAsFixed(2));
          _channelAmounts[m.userId] = v;
          acc += v;
        }
      }
    });
  }

  // -------------------------------------------------------------
  // SALVATAGGIO
  // -------------------------------------------------------------
  void _confirmSplit() {
    if (_isTwoPeopleMode) {
      final isExactlyFifty = (_activeUserAmount - (_totalAmount / 2)).abs() < 0.015;
      if (isExactlyFifty) {
        widget.onSplitConfirmed(SplitType.equal, null);
      } else {
        final data = <String, double>{
          _activeUser.userId: _activeUserAmount,
          _otherMember!.userId: _otherMemberAmount,
        };
        widget.onSplitConfirmed(SplitType.custom, data);
      }
    } else {
      if (!_isMultiBalanced) {
        _autoBalanceMulti();
      }
      widget.onSplitConfirmed(SplitType.custom, Map.from(_channelAmounts));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141417),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header con info spesa e gruppo
              _buildHeader(),
              const SizedBox(height: 20),

              // Corpo: Se 2 persone -> Cross-fader; Se > 2 persone -> Multi-channel Mixer
              if (_isTwoPeopleMode) ...[
                _buildTwoPeopleView(),
              ] else ...[
                _buildMultiPeopleView(),
              ],

              const SizedBox(height: 24),

              // Pulsante di conferma
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _confirmSplit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Applica Divisione',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // WIDGET: HEADER
  // -------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge gruppo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group_rounded, size: 14, color: Color(0xFF818CF8)),
                    const SizedBox(width: 6),
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Payer badge
              const Row(
                children: [
                  Icon(Icons.payment_rounded, size: 14, color: AppTheme.success),
                  SizedBox(width: 4),
                  Text('Pagata da te', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction.cleanDescription,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.transaction.category.label,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '€ ${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // WIDGET: VISTA 2 PERSONE (Cross-fader con step 0.50€)
  // -------------------------------------------------------------
  Widget _buildTwoPeopleView() {
    final activePct = _totalAmount > 0 ? (_activeUserAmount / _totalAmount) : 0.5;
    final otherPct = (1.0 - activePct).clamp(0.0, 1.0);

    return Column(
      children: [
        // Schede ai due estremi
        Row(
          children: [
            // Scheda Utente Attivo (Sinistra)
            Expanded(
              child: _buildTwoPeopleMemberCard(
                title: 'Tu (Pagatore)',
                name: _activeUser.displayName,
                amount: _activeUserAmount,
                percent: (activePct * 100).round(),
                color: const Color(0xFF6366F1),
                isLeft: true,
              ),
            ),
            const SizedBox(width: 12),
            // Scheda Altra Persona (Destra)
            Expanded(
              child: _buildTwoPeopleMemberCard(
                title: 'Altra persona',
                name: _otherMember!.displayName,
                amount: _otherMemberAmount,
                percent: (otherPct * 100).round(),
                color: const Color(0xFFEC4899),
                isLeft: false,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Slider Volume (Cross-Fader)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 16, color: Color(0xFF6366F1)),
                      SizedBox(width: 6),
                      Text('Volume Split (scatti 0,50 €)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text(
                    'Pari: ${(activePct * 100).toStringAsFixed(0)}% / ${(otherPct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  activeTrackColor: const Color(0xFF6366F1),
                  inactiveTrackColor: const Color(0xFFEC4899).withOpacity(0.5),
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFF6366F1).withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: _activeUserAmount.clamp(0.0, _totalAmount),
                  min: 0.0,
                  max: _totalAmount > 0 ? _totalAmount : 1.0,
                  onChanged: _onTwoPeopleSliderChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0.00 € (Tutto ${_otherMember!.displayName})', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    Text('€ ${_totalAmount.toStringAsFixed(2)} (Tutto Tu)', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick Preset Buttons
        Row(
          children: [
            _buildPresetPill('⚖️ 50/50 Equo', _setExactFiftyFifty),
            const SizedBox(width: 8),
            _buildPresetPill('👤 Solo Tu', _setFullActiveUser),
            const SizedBox(width: 8),
            _buildPresetPill('🎁 Tutto l\'altro', _setFullOtherUser),
          ],
        ),
      ],
    );
  }

  Widget _buildTwoPeopleMemberCard({
    required String title,
    required String name,
    required double amount,
    required int percent,
    required Color color,
    required bool isLeft,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isLeft) CircleAvatar(radius: 10, backgroundColor: color, child: const Icon(Icons.person, size: 12, color: Colors.white)),
              if (isLeft) const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              if (!isLeft) const SizedBox(width: 6),
              if (!isLeft) CircleAvatar(radius: 10, backgroundColor: color, child: const Icon(Icons.person, size: 12, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '€ ${amount.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            '$percent%',
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // WIDGET: VISTA > 2 PERSONE (Multi-channel Mixer)
  // -------------------------------------------------------------
  Widget _buildMultiPeopleView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra di bilanciamento stato
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isMultiBalanced ? AppTheme.success.withOpacity(0.12) : AppTheme.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _isMultiBalanced ? AppTheme.success.withOpacity(0.3) : AppTheme.warning.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(
                _isMultiBalanced ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: _isMultiBalanced ? AppTheme.success : AppTheme.warning,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isMultiBalanced
                      ? 'Bilanciato al centesimo (€ ${_multiCurrentTotal.toStringAsFixed(2)})'
                      : 'Totale: € ${_multiCurrentTotal.toStringAsFixed(2)} / € ${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _isMultiBalanced ? AppTheme.success : AppTheme.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_isMultiBalanced)
                GestureDetector(
                  onTap: _autoBalanceMulti,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warning,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Pareggia', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Preset rapidi
        Row(
          children: [
            _buildPresetPill('⚖️ Equo tutti', () {
              setState(() {
                _excludedUserIds.clear();
                _lockedUserIds.clear();
                _setEqualSplitMulti();
              });
            }),
            const SizedBox(width: 8),
            _buildPresetPill('👤 Solo io', () {
              setState(() {
                _lockedUserIds.clear();
                for (final m in _effectiveMembers) {
                  if (m.userId == _activeUser.userId) {
                    _channelAmounts[m.userId] = _totalAmount;
                    _excludedUserIds.remove(m.userId);
                  } else {
                    _channelAmounts[m.userId] = 0.0;
                    _excludedUserIds.add(m.userId);
                  }
                }
              });
            }),
          ],
        ),

        const SizedBox(height: 16),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'CANALI PARTECIPANTI (VOLUME FADER)',
            style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.white38),
          ),
        ),
        const SizedBox(height: 10),

        // Lista dei fader individuali
        ..._effectiveMembers.map((member) {
          final isExcluded = _excludedUserIds.contains(member.userId);
          final isLocked = _lockedUserIds.contains(member.userId);
          final isCurrent = member.userId == _activeUser.userId;
          final amount = _channelAmounts[member.userId] ?? 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isExcluded ? Colors.white.withOpacity(0.02) : const Color(0xFF1E1E22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent ? const Color(0xFF6366F1).withOpacity(0.4) : (isExcluded ? Colors.white10 : Colors.white12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Mute / Exclude button
                    IconButton(
                      icon: Icon(
                        isExcluded ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: isExcluded ? Colors.white24 : (isCurrent ? const Color(0xFF818CF8) : Colors.white70),
                        size: 20,
                      ),
                      onPressed: () => _toggleExcludeUser(member.userId),
                      tooltip: isExcluded ? 'Includi' : 'Escludi',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 8),

                    // Nome e Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.displayName,
                            style: TextStyle(
                              color: isExcluded ? Colors.white38 : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: isExcluded ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (isCurrent)
                            const Text('Tu (Pagatore)', style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    // Lock button 🔒
                    IconButton(
                      icon: Icon(
                        isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                        color: isLocked ? AppTheme.warning : Colors.white24,
                        size: 18,
                      ),
                      onPressed: isExcluded ? null : () => _toggleLockUser(member.userId),
                      tooltip: isLocked ? 'Sblocca' : 'Blocca quota',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),

                    const SizedBox(width: 8),

                    // Badge importo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isExcluded ? Colors.transparent : const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '€ ${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isExcluded ? Colors.white24 : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                if (!isExcluded) ...[
                  const SizedBox(height: 6),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: isCurrent ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: amount.clamp(0.0, _totalAmount),
                      min: 0.0,
                      max: _totalAmount > 0 ? _totalAmount : 1.0,
                      onChanged: isLocked ? null : (val) => _onMultiSliderChanged(member.userId, val),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPresetPill(String title, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
