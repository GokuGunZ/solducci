import 'package:flutter/material.dart';
import '../models/line_element.dart';

/// Modal dialog offering vertical split-screen configuration:
/// Left: Marker morphology & default behavior
/// Right: Visual styling modifiers & live preview
/// Bottom: Domain entity data-source binding
class LineModifierDialog extends StatefulWidget {
  final LineElement element;
  final LineMarkerRule currentRule;
  final ValueChanged<LineMarkerRule> onSaveRule;

  const LineModifierDialog({
    super.key,
    required this.element,
    required this.currentRule,
    required this.onSaveRule,
  });

  /// Displays the modal responsively: BottomSheet on narrow mobile (<600dp)
  /// and Dialog on wider screens.
  static Future<LineMarkerRule?> show(
    BuildContext context, {
    required LineElement element,
    required LineMarkerRule currentRule,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return showModalBottomSheet<LineMarkerRule>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => LineModifierDialog(
          element: element,
          currentRule: currentRule,
          onSaveRule: (updated) => Navigator.of(ctx).pop(updated),
        ),
      );
    } else {
      return showDialog<LineMarkerRule>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
            child: LineModifierDialog(
              element: element,
              currentRule: currentRule,
              onSaveRule: (updated) => Navigator.of(ctx).pop(updated),
            ),
          ),
        ),
      );
    }
  }

  @override
  State<LineModifierDialog> createState() => _LineModifierDialogState();
}

class _LineModifierDialogState extends State<LineModifierDialog> {
  late LineMarkerType _selectedMarkerType;
  late String? _selectedIconName;
  late bool _strikethrough;
  late bool _underline;
  late bool _bold;
  late Color? _selectedColor;
  late double _opacity;
  late ModifierCondition _condition;

  // Data Source Binding State
  late bool _isDataBound;
  late String _targetEntity;
  late String _contextScope;

  final List<Color> _palette = const [
    Color(0xFF10B981), // Emerald
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Rose
    Color(0xFFA855F7), // Purple
  ];

  @override
  void initState() {
    super.initState();
    final rule = widget.currentRule;
    _selectedMarkerType = rule.markerType;
    _selectedIconName = rule.customIconName;
    _strikethrough = rule.modifier.strikethrough;
    _underline = rule.modifier.underline;
    _bold = rule.modifier.bold;
    _selectedColor = rule.modifier.textColor;
    _opacity = rule.modifier.opacity;
    _condition = rule.modifier.applyCondition;

    _isDataBound = rule.dataSource.isConnected;
    _targetEntity = rule.dataSource.targetEntityType;
    _contextScope = rule.dataSource.contextScope;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personalizza Elemento di Riga',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Split Vertical Section: Left (Morphology) & Right (Styling)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Morphology & Defaults
                      Expanded(
                        child: _buildLeftMorphologyPanel(theme, isDark),
                      ),
                      const SizedBox(width: 16),
                      // Right Column: Line Modifier Styling & Live Preview
                      Expanded(
                        child: _buildRightStylingPanel(theme, isDark),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Bottom Section: Domain Data Source Connection
                  _buildBottomDataSourcePanel(theme, isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveAndApply,
                child: const Text('Applica alla Pagina'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftMorphologyPanel(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Morfologia Icona',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildMorphologyOption(
            type: LineMarkerType.checkbox,
            title: 'Casella Checkbox [ ]',
            subtitle: 'Completamento booleano',
            icon: Icons.check_circle_outline,
          ),
          _buildMorphologyOption(
            type: LineMarkerType.bullet,
            title: 'Punto Elenco -',
            subtitle: 'Lista standard',
            icon: Icons.circle,
          ),
          _buildMorphologyOption(
            type: LineMarkerType.numbered,
            title: 'Numerato 1.',
            subtitle: 'Sequenza ordinata',
            icon: Icons.format_list_numbered,
          ),
          _buildMorphologyOption(
            type: LineMarkerType.quote,
            title: 'Citazione >',
            subtitle: 'Blocco evidenziato',
            icon: Icons.format_quote,
          ),
        ],
      ),
    );
  }

  Widget _buildMorphologyOption({
    required LineMarkerType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMarkerType == type;
    return InkWell(
      onTap: () => setState(() => _selectedMarkerType = type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? const Color(0xFF6366F1) : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightStylingPanel(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. Modificatore di Riga',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Live Preview Card
          _buildLivePreviewCard(isDark),
          const SizedBox(height: 12),

          // Styling Toggles
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Testo Barrato (Strikethrough)', style: TextStyle(fontSize: 12)),
            value: _strikethrough,
            onChanged: (v) => setState(() => _strikethrough = v ?? false),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Sottolineato (Underline)', style: TextStyle(fontSize: 12)),
            value: _underline,
            onChanged: (v) => setState(() => _underline = v ?? false),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Grassetto (Bold Weight)', style: TextStyle(fontSize: 12)),
            value: _bold,
            onChanged: (v) => setState(() => _bold = v ?? false),
          ),

          // Color Palette Picker
          const SizedBox(height: 6),
          const Text('Colore Testo:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              ..._palette.map((c) => GestureDetector(
                onTap: () => setState(() => _selectedColor = (_selectedColor == c) ? null : c),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == c ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              )),
              if (_selectedColor != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() => _selectedColor = null),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(bool isDark) {
    final previewDecorations = <TextDecoration>[];
    if (_strikethrough) previewDecorations.add(TextDecoration.lineThrough);
    if (_underline) previewDecorations.add(TextDecoration.underline);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Anteprima stile applicato',
              style: TextStyle(
                fontSize: 12,
                fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
                decoration: previewDecorations.isNotEmpty ? TextDecoration.combine(previewDecorations) : null,
                color: _selectedColor ?? (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDataSourcePanel(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sync_alt, size: 18, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    '3. Connessione Fonte Dati Solducci',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Switch(
                value: _isDataBound,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setState(() => _isDataBound = val),
              ),
            ],
          ),
          if (_isDataBound) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _targetEntity,
                    decoration: const InputDecoration(
                      labelText: 'Entità Target',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'task', child: Text('Task / ToDo Personale', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'shopping_list', child: Text('Lista della Spesa', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'dispensa', child: Text('Inventario Dispensa', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (v) => setState(() => _targetEntity = v ?? 'task'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _contextScope,
                    decoration: const InputDecoration(
                      labelText: 'Ambito Contesto',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'personal', child: Text('Personale (Private)', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'group', child: Text('Gruppo Attivo (Shared)', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (v) => setState(() => _contextScope = v ?? 'personal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Ogni elemento con questo simbolo corrisponderà a un record sincronizzato nell\'entità selezionata.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  void _saveAndApply() {
    final updatedRule = LineMarkerRule(
      markerType: _selectedMarkerType,
      customIconName: _selectedIconName,
      modifier: LineModifierStyle(
        strikethrough: _strikethrough,
        underline: _underline,
        bold: _bold,
        textColor: _selectedColor,
        opacity: _opacity,
        applyCondition: _condition,
      ),
      dataSource: DataSourceBindingConfig(
        isConnected: _isDataBound,
        targetEntityType: _targetEntity,
        contextScope: _contextScope,
      ),
    );

    widget.onSaveRule(updatedRule);
  }
}
