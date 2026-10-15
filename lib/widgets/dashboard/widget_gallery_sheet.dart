import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/dashboard_widget_factory.dart';
import 'package:solducci/widgets/dashboard/gallery/bento_widget_preview_factory.dart';
import 'package:uuid/uuid.dart';

enum WidgetCategory {
  all('Tutti', Icons.grid_view_rounded, Color(0xFF6366F1)),
  finance('Finanze', Icons.account_balance_wallet_rounded, Color(0xFF10B981)),
  time('Tempo & Focus', Icons.timer_rounded, Color(0xFF6366F1)),
  notes('Note & Idee', Icons.sticky_note_2_rounded, Color(0xFFF59E0B)),
  home('Casa & Spazio', Icons.all_inbox_rounded, Color(0xFF3B82F6));

  final String label;
  final IconData icon;
  final Color color;
  const WidgetCategory(this.label, this.icon, this.color);
}

class WidgetMetadata {
  final String type;
  final String name;
  final String description;
  final WidgetCategory category;
  final IconData icon;
  final Color color;
  final BentoWidgetSize defaultSize;
  final List<BentoWidgetSize> allowedSizes;
  final List<String> keywords;

  const WidgetMetadata({
    required this.type,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.defaultSize,
    required this.allowedSizes,
    this.keywords = const [],
  });
}

class WidgetCatalog {
  static List<WidgetMetadata> get all => _WidgetGallerySheetState._catalog;
  static WidgetMetadata? findByType(String type) {
    try {
      return _WidgetGallerySheetState._catalog.firstWhere((w) => w.type == type);
    } catch (_) {
      return null;
    }
  }
}

class WidgetGallerySheet extends StatefulWidget {
  final List<BentoWidgetDef> currentLayout;
  final Function(BentoWidgetDef def) onAddWidget;
  final Future<Map<String, dynamic>?> Function(BuildContext context, String type) onConfigureWidget;

  const WidgetGallerySheet({
    super.key,
    required this.currentLayout,
    required this.onAddWidget,
    required this.onConfigureWidget,
  });

  static Future<void> show({
    required BuildContext context,
    required List<BentoWidgetDef> currentLayout,
    required Function(BentoWidgetDef def) onAddWidget,
    required Future<Map<String, dynamic>?> Function(BuildContext context, String type) onConfigureWidget,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF09090B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => WidgetGallerySheet(
        currentLayout: currentLayout,
        onAddWidget: onAddWidget,
        onConfigureWidget: onConfigureWidget,
      ),
    );
  }

  @override
  State<WidgetGallerySheet> createState() => _WidgetGallerySheetState();
}

class _WidgetGallerySheetState extends State<WidgetGallerySheet> {
  WidgetCategory _selectedCategory = WidgetCategory.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, BentoWidgetSize> _selectedSizes = {};

