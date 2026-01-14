import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/core/components/chips/expandable_chip.dart';

/// Chip con importo editabile per divisione spesa
///
/// A domain-specific implementation of [ExpandableChip] for expense splitting.
/// Uses the generic expandable chip pattern with expense-specific logic for
/// amount input, validation, and action buttons.
///
/// ## Design
/// - Base chip: Avatar + user name (always visible)
/// - Expanded section: Amount input + action buttons (slides in when selected)
/// - Completely dynamic, adapts to content
///
/// ## Features
/// - Smooth slide-in/out animation
/// - Amount validation and input formatting
/// - Conditional action buttons (add remaining / reduce overflow)
/// - Overflow detection and visual feedback
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
    return ExpandableChip<GroupMember>(
      item: widget.member,
      isSelected: widget.isSelected,
      baseContentBuilder: _buildBaseContent,
      expandedContentBuilder: _buildExpandedContent,
      onSelectionChanged: (_) => _toggleSelection(),
    );
  }

  /// Build the base chip content (avatar + name)
  Widget _buildBaseContent(BuildContext context, GroupMember member) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: widget.isSelected
              ? Colors.blue.shade200
              : Colors.grey.shade300,
          child: Text(
            member.initials,
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
          member.nickname ?? member.email ?? 'Unknown',
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
    );
  }

  /// Build the expanded content (amount input + buttons)
  Widget _buildExpandedContent(BuildContext context, GroupMember member) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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

        // Conditional action buttons
        if (_isOverflow && widget.amount > 0.01)
          _buildReduceButton()
        else if (_shouldShowAddButton)
          _buildAddButton(),
      ],
    );
  }

  /// Build reduce amount button (shown on overflow)
  Widget _buildReduceButton() {
    return GestureDetector(
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
    );
  }

  /// Build add remaining button
  Widget _buildAddButton() {
    return GestureDetector(
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
    );
  }
}
