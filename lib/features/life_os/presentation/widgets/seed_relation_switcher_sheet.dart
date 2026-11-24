import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/theme/app_theme.dart';

/// Result of the SeedRelationSwitcherSheet action.
class SeedRelationSwitcherResult {
  final bool remove;
  final SeedMention? updatedMention;

  const SeedRelationSwitcherResult.update(this.updatedMention) : remove = false;
  const SeedRelationSwitcherResult.remove() : remove = true, updatedMention = null;
}

/// Modal bottom sheet / popover to view and toggle the relation type
/// of a tagged entity between "Figlio di" (partOf) and "Semplice" (relatesTo).
class SeedRelationSwitcherSheet extends StatefulWidget {
  final SeedMention mention;

  const SeedRelationSwitcherSheet({
    super.key,
    required this.mention,
  });

  static Future<SeedRelationSwitcherResult?> show(
    BuildContext context, {
    required SeedMention mention,
  }) {
    return showModalBottomSheet<SeedRelationSwitcherResult?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SeedRelationSwitcherSheet(mention: mention),
    );
  }

  @override
  State<SeedRelationSwitcherSheet> createState() => _SeedRelationSwitcherSheetState();
}

class _SeedRelationSwitcherSheetState extends State<SeedRelationSwitcherSheet> {
  late RelationType _currentType;

  @override
  void initState() {
    super.initState();
    _currentType = widget.mention.relationType;
  }

  @override
  Widget build(BuildContext context) {
    final isChild = _currentType == RelationType.partOf;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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
          const SizedBox(height: 18),

          // Header with Entity Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isChild
                      ? const Color(0xFF8B5CF6).withOpacity(0.2)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isChild ? Icons.subdirectory_arrow_right_rounded : Icons.link_rounded,
                  color: isChild ? const Color(0xFF8B5CF6) : Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${widget.mention.entityTitle}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Entità LifeOS (${widget.mention.role.value})',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                onPressed: () => Navigator.of(context).pop(SeedRelationSwitcherResult.update(widget.mention.copyWith(relationType: _currentType))),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Informative label
          Text(
            'Tipo di collegamento con questo seme:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Interactive Segmented Selector Card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF141418),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                // Option 1: Figlio di (partOf)
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentType = RelationType.partOf);
                  },
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isChild ? const Color(0xFF8B5CF6).withOpacity(0.12) : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          color: isChild ? const Color(0xFF8B5CF6) : Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Figlio di (parte di)',
                                style: TextStyle(
                                  color: isChild ? Colors.white : Colors.white70,
                                  fontSize: 13.5,
                                  fontWeight: isChild ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Questo seme appartiene o è subordinato a questa entità',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<RelationType>(
                          value: RelationType.partOf,
                          groupValue: _currentType,
                          activeColor: const Color(0xFF8B5CF6),
                          onChanged: (val) {
                            if (val != null) setState(() => _currentType = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.06)),

                // Option 2: Semplice (relatesTo)
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentType = RelationType.relatesTo);
                  },
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: !isChild ? Colors.white.withOpacity(0.06) : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          color: !isChild ? AppTheme.primary : Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connessione Semplice',
                                style: TextStyle(
                                  color: !isChild ? Colors.white : Colors.white70,
                                  fontSize: 13.5,
                                  fontWeight: !isChild ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Questo seme è semplicemente associato come riferimento',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<RelationType>(
                          value: RelationType.relatesTo,
                          groupValue: _currentType,
                          activeColor: const Color(0xFF8B5CF6),
                          onChanged: (val) {
                            if (val != null) setState(() => _currentType = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions Row (Confirm and Remove Tag)
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(const SeedRelationSwitcherResult.remove());
                },
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 16),
                label: const Text(
                  'Rimuovi tag',
                  style: TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(SeedRelationSwitcherResult.update(widget.mention.copyWith(relationType: _currentType)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Conferma', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