  static final List<WidgetMetadata> _catalog = [
    // Finanze
    const WidgetMetadata(
      type: 'balance',
      name: 'Bilancio & Saldo',
      description: 'Panoramica liquida dei portafogli o saldo di gruppo con navigazione a swipe.',
      category: WidgetCategory.finance,
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF10B981),
      defaultSize: BentoWidgetSize(2, 1),
      allowedSizes: [BentoWidgetSize(2, 1), BentoWidgetSize(1, 1), BentoWidgetSize(1, 2)],
      keywords: ['saldo', 'conto', 'banca', 'portafoglio', 'denaro', 'soldi'],
    ),
    const WidgetMetadata(
      type: 'quick_expense',
      name: 'Spesa Rapida',
      description: 'Tastierino istantaneo per registrare uscite al volo con selezione rapida di categorie.',
      category: WidgetCategory.finance,
      icon: Icons.bolt_rounded,
      color: Color(0xFFEF4444),
      defaultSize: BentoWidgetSize(2, 3),
      allowedSizes: [BentoWidgetSize(2, 3), BentoWidgetSize(3, 3)],
      keywords: ['spesa', 'uscita', 'pagamento', 'registra', 'compra'],
    ),
    const WidgetMetadata(
      type: 'monthly_burn_rate',
      name: 'Burn Rate & Budget',
      description: 'Ritmo di spesa giornaliero rispetto al budget mensile con proiezione a fine mese.',
      category: WidgetCategory.finance,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF97316),
      defaultSize: BentoWidgetSize(2, 2),
      allowedSizes: [BentoWidgetSize(2, 2), BentoWidgetSize(4, 2)],
      keywords: ['budget', 'burn rate', 'limite', 'mese', 'proiezione'],
    ),
    const WidgetMetadata(
      type: 'investment_summary',
      name: 'Investimenti & Net Worth',
      description: 'Patrimonio allocato in asset finanziari, fisici e collezionabili con performance.',
      category: WidgetCategory.finance,
      icon: Icons.trending_up_rounded,
      color: Color(0xFF8B5CF6),
      defaultSize: BentoWidgetSize(2, 1),
      allowedSizes: [BentoWidgetSize(2, 1), BentoWidgetSize(2, 2), BentoWidgetSize(4, 2)],
      keywords: ['patrimonio', 'investimenti', 'azioni', 'etf', 'crypto', 'asset'],
    ),
    const WidgetMetadata(
      type: 'peer_debts',
      name: 'Saldo & Debiti di Gruppo',
      description: 'Stato dei debiti reciproci, crediti e rimborsi tra i membri del gruppo.',
      category: WidgetCategory.finance,
      icon: Icons.compare_arrows_rounded,
      color: Color(0xFF8B5CF6),
      defaultSize: BentoWidgetSize(2, 2),
      allowedSizes: [BentoWidgetSize(1, 1), BentoWidgetSize(2, 1), BentoWidgetSize(2, 2), BentoWidgetSize(3, 2)],
      keywords: ['debiti', 'crediti', 'gruppo', 'saldo', 'rimborsi', 'pari'],
    ),
    const WidgetMetadata(
      type: 'category_expenses',
      name: 'Spese per Categoria',
      description: 'Ripartizione delle uscite per categoria con dettaglio e navigazione diretta.',
      category: WidgetCategory.finance,
      icon: Icons.category_rounded,
      color: Color(0xFF10B981),
      defaultSize: BentoWidgetSize(2, 2),
      allowedSizes: [BentoWidgetSize(1, 1), BentoWidgetSize(2, 1), BentoWidgetSize(2, 2), BentoWidgetSize(3, 2)],
      keywords: ['categorie', 'spese', 'breakdown', 'cibo', 'trasporti', 'svago'],
    ),
    const WidgetMetadata(
      type: 'recurring_movements',
      name: 'Spese Ricorrenti',
      description: 'Monitora abbonamenti, affitti, bollette e stipendi con inbox per le conferme.',
      category: WidgetCategory.finance,
      icon: Icons.repeat_rounded,
      color: Color(0xFF8B5CF6),
      defaultSize: BentoWidgetSize(2, 2),
      allowedSizes: [BentoWidgetSize(2, 1), BentoWidgetSize(2, 2), BentoWidgetSize(3, 2)],
      keywords: ['ricorrenti', 'abbonamenti', 'affitto', 'bollette', 'stipendio', 'rate', 'mensile'],
    ),

    // Tempo & Focus
    const WidgetMetadata(
      type: 'daily_progress',
      name: 'Task di Oggi',
      description: 'Progresso delle task completate oggi rispetto a quelle in scadenza.',
      category: WidgetCategory.time,
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF10B981),
      defaultSize: BentoWidgetSize(1, 1),
      allowedSizes: [BentoWidgetSize(1, 1), BentoWidgetSize(2, 1), BentoWidgetSize(1, 2)],
      keywords: ['task', 'focus', 'oggi', 'progresso', 'obiettivi'],
    ),
    const WidgetMetadata(
      type: 'focus_tasks',
      name: 'Focus Task',
      description: 'Le tue priorità del giorno con caselle di completamento e riga di inserimento rapido.',
      category: WidgetCategory.time,
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF6366F1),
      defaultSize: BentoWidgetSize(2, 2),
      allowedSizes: [BentoWidgetSize(2, 2), BentoWidgetSize(2, 3), BentoWidgetSize(3, 2), BentoWidgetSize(3, 3), BentoWidgetSize(2, 4)],
      keywords: ['task', 'todo', 'attività', 'completare', 'focus', 'obiettivi'],
    ),
    const WidgetMetadata(
      type: 'habit_tracker',
      name: 'Abitudini & Routine',
      description: 'Traccia la costanza delle tue routine quotidiane con indicatori di streak e cerchi.',
      category: WidgetCategory.time,
      icon: Icons.repeat_rounded,
      color: Color(0xFFEC4899),
      defaultSize: BentoWidgetSize(2, 1),
      allowedSizes: [BentoWidgetSize(2, 1), BentoWidgetSize(2, 2), BentoWidgetSize(4, 2), BentoWidgetSize(4, 4)],
      keywords: ['abitudini', 'routine', 'streak', 'giornaliere', 'disciplina'],
    ),
    const WidgetMetadata(
      type: 'hero_countdown',
      name: 'Countdown Prossimo Evento',
      description: 'Conto alla rovescia in tempo reale per viaggi, scadenze importanti o eventi.',
      category: WidgetCategory.time,
      icon: Icons.hourglass_top_rounded,
      color: Color(0xFF14B8A6),
      defaultSize: BentoWidgetSize(2, 1),
      allowedSizes: [BentoWidgetSize(2, 1), BentoWidgetSize(2, 2), BentoWidgetSize(4, 2)],
      keywords: ['evento', 'countdown', 'giorni', 'viaggio', 'vacanze', 'compleanno'],
    ),

    // Note & Idee
    const WidgetMetadata(
      type: 'note_stack',
      name: 'Pila di Note Sticky 3D',
      description: 'Mazzo di foglietti post-it 3D sfogliabili a swipe con modifica diretta in Home.',
      category: WidgetCategory.notes,
      icon: Icons.layers_rounded,
      color: Color(0xFFF59E0B),
      defaultSize: BentoWidgetSize(2, 2),
      allowedSizes: [BentoWidgetSize(2, 2), BentoWidgetSize(2, 1), BentoWidgetSize(2, 3), BentoWidgetSize(4, 2)],
      keywords: ['note', 'sticky', 'post-it', 'appunti', 'stack', 'pila', 'scrittura'],
    ),
    const WidgetMetadata(
      type: 'recent_notes',
      name: 'Note Recenti',
      description: 'Elenco compatto delle ultime note con anteprima di testo e inserimento in-place.',
      category: WidgetCategory.notes,
      icon: Icons.notes_rounded,
      color: Color(0xFFF59E0B),
      defaultSize: BentoWidgetSize(2, 2),
      allowedSizes: [BentoWidgetSize(2, 2), BentoWidgetSize(2, 3), BentoWidgetSize(3, 2), BentoWidgetSize(3, 3), BentoWidgetSize(2, 4)],
      keywords: ['note', 'elenco', 'lista note', 'testo', 'recenti'],
    ),
    const WidgetMetadata(
      type: 'recent_markdown',
      name: 'File Markdown',
      description: 'Accesso rapido ai documenti markdown e file tecnici salvati.',
      category: WidgetCategory.notes,
      icon: Icons.description_rounded,
      color: Color(0xFF6366F1),
      defaultSize: BentoWidgetSize(2, 2),
      allowedSizes: [BentoWidgetSize(2, 2), BentoWidgetSize(2, 3), BentoWidgetSize(3, 2)],
      keywords: ['markdown', 'md', 'documenti', 'file'],
    ),

    // Casa & Spazio
    const WidgetMetadata(
      type: 'shopping_quick_list',
      name: 'Lista della Spesa',
      description: 'Articoli da acquistare con spunta, ricerca dispensa e aggiunta rapida inline.',
      category: WidgetCategory.home,
      icon: Icons.shopping_cart_outlined,
      color: Color(0xFF3B82F6),
      defaultSize: BentoWidgetSize(2, 2),
      allowedSizes: [BentoWidgetSize(2, 2), BentoWidgetSize(2, 3), BentoWidgetSize(3, 2), BentoWidgetSize(3, 3), BentoWidgetSize(2, 4)],
      keywords: ['spesa', 'supermercato', 'comprare', 'articoli', 'lista spesa'],
    ),
    const WidgetMetadata(
      type: 'pantry_alert',
      name: 'Dispensa & Scadenze',
      description: 'Notifica preventiva sui prodotti della dispensa in scadenza o da rifornire.',
      category: WidgetCategory.home,
      icon: Icons.kitchen_rounded,
      color: Color(0xFF10B981),
      defaultSize: BentoWidgetSize(1, 1),
      allowedSizes: [BentoWidgetSize(1, 1), BentoWidgetSize(2, 1)],
      keywords: ['dispensa', 'scadenza', 'cibo', 'scorte', 'pantry'],
    ),
    const WidgetMetadata(
      type: 'unresolved_asterisks',
      name: 'Asterischi in Sospeso',
      description: 'Segnaposto mentali per questioni da chiarire o ricordare, con risoluzione al tap.',
      category: WidgetCategory.home,
      icon: Icons.star_border_rounded,
      color: Color(0xFFFBBF24),
      defaultSize: BentoWidgetSize(2, 2),
      allowedSizes: [BentoWidgetSize(2, 2), BentoWidgetSize(2, 3), BentoWidgetSize(3, 2), BentoWidgetSize(3, 3), BentoWidgetSize(2, 4)],
      keywords: ['asterischi', 'dubbi', 'ricordare', 'punti', 'discussione'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final item in _catalog) {
      _selectedSizes[item.type] = item.defaultSize;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WidgetMetadata> get _filteredWidgets {
    return _catalog.where((meta) {
      // Category filter
      if (_selectedCategory != WidgetCategory.all && meta.category != _selectedCategory) {
        return false;
      }

      // Search filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchName = meta.name.toLowerCase().contains(q);
        final matchDesc = meta.description.toLowerCase().contains(q);
        final matchKeywords = meta.keywords.any((k) => k.toLowerCase().contains(q));
        return matchName || matchDesc || matchKeywords;
      }

      return true;
    }).toList();
  }

  Future<void> _onAdd(WidgetMetadata meta) async {
    HapticFeedback.mediumImpact();
    final chosenSize = _selectedSizes[meta.type] ?? meta.defaultSize;

    Map<String, dynamic>? customProps;
    if (DashboardWidgetFactory.requiresInit(meta.type)) {
      customProps = await widget.onConfigureWidget(context, meta.type);
      if (customProps == null) {
        // User cancelled configuration
        return;
      }
    }

    final newDef = BentoWidgetDef(
      id: const Uuid().v4(),
      type: meta.type,
      size: chosenSize,
      customProps: customProps,
    );

    widget.onAddWidget(newDef);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatSize(BentoWidgetSize size) {
    if (size.crossAxisCellCount == 2 && size.mainAxisCellCount == 2) return '2x2 (Quadrato)';
    if (size.crossAxisCellCount == 2 && size.mainAxisCellCount == 1) return '2x1 (Compatto)';
    if (size.crossAxisCellCount == 1 && size.mainAxisCellCount == 1) return '1x1 (Icona)';
    if (size.crossAxisCellCount == 1 && size.mainAxisCellCount == 2) return '1x2 (Verticale)';
    if (size.crossAxisCellCount == 2 && size.mainAxisCellCount == 3) return '2x3 (Medio)';
    if (size.crossAxisCellCount == 3 && size.mainAxisCellCount == 2) return '3x2 (Ampio)';
    if (size.crossAxisCellCount == 3 && size.mainAxisCellCount == 3) return '3x3 (Grande)';
    if (size.crossAxisCellCount == 4 && size.mainAxisCellCount == 2) return '4x2 (Panoramico)';
    if (size.crossAxisCellCount == 4 && size.mainAxisCellCount == 4) return '4x4 (Massimo)';
    return '${size.crossAxisCellCount}x${size.mainAxisCellCount}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredWidgets;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Galleria Widget',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Personalizza la tua Bento Home',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Cerca per nome, tag o parola chiave...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.clear, color: Colors.white38, size: 16),
                    ),
                ],
              ),
            ),
          ),

          // Category tabs carousel
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: WidgetCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = WidgetCategory.values[idx];
                final isSelected = cat == _selectedCategory;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withOpacity(0.2)
                          : const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? cat.color.withOpacity(0.6)
                            : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 14,
                          color: isSelected ? cat.color : Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Widget cards list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        const Text(
                          'Nessun widget trovato',
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prova a cercare con un altro termine o categoria',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final meta = filtered[index];
                      final isCurrentlyActive = widget.currentLayout.any((w) => w.type == meta.type);
                      final currentSize = _selectedSizes[meta.type] ?? meta.defaultSize;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: meta.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: meta.color.withOpacity(0.3), width: 1),
                                  ),
                                  child: Icon(meta.icon, color: meta.color, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              meta.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                          ),
                                          if (isCurrentlyActive)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                              ),
                                              child: const Text(
                                                'In uso',
                                                style: TextStyle(
                                                  color: Color(0xFF34D399),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        meta.description,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.65),
                                          fontSize: 12,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Dynamic Live Preview Stage (Proportional Size)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final previewSize = BentoWidgetPreviewFactory.getPreviewSize(
                                  currentSize,
                                  constraints.maxWidth,
                                );

                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0F12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.04),
                                    ),
                                  ),
                                  child: Center(
                                    child: AnimatedSize(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      child: SizedBox(
                                        width: previewSize.width,
                                        height: previewSize.height,
                                        child: BentoWidgetPreviewFactory.buildPreview(
                                          type: meta.type,
                                          size: currentSize,
                                          accentColor: meta.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Interactive Size Selector Chips (if multiple allowed)
                            if (meta.allowedSizes.length > 1) ...[
                              Row(
                                children: [
                                  Text(
                                    'TAGLIA ANTEPRIMA',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '• tocca per cambiare',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.25),
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: meta.allowedSizes.map((size) {
                                  final isSizeSelected = size.crossAxisCellCount == currentSize.crossAxisCellCount &&
                                      size.mainAxisCellCount == currentSize.mainAxisCellCount;

                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedSizes[meta.type] = size;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                                      decoration: BoxDecoration(
                                        color: isSizeSelected
                                            ? meta.color.withOpacity(0.2)
                                            : const Color(0xFF27272A),
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                          color: isSizeSelected
                                              ? meta.color.withOpacity(0.6)
                                              : Colors.white10,
                                          width: isSizeSelected ? 1.2 : 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSizeSelected) ...[
                                            Container(
                                              width: 4,
                                              height: 4,
                                              margin: const EdgeInsets.only(right: 5),
                                              decoration: BoxDecoration(
                                                color: meta.color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                          Text(
                                            _formatSize(size),
                                            style: TextStyle(
                                              color: isSizeSelected ? Colors.white : Colors.white60,
                                              fontSize: 10.5,
                                              fontWeight: isSizeSelected ? FontWeight.bold : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Bottom add action
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: meta.color,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: Text(
                                  DashboardWidgetFactory.requiresInit(meta.type)
                                      ? 'Configura e Aggiungi'
                                      : 'Aggiungi alla Home',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                onPressed: () => _onAdd(meta),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
