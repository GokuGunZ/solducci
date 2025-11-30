import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/widgets/context_chip.dart';
import 'package:solducci/models/expense_view.dart';

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
                    child: _buildContextName(currentContext),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build context name with purple icon for personal expenses
  Widget _buildContextName(ExpenseContext currentContext) {
    final baseName = currentContext.isPersonal
        ? 'Personale'
        : currentContext.isView
            ? currentContext.view!.name
            : currentContext.group!.name;

    // Se include personal, aggiungi icona viola
    if (currentContext.includesPersonal) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: baseName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const TextSpan(text: ' '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.person,
                size: 18,
                color: Colors.purple[600],
              ),
            ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    // Altrimenti solo testo normale
    return Text(
      baseName,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      overflow: TextOverflow.ellipsis,
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

  // Controller per edit nome
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;

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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onChipTap(String id, ContextChipType type) {
    final contextManager = ContextManager();

    if (type == ContextChipType.personal) {
      // Personal: switch immediato (refresh dinamico)
      setState(() {
        _selectedGroupIds.clear();
        _selectedViewIds.clear();
      });
      contextManager.switchToPersonal();
    } else if (type == ContextChipType.group) {
      // Gruppo: toggle multi-select
      if (_selectedGroupIds.contains(id)) {
        // Deseleziona
        setState(() {
          _selectedGroupIds.remove(id);
        });
      } else {
        // Seleziona
        setState(() {
          _selectedGroupIds.add(id);
          _selectedViewIds.clear(); // Clear viste se selezioni gruppi
        });
      }

      // Refresh dinamico basato sul numero di gruppi selezionati
      if (_selectedGroupIds.length == 1 && _selectedViewIds.isEmpty) {
        // 1 gruppo: switch normale
        final group = contextManager.userGroups.firstWhere(
          (g) => g.id == _selectedGroupIds.first,
        );
        contextManager.switchToGroup(group);
      } else if (_selectedGroupIds.length > 1) {
        // Multi-select: crea vista temporanea per preview
        contextManager.switchToTemporaryView(_selectedGroupIds.toList());
      }
    } else if (type == ContextChipType.view) {
      // Vista: toggle multi-select
      if (_selectedViewIds.contains(id)) {
        // Deseleziona vista
        setState(() {
          _selectedViewIds.remove(id);
        });
      } else {
        // Seleziona vista
        setState(() {
          _selectedViewIds.add(id);
        });
      }

      // Popola _selectedGroupIds con l'unione dei gruppi delle viste selezionate
      setState(() {
        _selectedGroupIds.clear();
        for (final viewId in _selectedViewIds) {
          final view = contextManager.userViews.firstWhere((v) => v.id == viewId);
          _selectedGroupIds.addAll(view.groupIds);
        }
      });

      // Refresh dinamico basato sul numero di viste selezionate
      if (_selectedViewIds.length == 1) {
        // 1 vista: switch normale
        final view = contextManager.userViews.firstWhere((v) => v.id == id);
        contextManager.switchToView(view);
      } else if (_selectedViewIds.length > 1) {
        // Multi-select viste: crea vista temporanea con unione gruppi
        contextManager.switchToTemporaryView(_selectedGroupIds.toList());
      }
    }
  }

  Future<void> _toggleIncludePersonal(String viewId) async {
    await ContextManager().toggleIncludePersonalForView(viewId);
    setState(() {});
  }

  /// Determina se un gruppo è correlato (parte di vista selezionata)
  bool _isGroupRelated(String groupId) {
    if (_selectedViewIds.length != 1) return false;

    final contextManager = ContextManager();
    final view = contextManager.userViews.firstWhere((v) => v.id == _selectedViewIds.first);
    return view.groupIds.contains(groupId);
  }

  /// Determina se una vista è correlata (corrisponde ai gruppi multi-selezionati)
  bool _isViewRelated(String viewId) {
    if (_selectedGroupIds.length < 2) return false;

    final contextManager = ContextManager();
    final view = contextManager.userViews.firstWhere((v) => v.id == viewId);

    // Verifica se la vista contiene esattamente gli stessi gruppi selezionati
    final sortedSelected = _selectedGroupIds.toList()..sort();
    final sortedView = view.groupIds.toList()..sort();

    return sortedSelected.length == sortedView.length &&
        sortedSelected.every((id) => sortedView.contains(id));
  }

  /// Salva nome modificato (gruppo o vista) o crea nuova vista
  Future<void> _saveEditedName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final contextManager = ContextManager();

    try {
      if (_selectedGroupIds.length == 1 && _selectedViewIds.isEmpty) {
        // Edit nome gruppo
        final group = contextManager.userGroups.firstWhere(
          (g) => g.id == _selectedGroupIds.first,
        );
        final updatedGroup = group.copyWith(name: name);
        await contextManager.updateGroup(updatedGroup);
      } else if (_selectedViewIds.length == 1 && _selectedGroupIds.isEmpty) {
        // Edit nome vista esistente
        final view = contextManager.userViews.firstWhere(
          (v) => v.id == _selectedViewIds.first,
        );
        final updatedView = view.copyWith(name: name);
        await contextManager.updateView(updatedView);
      } else if (_selectedGroupIds.length > 1 || _selectedViewIds.length > 1) {
        // Crea nuova vista con multi-select gruppi o viste
        await contextManager.createAndSwitchToView(
          name: name,
          groupIds: _selectedGroupIds.toList(),
          includePersonal: false,
        );

        // Reset stato
        setState(() {
          _isEditingName = false;
          _selectedGroupIds.clear();
          _selectedViewIds.clear(); // Reset anche viste selezionate
          _nameController.clear();
        });
      }

      setState(() {
        _isEditingName = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  /// Build dynamic header with editable title
  Widget _buildDynamicHeader(ContextManager contextManager) {
    String titleText;
    String? placeholder;
    bool showEditButton = false;
    bool isEditable = false;

    // Determina stato dell'header
    if (_selectedGroupIds.length == 1 && _selectedViewIds.isEmpty) {
      // Single gruppo selezionato
      final group = contextManager.userGroups.firstWhere(
        (g) => g.id == _selectedGroupIds.first,
      );
      titleText = group.name;
      isEditable = true; // TODO: Check if user is admin
      showEditButton = isEditable;
    } else if (_selectedViewIds.length == 1 && _selectedGroupIds.isEmpty) {
      // Vista selezionata
      final view = contextManager.userViews.firstWhere(
        (v) => v.id == _selectedViewIds.first,
      );
      titleText = view.name;
      isEditable = true; // Viste sono sempre editabili (local)
      showEditButton = true;
    } else if (_selectedGroupIds.length > 1 || _selectedViewIds.length > 1) {
      // Multi-select gruppi o viste
      ExpenseView? relatedView;
      for (final view in contextManager.userViews) {
        if (_isViewRelated(view.id)) {
          relatedView = view;
          break;
        }
      }

      if (relatedView != null) {
        // Vista esistente corrispondente
        titleText = relatedView.name;
        isEditable = true;
        showEditButton = true;
      } else {
        // Nessuna vista corrispondente
        titleText = '';
        placeholder = 'Nuova Vista';
        isEditable = true;
        showEditButton = true;
      }
    } else {
      // Nessuna selezione o personal
      titleText = contextManager.currentContext.displayName;
      isEditable = false;
    }

    // Inizializza controller se in modalità edit
    if (isEditable && !_isEditingName) {
      _nameController.text = titleText;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Titolo dinamico con form (centrato)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: isEditable
                    ? TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: placeholder,
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          setState(() {
                            _isEditingName = true;
                          });
                        },
                      )
                    : Text(
                        titleText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (showEditButton && _isEditingName) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _saveEditedName,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // "Seleziona Contesto" piccolo (allineato a sinistra)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Seleziona Contesto',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
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

          // Dynamic Header
          _buildDynamicHeader(contextManager),

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
                    // Chip Personale (align left con width dinamica)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ContextChip(
                        id: 'personal',
                        label: 'Personale',
                        type: ContextChipType.personal,
                        isSelected:
                            contextManager.currentContext.isPersonal &&
                            !_isInMultiSelectMode,
                        onTap: () =>
                            _onChipTap('personal', ContextChipType.personal),
                      ),
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
                          final isRelated = _isViewRelated(view.id);

                          return ContextChip(
                            id: view.id,
                            label: view.name,
                            type: ContextChipType.view,
                            isSelected: isSelected,
                            isRelated: isRelated,
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
                        final isInSelectedGroups = _selectedGroupIds.contains(group.id);
                        final isRelated = _isGroupRelated(group.id);
                        final includesPersonal = contextManager.getGroupIncludesPersonal(group.id);

                        // Se ci sono viste selezionate, i gruppi sono "related" (derivati), non "selected"
                        final bool isSelected;
                        final bool isRelatedFinal;

                        if (_selectedViewIds.isNotEmpty && isInSelectedGroups) {
                          // Gruppo derivato da viste: mostra come "related" (semi-trasparente)
                          isSelected = false;
                          isRelatedFinal = true;
                        } else {
                          // Comportamento normale
                          isSelected = isInSelectedGroups;
                          isRelatedFinal = isRelated;
                        }

                        return ContextChip(
                          id: group.id,
                          label: group.name,
                          type: ContextChipType.group,
                          isSelected: isSelected,
                          isRelated: isRelatedFinal,
                          includesPersonal: includesPersonal,
                          onTap: () =>
                              _onChipTap(group.id, ContextChipType.group),
                          onAddPersonalTap: () async {
                            await contextManager.toggleIncludePersonalForGroup(group.id);
                          },
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
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/groups/create');
                },
                icon: const Icon(Icons.add),
                label: const Text('Crea Gruppo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
