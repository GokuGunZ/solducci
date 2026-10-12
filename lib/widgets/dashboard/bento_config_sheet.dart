import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/config/bento_config_models.dart';
import 'package:solducci/widgets/dashboard/config/bento_widget_config_registry.dart';
import 'package:solducci/widgets/dashboard/widget_gallery_sheet.dart';

/// Modal bottom sheet unificato e moderno per la configurazione dei widget Bento
class BentoConfigSheet extends StatefulWidget {
  final String widgetType;
  final Map<String, dynamic>? initialProps;

  const BentoConfigSheet({
    super.key,
    required this.widgetType,
    this.initialProps,
  });

  /// Metodo statico per aprire il modal e restituire i nuovi `customProps`
  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required BentoWidgetDef widgetDef,
  }) async {
    HapticFeedback.lightImpact();
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BentoConfigSheet(
        widgetType: widgetDef.type,
        initialProps: widgetDef.customProps,
      ),
    );
  }

  /// Sovraccarico accettando direttamente il tipo stringa
  static Future<Map<String, dynamic>?> showForType({
    required BuildContext context,
    required String widgetType,
    Map<String, dynamic>? currentProps,
  }) async {
    HapticFeedback.lightImpact();
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BentoConfigSheet(
        widgetType: widgetType,
        initialProps: currentProps,
      ),
    );
  }

  @override
  State<BentoConfigSheet> createState() => _BentoConfigSheetState();
}

class _BentoConfigSheetState extends State<BentoConfigSheet> {
  bool _loading = true;
  BentoWidgetConfigData? _configData;
  String? _selectedOptionId;
  final TextEditingController _customTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    final data = await BentoWidgetConfigRegistry.getConfigForWidget(
      type: widgetType,
      currentProps: widget.initialProps,
    );

    if (mounted) {
      // Determina l'opzione inizialmente selezionata
      String? initialSelectedId;
      if (widget.initialProps != null) {
        final currentSource = widget.initialProps!['source'] as String?;
        final currentWalletId = widget.initialProps!['walletId'] as int?;
        final currentDocId = widget.initialProps!['documentId'] as int?;
        final currentRoutineId = widget.initialProps!['routineId'] as int?;
        final currentScenarioId = widget.initialProps!['scenarioId'] as int?;
        final currentCategory = widget.initialProps!['category'] as String?;

        if (currentWalletId != null) {
          initialSelectedId = 'wallet_$currentWalletId';
        } else if (currentDocId != null) {
          initialSelectedId = 'doc_$currentDocId';
        } else if (currentRoutineId != null) {
          initialSelectedId = 'routine_$currentRoutineId';
        } else if (currentScenarioId != null) {
          initialSelectedId = 'scenario_$currentScenarioId';
        } else if (currentCategory != null) {
          initialSelectedId = 'cat_$currentCategory';
        } else if (currentSource != null) {
          initialSelectedId = currentSource;
        }
      }

      initialSelectedId ??= data.defaultOptionId;
      if (initialSelectedId == null && data.options.isNotEmpty) {
        initialSelectedId = data.options.first.id;
      }

      // Imposta titolo personalizzato se presente
      final existingTitle = widget.initialProps?['customTitle'] as String? ??
          widget.initialProps?['title'] as String?;
      if (existingTitle != null && existingTitle.isNotEmpty) {
        _customTitleController.text = existingTitle;
      } else {
        // Usa il titolo dell'opzione selezionata
        final selectedOpt = data.options.cast<BentoConfigOption?>().firstWhere(
              (o) => o?.id == initialSelectedId,
              orElse: () => null,
            );
        if (selectedOpt != null) {
          _customTitleController.text = selectedOpt.title;
        }
      }

      setState(() {
        _configData = data;
        _selectedOptionId = initialSelectedId;
        _loading = false;
      });
    }
  }

  String get widgetType => widget.widgetType;

  void _onOptionSelected(BentoConfigOption option) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOptionId = option.id;
      // Aggiorna l'etichetta personalizzata solo se non era stata editata manualmente
      _customTitleController.text = option.title;
    });
  }

  void _saveConfiguration() {
    if (_configData == null || _configData!.options.isEmpty) {
      Navigator.of(context).pop(<String, dynamic>{});
      return;
    }

    final selectedOption = _configData!.options.cast<BentoConfigOption?>().firstWhere(
          (o) => o?.id == _selectedOptionId,
          orElse: () => _configData!.options.first,
        );

    final finalProps = Map<String, dynamic>.from(selectedOption?.props ?? {});
    final customTitle = _customTitleController.text.trim();
    if (customTitle.isNotEmpty) {
      finalProps['customTitle'] = customTitle;
      finalProps['title'] = customTitle;
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(finalProps);
  }

  @override
  Widget build(BuildContext context) {
    final meta = WidgetCatalog.findByType(widgetType);
    final accentColor = meta?.color ?? const Color(0xFF6366F1);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // OLED Dark Surface
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(meta?.icon ?? Icons.settings_rounded, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _configData?.title ?? 'Configura Widget',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _configData?.description ?? 'Personalizza la sorgente e le impostazioni del tile',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Content body
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60.0),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
            )
          else ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sezione 1: Sorgente Dati
                    if (_configData != null && _configData!.options.isNotEmpty) ...[
                      const Text(
                        'SORGENTE DATI',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _configData!.options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final option = _configData!.options[index];
                          final isSelected = option.id == _selectedOptionId;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _onOptionSelected(option),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? option.color.withOpacity(0.12)
                                    : Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? option.color.withOpacity(0.6)
                                      : Colors.white.withOpacity(0.08),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: option.color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(option.icon, color: option.color, size: 20),
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
                                                option.title,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (option.badge != null) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: option.color.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  option.badge!,
                                                  style: TextStyle(
                                                    color: option.color,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (option.subtitle != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            option.subtitle!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: isSelected ? option.color : Colors.white24,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Sezione 2: Personalizzazione Nome Tile
                    const Text(
                      'PERSONALIZZAZIONE TILE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Etichetta del Widget',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customTitleController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Es. Conto Personale, Spesa Famiglia',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: accentColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Questo testo apparirà come intestazione o nome di riferimento sulla tua dashboard.',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action bar
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Salva Configurazione',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _saveConfiguration,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
