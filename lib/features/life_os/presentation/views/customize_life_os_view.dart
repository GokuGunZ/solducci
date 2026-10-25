import 'package:flutter/material.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/services/user_property_pack_service.dart';

/// Management View: "Personalizza LifeOS" -> "Nature e proprietà" (INT-D016 / Step 3.2)
/// Allows individual users to configure default property suggestions for each SemanticRole.
class CustomizeLifeOsView extends StatefulWidget {
  const CustomizeLifeOsView({super.key});

  @override
  State<CustomizeLifeOsView> createState() => _CustomizeLifeOsViewState();
}

class _CustomizeLifeOsViewState extends State<CustomizeLifeOsView> {
  final UserPropertyPackService _packService = getIt<UserPropertyPackService>();
  SemanticRole _selectedRole = SemanticRole.project;
  List<PropertyTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final loaded = await _packService.getTemplatesForRole(_selectedRole);
    if (mounted) {
      setState(() {
        _templates = List.from(loaded);
        _isLoading = false;
      });
    }
  }

  void _onRoleChanged(SemanticRole role) {
    if (_selectedRole == role) return;
    setState(() => _selectedRole = role);
    _loadTemplates();
  }

  Future<void> _saveCurrentList() async {
    await _packService.saveTemplatesForRole(_selectedRole, _templates);
  }

  Future<void> _showAddTemplateDialog() async {
    final labelCtrl = TextEditingController();
    PropertyType selectedType = PropertyType.text;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(
                'Aggiungi al pacchetto ${_roleLabel(_selectedRole)}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Nome suggerimento (es. Obiettivo)',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Tipo: ', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(width: 8),
                      DropdownButton<PropertyType>(
                        value: selectedType,
                        dropdownColor: const Color(0xFF27272A),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        underline: const SizedBox(),
                        items: PropertyType.values.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedType = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () {
                    final label = labelCtrl.text.trim();
                    if (label.isNotEmpty) {
                      String key = label.toLowerCase().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
                      if (key.isEmpty) key = 'prop_${DateTime.now().millisecondsSinceEpoch}';

                      setState(() {
                        _templates.add(PropertyTemplate(
                          key: key,
                          label: label,
                          placeholder: 'Valore per $label...',
                          defaultType: selectedType,
                        ));
                      });
                      _saveCurrentList();
                    }
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('Aggiungi', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditTemplateDialog(int index) async {
    final current = _templates[index];
    final labelCtrl = TextEditingController(text: current.label);
    PropertyType selectedType = current.defaultType;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text(
                'Modifica Suggerimento',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Etichetta visualizzata',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Tipo: ', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(width: 8),
                      DropdownButton<PropertyType>(
                        value: selectedType,
                        dropdownColor: const Color(0xFF27272A),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        underline: const SizedBox(),
                        items: PropertyType.values.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedType = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () {
                    final label = labelCtrl.text.trim();
                    if (label.isNotEmpty) {
                      setState(() {
                        // Preserve original stable key to maintain semantic identity!
                        _templates[index] = PropertyTemplate(
                          key: current.key,
                          label: label,
                          placeholder: current.placeholder,
                          defaultType: selectedType,
                        );
                      });
                      _saveCurrentList();
                    }
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('Salva', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text('Ripristina Predefiniti?', style: TextStyle(color: Colors.white)),
        content: Text(
          'I suggerimenti predefiniti per "${_roleLabel(_selectedRole)}" verranno ripristinati.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ripristina', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _packService.resetToDefaults(_selectedRole);
      await _loadTemplates();
    }
  }

  String _roleLabel(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return 'Progetto';
      case SemanticRole.practice:
        return 'Pratica';
      case SemanticRole.concept:
        return 'Concetto';
      case SemanticRole.idea:
        return 'Idea';
      case SemanticRole.seed:
        return 'Seme';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Personalizza LifeOS',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Ripristina predefiniti per questa natura',
            icon: const Icon(Icons.restore_rounded, color: Colors.white54),
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheader: "Nature e proprietà"
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'NATURE E PROPRIETÀ SUGGERITE',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),

          // Role Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: SemanticRole.values.map((role) {
                final isSelected = role == _selectedRole;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_roleLabel(role)),
                    selected: isSelected,
                    onSelected: (_) => _onRoleChanged(role),
                    selectedColor: AppTheme.primary.withOpacity(0.25),
                    backgroundColor: const Color(0xFF141418),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.08),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Templates List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _templates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inbox_rounded, size: 36, color: Colors.white24),
                            const SizedBox(height: 8),
                            Text(
                              'Nessuna proprietà suggerita per ${_roleLabel(_selectedRole)}.\nIl seme o entità resterà leggero.',
                              style: const TextStyle(color: Colors.white38, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _templates.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _templates.removeAt(oldIndex);
                            _templates.insert(newIndex, item);
                          });
                          _saveCurrentList();
                        },
                        itemBuilder: (context, index) {
                          final template = _templates[index];
                          return Container(
                            key: ValueKey(template.key),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141418),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                              leading: const Icon(Icons.drag_indicator_rounded, color: Colors.white30, size: 20),
                              title: Text(
                                template.label,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Tipo: ${template.defaultType.name} • key: ${template.key}',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white60),
                                    onPressed: () => _showEditTemplateDialog(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white38),
                                    onPressed: () {
                                      setState(() {
                                        _templates.removeAt(index);
                                      });
                                      _saveCurrentList();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Action: Add to Pack
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(context).bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: AppTheme.primary.withOpacity(0.08),
                ),
                icon: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
                label: Text(
                  'Aggiungi proprietà a ${_roleLabel(_selectedRole)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onPressed: _showAddTemplateDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
