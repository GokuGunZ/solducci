import 'package:flutter/material.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/split_type.dart';

/// Widget for group-specific expense fields
/// Shows "Chi ha pagato?" and split type selectors
class GroupExpenseFields extends StatefulWidget {
  final List<GroupMember> members;
  final String? initialPaidBy;
  final SplitType? initialSplitType;
  final ValueChanged<String?> onPaidByChanged;
  final ValueChanged<SplitType?> onSplitTypeChanged;

  const GroupExpenseFields({
    super.key,
    required this.members,
    this.initialPaidBy,
    this.initialSplitType,
    required this.onPaidByChanged,
    required this.onSplitTypeChanged,
  });

  @override
  State<GroupExpenseFields> createState() => _GroupExpenseFieldsState();
}

class _GroupExpenseFieldsState extends State<GroupExpenseFields> {
  String? _selectedPaidBy;
  SplitType? _selectedSplitType;

  @override
  void initState() {
    super.initState();
    _selectedPaidBy = widget.initialPaidBy;
    _selectedSplitType = widget.initialSplitType ?? SplitType.equal;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Divider with title
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey[400],
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'SPLIT TRA MEMBRI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey[400],
                thickness: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // "Chi ha pagato?" dropdown
        Text(
          'Chi ha pagato? *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPaidBy,
          decoration: InputDecoration(
            hintText: 'Seleziona chi ha pagato',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: widget.members.map((member) {
            return DropdownMenuItem<String>(
              value: member.userId,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue[200],
                    child: Text(
                      member.initials ?? '?',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      member.nickname ?? member.email ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (member.role == GroupRole.admin) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPaidBy = value;
            });
            widget.onPaidByChanged(value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Seleziona chi ha pagato';
            }
            return null;
          },
        ),

        const SizedBox(height: 24),

        // "Come dividere?" split type selector
        Text(
          'Come dividere?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        // Split type radio buttons
        ...SplitType.values.map((type) {
          return RadioListTile<SplitType>(
            value: type,
            groupValue: _selectedSplitType,
            onChanged: (value) {
              setState(() {
                _selectedSplitType = value;
              });
              widget.onSplitTypeChanged(value);
            },
            title: Row(
              children: [
                Text(
                  type.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        type.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            dense: true,
          );
        }),

        const SizedBox(height: 8),
      ],
    );
  }
}
