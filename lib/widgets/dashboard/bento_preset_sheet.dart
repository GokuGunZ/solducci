import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/models/bento_preset.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/gallery/bento_dashboard_blueprint.dart';
import 'package:uuid/uuid.dart';

/// Modal bottom sheet con Showcase Carousel orizzontale per i Preset di Bento Dashboard.
/// Offre grandi anteprime visive ad alta fedeltà (60/120fps) stile Apple Watch/Linear.
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
  String _selectedCategory = 'all';
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
    _loadCustomPresets();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          _selectedCategory = 'custom';
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
    setState(() {
      _customPresets = updated;
      if (_currentPage >= updated.length && _currentPage > 0) {
        _currentPage = updated.length - 1;
      }
    });
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
            Expanded(
              child: Text(
                preset.title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
            child: Text(
              'Applica Ora',
              style: TextStyle(
                color: preset.accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BentoPreset> _getFilteredPresets() {
    final all = [
      ...BentoPresetCatalog.curatedPresets,
      ..._customPresets,
    ];

    if (_selectedCategory == 'all') {
      return all;
    } else if (_selectedCategory == 'custom') {
      return _customPresets;
    } else {
      return all.where((p) => p.category == _selectedCategory).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPresets = _getFilteredPresets();

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        'Scorri e scopri i layout pronti all\'uso',
                        style: TextStyle(color: Colors.white54, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                // Pulsante Salva Setup Corrente
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.06),
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 16, color: Colors.orangeAccent),
                  label: const Text('Salva', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _showSavePresetDialog,
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Category Filter Chips
          _buildCategoryChips(),

          const SizedBox(height: 8),

          // Main Showcase Carousel
          Expanded(
            child: _isLoadingCustom
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : filteredPresets.isEmpty
                    ? _buildEmptyCategoryState()
                    : Column(
                        children: [
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredPresets.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                                HapticFeedback.selectionClick();
                              },
                              itemBuilder: (context, index) {
                                final preset = filteredPresets[index];
                                final isRecommended = widget.isGroupContext
                                    ? preset.id == 'preset_home'
                                    : preset.id == 'preset_finance';

                                return _ShowcasePresetCard(
                                  preset: preset,
                                  isRecommended: isRecommended,
                                  onApply: () => _confirmApplyPreset(preset),
                                  onDelete: preset.isCustom ? () => _deleteCustomPreset(preset.id) : null,
                                );
                              },
                            ),
                          ),

                          // Indicator Dots & Counter
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: _buildPageIndicator(filteredPresets.length),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      {'id': 'all', 'label': 'Tutti'},
      {'id': 'finance', 'label': 'Finanze'},
      {'id': 'home', 'label': 'Casa'},
      {'id': 'minimal', 'label': 'Focus'},
      {'id': 'productivity', 'label': 'Note'},
      {'id': 'custom', 'label': 'I Miei (${_customPresets.length})'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                cat['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF6366F1).withOpacity(0.25),
              backgroundColor: Colors.white.withOpacity(0.04),
              side: BorderSide(
                color: isSelected ? const Color(0xFF6366F1).withOpacity(0.6) : Colors.white.withOpacity(0.08),
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (_) {
                if (_selectedCategory != cat['id']) {
                  setState(() {
                    _selectedCategory = cat['id'] as String;
                    _currentPage = 0;
                  });
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
                  HapticFeedback.selectionClick();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPageIndicator(int count) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.white24,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyCategoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 12),
            const Text(
              'Nessun template personalizzato',
              style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tocca "Salva" in alto per memorizzare la configurazione attuale della tua Bento Home.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card principale dello Showcase Carousel con la vera anteprima visiva ingrandita
class _ShowcasePresetCard extends StatelessWidget {
  final BentoPreset preset;
  final bool isRecommended;
  final VoidCallback onApply;
  final VoidCallback? onDelete;

  const _ShowcasePresetCard({
    required this.preset,
    required this.isRecommended,
    required this.onApply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final luminance = preset.accentColor.computeLuminance();
    final buttonTextColor = luminance > 0.5 ? Colors.black : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF16161A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRecommended
              ? preset.accentColor.withOpacity(0.55)
              : Colors.white.withOpacity(0.08),
          width: isRecommended ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient corner glow
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: preset.accentColor.withOpacity(0.12),
                ),
              ),
            ),

            // Contenuto della card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: Icon + Titolo + Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: preset.accentColor.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: preset.accentColor.withOpacity(0.35)),
                        ),
                        child: Icon(preset.icon, color: preset.accentColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    preset.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isRecommended) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: preset.accentColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: preset.accentColor.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      'Consigliato',
                                      style: TextStyle(
                                        color: preset.accentColor,
                                        fontSize: 9.5,
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
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11.5),
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

                  const SizedBox(height: 8),

                  // Descrizione sintetica
                  Text(
                    preset.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Grande Anteprima Grafica Reale del Mosaico
                  Expanded(
                    child: BentoDashboardBlueprint(
                      layout: preset.layout,
                      accentColor: preset.accentColor,
                      maxHeight: 330.0,
                      allowScroll: true,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bottone di applicazione CTA
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: preset.accentColor,
                      foregroundColor: buttonTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: preset.accentColor.withOpacity(0.4),
                    ),
                    icon: Icon(Icons.check_circle_rounded, size: 19, color: buttonTextColor),
                    label: Text(
                      'Applica questo Template',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: buttonTextColor),
                    ),
                    onPressed: onApply,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
