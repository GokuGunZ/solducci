import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/widgets/context_chip.dart';
import 'package:solducci/widgets/create_view_dialog.dart';

/// Widget che mostra il contesto corrente (Personal/Gruppo/Vista) e permette di switchare
class ContextSwitcher extends StatelessWidget {
  const ContextSwitcher({super.key});

  void _showContextPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _ContextPickerModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ContextManager(),
      builder: (context, child) {
        final contextManager = ContextManager();
        final currentContext = contextManager.currentContext;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showContextPicker(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icona contesto con colore distintivo
                  Icon(
                    currentContext.isPersonal
                        ? Icons.person
                        : currentContext.isView
                            ? Icons.dashboard
                            : Icons.group,
                    size: 20,
                    color: currentContext.isPersonal
                        ? Colors.purple
                        : currentContext.isView
                            ? Colors.blue
                            : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      currentContext.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Modal per selezionare il contesto
class _ContextPickerModal extends StatefulWidget {
  const _ContextPickerModal();

  @override
  State<_ContextPickerModal> createState() => _ContextPickerModalState();
}

class _ContextPickerModalState extends State<_ContextPickerModal> {
  // Multi-select per creare viste
  final Set<String> _selectedGroupIds = {};
  final Set<String> _selectedViewIds = {};

  bool get _isInMultiSelectMode =>
      _selectedGroupIds.length > 1 || _selectedViewIds.length > 1;

  @override
  void initState() {
    super.initState();
    // Pre-select current context se non in multi-select
    final currentContext = ContextManager().currentContext;
    if (currentContext.isGroup) {
      _selectedGroupIds.add(currentContext.groupId!);
    } else if (currentContext.isView) {
      _selectedViewIds.add(currentContext.viewId!);
    }
  }

  void _onChipTap(String id, ContextChipType type) {
    setState(() {
      if (type == ContextChipType.personal) {
        // Personal: switch diretto
        _selectedGroupIds.clear();
        _selectedViewIds.clear();
        ContextManager().switchToPersonal();
        Navigator.pop(context);
      } else if (type == ContextChipType.group) {
        // Gruppo: toggle multi-select
        if (_selectedGroupIds.contains(id)) {
          _selectedGroupIds.remove(id);
        } else {
          // Se clicco su un gruppo quando nessuno è selezionato, switch diretto
          if (_selectedGroupIds.isEmpty && _selectedViewIds.isEmpty) {
            final contextManager = ContextManager();
            final group = contextManager.userGroups.firstWhere((g) => g.id == id);
            contextManager.switchToGroup(group);
            Navigator.pop(context);
            return;
          }
          _selectedGroupIds.add(id);
        }
        _selectedViewIds.clear(); // Clear viste se selezioni gruppi
      } else if (type == ContextChipType.view) {
        // Vista: toggle multi-select
        if (_selectedViewIds.contains(id)) {
          _selectedViewIds.remove(id);
        } else {
          // Se clicco su una vista quando nessuna è selezionata, switch diretto
          if (_selectedViewIds.isEmpty && _selectedGroupIds.isEmpty) {
            final contextManager = ContextManager();
            final view = contextManager.userViews.firstWhere((v) => v.id == id);
            contextManager.switchToView(view);
            Navigator.pop(context);
            return;
          }
          _selectedViewIds.add(id);
        }
        _selectedGroupIds.clear(); // Clear gruppi se selezioni viste
      }
    });
  }

  void _confirmSelection() async {
    if (_isInMultiSelectMode) {
      // Mostra dialog "Crea Vista"
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => CreateViewDialog(
          selectedGroupIds: _selectedGroupIds.toList(),
          selectedViewIds: _selectedViewIds.toList(),
        ),
      );

      if (result == true && mounted) {
        Navigator.pop(context); // Chiudi modal picker
      }
    } else {
      // Switch diretto (singola selezione)
      final contextManager = ContextManager();

      if (_selectedGroupIds.length == 1) {
        final group = contextManager.userGroups
            .firstWhere((g) => g.id == _selectedGroupIds.first);
        contextManager.switchToGroup(group);
        Navigator.pop(context);
      } else if (_selectedViewIds.length == 1) {
        final view = contextManager.userViews
            .firstWhere((v) => v.id == _selectedViewIds.first);
        contextManager.switchToView(view);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleIncludePersonal(String viewId) async {
    await ContextManager().toggleIncludePersonalForView(viewId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final contextManager = ContextManager();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Seleziona Contesto',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: ListenableBuilder(
              listenable: contextManager,
              builder: (context, child) {
                final userGroups = contextManager.userGroups;
                final userViews = contextManager.userViews;

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Chip Personale
                    ContextChip(
                      id: 'personal',
                      label: 'Personale',
                      type: ContextChipType.personal,
                      isSelected: contextManager.currentContext.isPersonal &&
                          !_isInMultiSelectMode,
                      onTap: () => _onChipTap('personal', ContextChipType.personal),
                    ),

                    const SizedBox(height: 24),

                    // LE TUE VISTE (prima dei gruppi)
                    if (userViews.isNotEmpty) ...[
                      Text(
                        'LE TUE VISTE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: userViews.map((view) {
                          final isSelected = _selectedViewIds.contains(view.id);

                          return ContextChip(
                            id: view.id,
                            label: view.name,
                            type: ContextChipType.view,
                            isSelected: isSelected,
                            includesPersonal: view.includePersonal,
                            onTap: () =>
                                _onChipTap(view.id, ContextChipType.view),
                            onAddPersonalTap: () =>
                                _toggleIncludePersonal(view.id),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),
                    ],

                    // I TUOI GRUPPI
                    Text(
                      'I TUOI GRUPPI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: userGroups.map((group) {
                        final isSelected =
                            _selectedGroupIds.contains(group.id);

                        return ContextChip(
                          id: group.id,
                          label: group.name,
                          type: ContextChipType.group,
                          isSelected: isSelected,
                          onTap: () =>
                              _onChipTap(group.id, ContextChipType.group),
                          // TODO: Implementare creazione vista rapida gruppo+personale
                          onAddPersonalTap: null,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 80), // Spazio per bottoni in basso
                  ],
                );
              },
            ),
          ),

          // Bottoni in basso (affiancati)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Bottone "+ Crea Vista"
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isInMultiSelectMode ? _confirmSelection : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Crea Vista'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Bottone "+ Crea Gruppo"
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/groups/create');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Crea Gruppo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
