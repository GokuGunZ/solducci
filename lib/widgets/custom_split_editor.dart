import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/group.dart';

/// Widget for editing custom split amounts per member
class CustomSplitEditor extends StatefulWidget {
  final List<GroupMember> members;
  final double totalAmount;
  final Map<String, double>? initialSplits;
  final ValueChanged<Map<String, double>> onSplitsChanged;

  const CustomSplitEditor({
    super.key,
    required this.members,
    required this.totalAmount,
    this.initialSplits,
    required this.onSplitsChanged,
  });

  @override
  State<CustomSplitEditor> createState() => _CustomSplitEditorState();
}

class _CustomSplitEditorState extends State<CustomSplitEditor> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _splits = {};

  @override
  void initState() {
    super.initState();

    // Initialize controllers and splits
    for (final member in widget.members) {
      final initialAmount = widget.initialSplits?[member.userId] ?? 0.0;
      _controllers[member.userId] = TextEditingController(
        text: initialAmount > 0 ? initialAmount.toStringAsFixed(2) : '',
      );
      _splits[member.userId] = initialAmount;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _currentTotal {
    return _splits.values.fold(0.0, (sum, amount) => sum + amount);
  }

  bool get _isValid {
    return (_currentTotal - widget.totalAmount).abs() < 0.01; // Allow 1 cent tolerance
  }

  Color get _totalColor {
    if (_currentTotal == 0) return Colors.grey.shade600;
    if (_isValid) return Colors.green.shade700;
    return Colors.red.shade700;
  }

  void _updateSplit(String userId, String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      _splits[userId] = amount;
    });
    widget.onSplitsChanged(_splits);
  }

  void _splitEqually() {
    final amountPerPerson = widget.totalAmount / widget.members.length;

    setState(() {
      for (final member in widget.members) {
        final roundedAmount = double.parse(amountPerPerson.toStringAsFixed(2));
        _splits[member.userId] = roundedAmount;
        _controllers[member.userId]!.text = roundedAmount.toStringAsFixed(2);
      }
    });

    widget.onSplitsChanged(_splits);
  }

  void _roundUpToMember(String userId) {
    // Calculate remaining amount
    final remaining = widget.totalAmount - _currentTotal;

    if (remaining <= 0) {
      // Already at or over total, don't add more
      return;
    }

    // Get current amount for this member
    final currentAmount = _splits[userId] ?? 0.0;

    // Add remaining to this member
    final newAmount = currentAmount + remaining;
    final roundedAmount = double.parse(newAmount.toStringAsFixed(2));

    setState(() {
      _splits[userId] = roundedAmount;
      _controllers[userId]!.text = roundedAmount.toStringAsFixed(2);
    });

    widget.onSplitsChanged(_splits);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isValid ? Colors.green.shade300 : Colors.blue.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with equal split button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Importi per membro',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: _splitEqually,
                icon: const Icon(Icons.calculate, size: 16),
                label: const Text('Dividi equamente'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Member split inputs
          ...widget.members.map((member) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Member avatar and name
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue[200],
                    child: Text(
                      member.nickname?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      member.nickname ?? member.email ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Amount input
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _controllers[member.userId],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        suffix: const Text('€'),
                        hintText: '0.00',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onChanged: (value) => _updateSplit(member.userId, value),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  // Round-up button (only show if there's remaining amount)
                  if (_currentTotal < widget.totalAmount && (widget.totalAmount - _currentTotal) > 0.01) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _roundUpToMember(member.userId),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 20,
                      tooltip: 'Assegna resto (${(widget.totalAmount - _currentTotal).toStringAsFixed(2)}€)',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      color: Colors.blue.shade600,
                    ),
                  ],
                ],
              ),
            );
          }),

          const Divider(height: 24),

          // Total summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _totalColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isValid ? Icons.check_circle : Icons.warning,
                      color: _totalColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Totale:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _totalColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_currentTotal.toStringAsFixed(2)} / ${widget.totalAmount.toStringAsFixed(2)} €',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _totalColor,
                  ),
                ),
              ],
            ),
          ),

          if (!_isValid && _currentTotal > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _currentTotal > widget.totalAmount
                    ? '⚠️ Importo totale supera ${widget.totalAmount.toStringAsFixed(2)}€'
                    : '⚠️ Mancano ${(widget.totalAmount - _currentTotal).toStringAsFixed(2)}€',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
