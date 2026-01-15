import 'package:flutter/material.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/expense_split_state.dart';
import 'package:solducci/widgets/expense_split/user_selection_chip.dart';
import 'package:solducci/widgets/expense_split/user_split_chip.dart';
import 'package:solducci/widgets/expense_split/equally_split_toggle.dart';
import 'package:solducci/widgets/expense_split/percentage_toggle.dart';

/// Card espandibile per rappresentare un gruppo nella divisione spesa
///
/// Stato NON selezionato:
/// - Mostra nome gruppo
/// - Leading: Avatar/icona gruppo
/// - Trailing: Badge con icona "user" + numero utenti
/// - Altezza compatta: 64px
///
/// Stato SELEZIONATO:
/// - Border colorato, background leggermente colorato
/// - Espande verso il basso con animazione (300ms)
/// - Mostra sezione "Chi paga" e "Diviso tra"
class GroupSplitCard extends StatefulWidget {
  final ExpenseGroup group;
  final ExpenseSplitState splitState;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool allowCollapse;
  final bool showExpandIcon;

  const GroupSplitCard({
    super.key,
    required this.group,
    required this.splitState,
    required this.isSelected,
    this.onSelectionChanged,
    this.allowCollapse = true,
    this.showExpandIcon = true,
  });

  @override
  State<GroupSplitCard> createState() => _GroupSplitCardState();
}

class _GroupSplitCardState extends State<GroupSplitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    if (widget.isSelected) {
      _expandController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(GroupSplitCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleSelection() {
    if (widget.allowCollapse) {
      widget.onSelectionChanged?.call(!widget.isSelected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.splitState,
      builder: (context, _) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: widget.isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: widget.isSelected
                  ? Colors.blue.shade400
                  : Colors.grey.shade300,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (sempre visibile)
              InkWell(
                onTap: _toggleSelection,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Colors.blue.shade50
                        : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Group avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: widget.isSelected
                            ? Colors.blue.shade200
                            : Colors.grey.shade300,
                        child: Icon(
                          Icons.group,
                          color: widget.isSelected
                              ? Colors.blue.shade900
                              : Colors.grey.shade700,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Group name
                      Expanded(
                        child: Text(
                          widget.group.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.isSelected
                                ? Colors.blue.shade900
                                : Colors.grey.shade800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Member count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: widget.isSelected
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.splitState.members.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.isSelected
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Expand icon (only if collapsible AND showExpandIcon is true)
                      if (widget.allowCollapse && widget.showExpandIcon) ...[
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: widget.isSelected ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: widget.isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Expanded content (animato)
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Chi paga" section
                      Row(
                        children: [
                          Text(
                            'Pagato da ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const Text('💰', style: TextStyle(fontSize: 13)),
                          const Text(
                            ':',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Payer selection chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.splitState.members.map((member) {
                          return UserSelectionChip(
                            member: member,
                            isSelected:
                                widget.splitState.selectedPayer ==
                                member.userId,
                            onTap: () {
                              widget.splitState.selectPayer(member.userId);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Divider(color: Colors.grey.shade300, thickness: 1),

                      const SizedBox(height: 16),

                      // "Diviso tra" section with toggles
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PercentageToggle(
                            isPercentage: widget.splitState.isPercentageView,
                            onToggle: () {
                              widget.splitState.togglePercentageView();
                            },
                          ),
                          const SizedBox(width: 4),
                          EquallySplitToggle(
                            isEqual: widget.splitState.isEqualSplit,
                            onToggle: () {
                              widget.splitState.toggleEqualSplit();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // User split chips - Wrap layout (flow)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.splitState.members.map((member) {
                          return UserSplitChip(
                            member: member,
                            isSelected: widget.splitState.isSplitterSelected(
                              member.userId,
                            ),
                            amount: widget.splitState.getSplitAmount(
                              member.userId,
                            ),
                            totalAmount: widget.splitState.totalAmount,
                            currentSplitsTotal: widget.splitState.currentTotal,
                            onSelectionChanged: (selected) {
                              widget.splitState.toggleSplitter(member.userId);
                            },
                            onAmountChanged: (amount) {
                              widget.splitState.updateSplitAmount(
                                member.userId,
                                amount,
                              );
                            },
                            onAssignRemaining: () {
                              widget.splitState.assignRemainingTo(
                                member.userId,
                              );
                            },
                            showAddRemaining: !widget.splitState.isEqualSplit,
                            isPercentageView: widget.splitState.isPercentageView,
                          );
                        }).toList(),
                      ),

                      // Summary (if not equal or invalid)
                      if (!widget.splitState.isEqualSplit ||
                          !widget.splitState.isValid) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.splitState.isValid
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.splitState.isValid
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    widget.splitState.isValid
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color: widget.splitState.isValid
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Totale:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: widget.splitState.isValid
                                          ? Colors.green.shade900
                                          : Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${widget.splitState.currentTotal.toStringAsFixed(2)} / ${widget.splitState.totalAmount.toStringAsFixed(2)} €',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: widget.splitState.isValid
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Warning message
                        if (!widget.splitState.isValid) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.splitState.currentTotal >
                                    widget.splitState.totalAmount
                                ? '⚠️ Importo totale supera ${widget.splitState.totalAmount.toStringAsFixed(2)}€'
                                : widget.splitState.selectedSplitters.isEmpty
                                ? '⚠️ Seleziona almeno un utente'
                                : '⚠️ Mancano ${widget.splitState.remaining.toStringAsFixed(2)}€',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
