import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/models/bento_preset.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/gallery/bento_dashboard_blueprint.dart';
import 'package:uuid/uuid.dart';

/// Modal bottom sheet per la scelta, applicazione e salvataggio dei Preset di Bento Dashboard
class BentoPresetSheet extends StatefulWidget {
  final List<BentoWidgetDef> currentLayout;
  final bool isGroupContext;
  final Function(List<BentoWidgetDef> newLayout) onApplyLayout;

  const BentoPresetSheet({
    super.key,
    required this.currentLayout,
    required this.isGroupContext,
    required this.onApplyLayout,
  });

  static Future<void> show({
    required BuildContext context,
    required List<BentoWidgetDef> currentLayout,
    required bool isGroupContext,
    required Function(List<BentoWidgetDef> newLayout) onApplyLayout,
  }) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BentoPresetSheet(
        currentLayout: currentLayout,
        isGroupContext: isGroupContext,
        onApplyLayout: onApplyLayout,
      ),
    );
  }

  @override
  State<BentoPresetSheet> createState() => _BentoPresetSheetState();
}

class _BentoPresetSheetState extends State<BentoPresetSheet> {
  List<BentoPreset> _customPresets = [];
  bool _isLoadingCustom = true;

  @override
  void initState() {
    super.initState();
    _loadCustomPresets();
  }

  Future<void> _loadCustomPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('solducci_custom_bento_presets') ?? [];
      final loaded = rawList.map((str) {
        return BentoPreset.fromMap(jsonDecode(str) as Map<String, dynamic>);
      }).toList();
      if (mounted) {
        setState(() {
          _customPresets = loaded;
          _isLoadingCustom = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCustom = false);
    }
  }

  Future<void> _saveCurrentAsPreset(String name) async {
    if (name.trim().isEmpty) return;
    try {
      final newPreset = BentoPreset(
        id: 'custom_${const Uuid().v4()}',
        title: name.trim(),
        description: 'Template personalizzato salvato da te (${widget.currentLayout.length} widget)',
        icon: Icons.star_rounded,
        accentColor: const Color(0xFFF59E0B),
        category: 'custom',
        layout: List.from(widget.currentLayout),
        isCustom: true,
      );

      final updated = [..._customPresets, newPreset];
      final prefs = await SharedPreferences.getInstance();
      final rawList = updated.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList('solducci_custom_bento_presets', rawList);

      if (mounted) {
        setState(() {
          _customPresets = updated;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preset "$name" salvato con successo!'),
            backgroundColor: const Color(0xFF27272A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Ignora o gestisci
    }
  }

  Future<void> _deleteCustomPreset(String id) async {
    final updated = _customPresets.where((p) => p.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    final rawList = updated.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList('solducci_custom_bento_presets', rawList);
    setState(() => _customPresets = updated);
  }

  void _showSavePresetDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Salva Layout Corrente',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Assegna un nome per poter riapplicare questo setup in qualsiasi momento.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Es. Studio, Viaggio, Weekend',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final name = textController.text;
              Navigator.of(dialogContext).pop();
              _saveCurrentAsPreset(name);
            },
            child: const Text('Salva Preset'),
          ),
        ],
      ),
    );
  }

  void _confirmApplyPreset(BentoPreset preset) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(preset.icon, color: preset.accentColor, size: 22),
            const SizedBox(width: 10),
            Text(
              preset.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Vuoi applicare questo template? Il layout corrente verrà sostituito con i ${preset.layout.length} widget del preset.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: preset.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
              HapticFeedback.mediumImpact();
              widget.onApplyLayout(preset.layout);
            },
            child: const Text('Applica Ora', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPresets = [
      ...BentoPresetCatalog.curatedPresets,
      ..._customPresets,
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF121215), // Deep OLED
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_mosaic_rounded, color: Color(0xFF818CF8), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modelli & Preset',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Template curati e layout salvati per la tua Bento Home',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Action: Salva layout attuale
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showSavePresetDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_add_outlined, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Salva configurazione corrente come Preset',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3), size: 18),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // List of Presets
          Expanded(
            child: _isLoadingCustom
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: allPresets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final preset = allPresets[index];
                      final isRecommended = widget.isGroupContext
                          ? preset.id == 'preset_home'
                          : preset.id == 'preset_finance';

                      return _PresetCard(
                        preset: preset,
                        isRecommended: isRecommended,
                        onApply: () => _confirmApplyPreset(preset),
                        onDelete: preset.isCustom ? () => _deleteCustomPreset(preset.id) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Card rappresentativa di un singolo preset con mini anteprima visuale della griglia
class _PresetCard extends StatelessWidget {
  final BentoPreset preset;
  final bool isRecommended;
  final VoidCallback onApply;
  final VoidCallback? onDelete;

  const _PresetCard({
    required this.preset,
    required this.isRecommended,
    required this.onApply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecommended
              ? preset.accentColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.08),
          width: isRecommended ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: preset.accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(preset.icon, color: preset.accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          preset.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: preset.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Consigliato',
                              style: TextStyle(
                                color: preset.accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${preset.layout.length} Widget • ${preset.isCustom ? 'Personalizzato' : 'Curato'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 18),
                  onPressed: onDelete,
                ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            preset.description,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
          ),

          const SizedBox(height: 14),

          // Anteprima Mosaico dell'intera Dashboard Blueprint
          BentoDashboardBlueprint(
            layout: preset.layout,
            accentColor: preset.accentColor,
            maxHeight: 155.0,
          ),

          const SizedBox(height: 14),

          // Bottom action button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: preset.accentColor.withOpacity(0.15),
                foregroundColor: preset.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text(
                'Applica Template',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onPressed: onApply,
            ),
          ),
        ],
      ),
    );
  }
}
