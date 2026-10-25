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
  Set<String> _selectedOptionIds = {};

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final data = await BentoWidgetConfigRegistry.getConfigForWidget(
      type: widgetType,
      currentProps: widget.initialProps,
    );

    if (mounted) {
      if (data.isMultiSelect) {
        final rawSelected = widget.initialProps?['selectedSourceIds'] as List?;
        if (rawSelected != null && rawSelected.isNotEmpty) {
          final set = rawSelected.map((e) => e.toString()).toSet();
          _selectedOptionIds = set.intersection(data.options.map((o) => o.id).toSet());
          if (_selectedOptionIds.isEmpty) {
            _selectedOptionIds = data.options.map((o) => o.id).toSet();
          }
        } else {
          // Default: all options selected!
          _selectedOptionIds = data.options.map((o) => o.id).toSet();
        }
      } else {
        // Determina l'opzione inizialmente selezionata
        String? initialSelectedId;
        if (widget.initialProps != null) {
          final currentEntityId = widget.initialProps!['entity_id'] as String?;
          final currentSource = widget.initialProps!['source'] as String?;
          final currentWalletId = widget.initialProps!['walletId'] as int?;
          final currentDocId = widget.initialProps!['documentId'] as int?;
          final currentRoutineId = widget.initialProps!['routineId'] as int?;
          final currentScenarioId = widget.initialProps!['scenarioId'] as int?;
          final currentCategory = widget.initialProps!['category'] as String?;

          if (currentEntityId != null) {
            initialSelectedId = currentEntityId;
          } else if (currentWalletId != null) {
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
        _selectedOptionId = initialSelectedId;
      }

      setState(() {
        _configData = data;
        _loading = false;
      });
    }
  }

  String get widgetType => widget.widgetType;

  void _onOptionSelected(BentoConfigOption option) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOptionId = option.id;
    });
  }

  void _onOptionToggle(BentoConfigOption option) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedOptionIds.contains(option.id)) {
        if (_selectedOptionIds.length > 1) {
          _selectedOptionIds.remove(option.id);
        }
      } else {
        _selectedOptionIds.add(option.id);
      }
    });
  }

  void _onOptionSoloSelect(BentoConfigOption option) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedOptionIds = {option.id};
    });
  }

  void _onToggleSelectAll() {
    if (_configData == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedOptionIds.length == _configData!.options.length) {
        // Keep only first
        _selectedOptionIds = {_configData!.options.first.id};
      } else {
        _selectedOptionIds = _configData!.options.map((o) => o.id).toSet();
      }
    });
  }

  void _saveConfiguration() {
    if (_configData == null || _configData!.options.isEmpty) {
      Navigator.of(context).pop(<String, dynamic>{});
      return;
    }

    if (_configData!.isMultiSelect) {
      final selectedList = _selectedOptionIds.toList();
      final finalProps = <String, dynamic>{
        'selectedSourceIds': selectedList,
      };
      if (selectedList.isNotEmpty) {
        final firstOpt = _configData!.options.firstWhere(
          (o) => o.id == selectedList.first,
          orElse: () => _configData!.options.first,
        );
        finalProps.addAll(firstOpt.props);
        finalProps['selectedSourceIds'] = selectedList;
      }
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(finalProps);
      return;
    }

    final selectedOption = _configData!.options.cast<BentoConfigOption?>().firstWhere(
          (o) => o?.id == _selectedOptionId,
          orElse: () => _configData!.options.first,
        );

    final finalProps = Map<String, dynamic>.from(selectedOption?.props ?? {});
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
                    // Sezione: Sorgente Dati
                    if (_configData != null && _configData!.options.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _configData!.isMultiSelect
                                ? 'SORGENTI ATTIVE (${_selectedOptionIds.length}/${_configData!.options.length})'
                                : 'SORGENTE DATI',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (_configData!.isMultiSelect)
                            GestureDetector(
                              onTap: _onToggleSelectAll,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  _selectedOptionIds.length == _configData!.options.length
                                      ? 'Deseleziona altri'
                                      : 'Seleziona tutti',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _configData!.options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final option = _configData!.options[index];
                          final isMulti = _configData!.isMultiSelect;
                          final isSelected = isMulti
                              ? _selectedOptionIds.contains(option.id)
                              : option.id == _selectedOptionId;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isMulti
                                ? () => _onOptionToggle(option)
                                : () => _onOptionSelected(option),
                            onLongPress: isMulti
                                ? () => _onOptionSoloSelect(option)
                                : null,
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
                                        if (option.preview != null && option.preview!.isNotEmpty) ...[
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: option.color.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: option.color.withOpacity(0.25), width: 0.8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.remove_red_eye_outlined, size: 11, color: option.color.withOpacity(0.9)),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    option.preview!,
                                                    style: TextStyle(
                                                      color: option.color.withOpacity(0.95),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isMulti
                                        ? (isSelected
                                            ? Icons.check_box_rounded
                                            : Icons.check_box_outline_blank_rounded)
                                        : (isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded),
                                    color: isSelected ? option.color : Colors.white24,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
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
