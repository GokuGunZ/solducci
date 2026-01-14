import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/group.dart';

/// Chip con importo editabile per divisione spesa
///
/// Design inline: chip base + sezione importo side-by-side
/// Completamente dinamico, si adatta al contenuto
class UserSplitChip extends StatefulWidget {
  final GroupMember member;
  final bool isSelected;
  final double amount;
  final double totalAmount;
  final double currentSplitsTotal;
  final ValueChanged<bool> onSelectionChanged;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback? onAssignRemaining;
  final bool showAddRemaining;

  const UserSplitChip({
    super.key,
    required this.member,
    required this.isSelected,
    required this.amount,
    required this.totalAmount,
    required this.currentSplitsTotal,
    required this.onSelectionChanged,
    required this.onAmountChanged,
    this.onAssignRemaining,
    this.showAddRemaining = false,
  });

  @override
  State<UserSplitChip> createState() => _UserSplitChipState();
}

class _UserSplitChipState extends State<UserSplitChip> {
  late TextEditingController _amountController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.amount > 0 ? widget.amount.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(UserSplitChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount != oldWidget.amount && !_focusNode.hasFocus) {
      _amountController.text = widget.amount > 0
          ? widget.amount.toStringAsFixed(2)
          : '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isOverflow {
    return widget.currentSplitsTotal > widget.totalAmount + 0.01;
  }

  double get _overflow {
    return widget.currentSplitsTotal - widget.totalAmount;
  }

  bool get _shouldShowAddButton {
    return widget.isSelected &&
        widget.showAddRemaining &&
        (widget.totalAmount - widget.currentSplitsTotal) > 0.01;
  }

  void _handleAmountChange(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    widget.onAmountChanged(amount);
  }

  void _toggleSelection() {
    widget.onSelectionChanged(!widget.isSelected);
  }

  void _handleReduceAmount() {
    final reductionNeeded = _overflow;
    final newAmount = (widget.amount - reductionNeeded).clamp(0.0, widget.amount);
    widget.onAmountChanged(double.parse(newAmount.toStringAsFixed(2)));
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isSelected
        ? Colors.blue.shade50
        : Colors.grey.shade100;

    final borderColor = widget.isSelected
        ? Colors.blue.shade300
        : Colors.grey.shade300;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Base chip
        GestureDetector(
          onTap: _toggleSelection,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 2 : 1,
              ),
              borderRadius: widget.isSelected
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    )
                  : BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: widget.isSelected
                      ? Colors.blue.shade200
                      : Colors.grey.shade300,
                  child: Text(
                    widget.member.initials,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.isSelected
                          ? Colors.blue.shade900
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.member.nickname ?? widget.member.email ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? Colors.blue.shade900
                        : Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Money section (animated)
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.centerLeft,
            widthFactor: widget.isSelected ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: 2),
                  right: BorderSide(color: borderColor, width: 2),
                  bottom: BorderSide(color: borderColor, width: 2),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Divider
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.only(right: 6),
                  ),

                  // Amount field (intrinsic width)
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        suffix: Text(
                          '€',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        hintText: '0.00',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: _handleAmountChange,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Buttons
                  if (_isOverflow && widget.amount > 0.01)
                    GestureDetector(
                      onTap: _handleReduceAmount,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    )
                  else if (_shouldShowAddButton)
                    GestureDetector(
                      onTap: widget.onAssignRemaining,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
