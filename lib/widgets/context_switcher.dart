import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/widgets/context_chip.dart';
import 'package:solducci/widgets/create_view_bubble.dart';
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

  /// Helper per verificare se il contesto corrente è la vista "Tutti i gruppi"
  bool _isAllGroupsView(ExpenseContext context) {
    if (!context.isView) return false;
    return context.view?.id == 'all-groups-preset';
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icona contesto con colore distintivo
                Icon(
                  currentContext.isPersonal
                      ? Icons.person
                      : currentContext.isView
                      ? (_isAllGroupsView(currentContext) ? Icons.groups : Icons.view_list_rounded)
                      : Icons.group,
                  size: 20,
                  color: currentContext.isPersonal
                      ? Colors.purple
                      : currentContext.isView
                      ? (_isAllGroupsView(currentContext) ? Colors.orange : Colors.blue)
                      : Colors.green,
                ),
                const SizedBox(width: 8),
                Flexible(child: _buildContextName(currentContext)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const TextSpan(text: ' '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.person, size: 18, color: Colors.purple[600]),
            ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    // Altrimenti solo testo normale
    return Text(
      baseName,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
  final Set<String> _visuallyHighlightedGroupIds =
      {}; // Gruppi evidenziati da tap singolo su vista (visual only)
  final Set<String> _selectedViewIds =
      {}; // Viste con tap singolo (visual only)
  final Set<String> _fullySelectedViewIds =
      {}; // Viste con doppio tap (actual selection)

  // Controller per edit nome
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;

  // Controllo visibilità bubble informativa
  bool _showBubble = false;

  // Timer per gestire delay tra tap singolo e doppio
  Timer? _tapTimer;
  String? _pendingTapViewId;

  bool get _isInMultiSelectMode =>
      _selectedGroupIds.length > 1 || _fullySelectedViewIds.length > 1;

  @override
  void initState() {
    super.initState();
    // Pre-select current context se non in multi-select
    final contextManager = ContextManager();
    final currentContext = contextManager.currentContext;

    if (currentContext.isGroup) {
      _selectedGroupIds.add(currentContext.groupId!);
    } else if (currentContext.isView) {
      // Check if it's a temporary view
      final tempView = contextManager.currentTemporaryView;
      if (tempView != null && currentContext.viewId == tempView.id) {
        // Vista temporanea: pre-seleziona i gruppi invece della vista
        _selectedGroupIds.addAll(tempView.groupIds);
      } else {
        // Vista normale: pre-seleziona la vista
        _selectedViewIds.add(currentContext.viewId!);
      }
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
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
        _visuallyHighlightedGroupIds.clear();
      });
      contextManager.switchToPersonal();
    } else if (type == ContextChipType.allGroups) {
      // Vista "Tutti i gruppi": crea vista temporanea con tutti i gruppi
      final includePersonal = _getAllGroupsIncludesPersonal(contextManager);

      setState(() {
        _selectedGroupIds.clear();
        _selectedViewIds.clear();
        _visuallyHighlightedGroupIds.clear();
      });

      contextManager.switchToAllGroupsView(includePersonal: includePersonal);
    } else if (type == ContextChipType.group) {
      // Gruppo: toggle multi-select
      if (_selectedGroupIds.contains(id)) {
        // Deseleziona
        setState(() {
          _selectedGroupIds.remove(id);
          // Nascondi bubble se non più in multi-select
          if (_selectedGroupIds.length <= 1) {
            _showBubble = false;
          }
        });
      } else {
        // Seleziona nuovo gruppo
        setState(() {
          _selectedGroupIds.add(id);
          // Clear TUTTE le viste e gruppi evidenziati se clicchi un gruppo
          _selectedViewIds.clear();
          _fullySelectedViewIds.clear();
          _visuallyHighlightedGroupIds.clear();
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

        // Mostra bubble informativa se non ci sono viste create
        if (contextManager.userViews.isEmpty) {
          setState(() {
            _showBubble = true;
          });
        }
      }
    } else if (type == ContextChipType.view) {
      // Vista: tap singolo (visual only, non seleziona gruppi)
      _onViewSingleTap(id, contextManager);
    }
  }

  /// Gestisce tap singolo su vista con delay per distinguere da doppio tap
  void _onViewSingleTap(String id, ContextManager contextManager) {
    // Se c'è già un timer pending, è un doppio tap
    if (_tapTimer?.isActive == true && _pendingTapViewId == id) {
      // Cancella il timer e esegui doppio tap
      _tapTimer?.cancel();
      _pendingTapViewId = null;
      _onViewDoubleTap(id, contextManager);
      return;
    }

    // Avvia timer per tap singolo con delay
    _pendingTapViewId = id;
    _tapTimer = Timer(const Duration(milliseconds: 300), () {
      // Esegui tap singolo dopo il delay
      _executeSingleTap(id, contextManager);
      _pendingTapViewId = null;
    });
  }

  /// Esegue tap singolo (visual only - gruppi molto trasparenti)
  void _executeSingleTap(String id, ContextManager contextManager) {
    if (_selectedViewIds.contains(id)) {
      // Deseleziona vista
      setState(() {
        _selectedViewIds.remove(id);
        _visuallyHighlightedGroupIds.clear();
      });
    } else {
      // Seleziona vista (visual only)
      setState(() {
        _selectedViewIds.add(id);
        _fullySelectedViewIds.clear(); // Clear doppi tap precedenti
        _selectedGroupIds.clear(); // Clear gruppi selezionati precedentemente

        // Popola gruppi per visualizzazione (ma NON sono effettivamente selezionati)
        _visuallyHighlightedGroupIds.clear();
        final view = contextManager.userViews.firstWhere((v) => v.id == id);
        _visuallyHighlightedGroupIds.addAll(view.groupIds);
      });
    }

    // Switch contesto per refresh dinamico
    if (_selectedViewIds.length == 1) {
      final view = contextManager.userViews.firstWhere((v) => v.id == id);
      contextManager.switchToView(view);
    } else if (_selectedViewIds.isEmpty) {
      contextManager.switchToPersonal();
    }
  }

  /// Gestisce doppio tap su vista (selezione effettiva con gruppi)
  void _onViewDoubleTap(String id, ContextManager contextManager) {
    if (_fullySelectedViewIds.contains(id)) {
      // Deseleziona dalla selezione completa
      setState(() {
        _fullySelectedViewIds.remove(id);
        _selectedViewIds.remove(id);
      });
    } else {
      // Seleziona completamente (popola gruppi)
      setState(() {
        _fullySelectedViewIds.add(id);
        _selectedViewIds.add(id);
        _visuallyHighlightedGroupIds
            .clear(); // Clear gruppi evidenziati da tap singolo
      });
    }

    // Popola _selectedGroupIds con l'unione dei gruppi delle viste fully selected
    setState(() {
      _selectedGroupIds.clear();
      for (final viewId in _fullySelectedViewIds) {
        final view = contextManager.userViews.firstWhere((v) => v.id == viewId);
        _selectedGroupIds.addAll(view.groupIds);
      }
    });

    // Refresh dinamico
    if (_fullySelectedViewIds.length == 1) {
      final view = contextManager.userViews.firstWhere((v) => v.id == id);
      contextManager.switchToView(view);
    } else if (_fullySelectedViewIds.length > 1) {
      contextManager.switchToTemporaryView(_selectedGroupIds.toList());
    }
  }

  Future<void> _toggleIncludePersonal(String viewId) async {
    await ContextManager().toggleIncludePersonalForView(viewId);
    setState(() {});
  }

  /// Elimina una vista custom
  Future<void> _deleteView(String viewId, ContextManager contextManager) async {
    // Conferma eliminazione
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Vista'),
        content: const Text('Sei sicuro di voler eliminare questa vista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await contextManager.deleteView(viewId);
      await contextManager.loadUserViews();

      setState(() {
        _selectedViewIds.remove(viewId);
        _isEditingName = false;
        _nameController.clear();
      });

      // Switch a Personal dopo eliminazione
      contextManager.switchToPersonal();
    }
  }

  /// Determina se la vista "Tutti i gruppi" è selezionata
  bool _isAllGroupsViewSelected(ContextManager contextManager) {
    if (!contextManager.currentContext.isView) return false;

    final currentView = contextManager.currentContext.view;
    if (currentView == null) return false;

    // Verifica se la vista corrente contiene tutti i gruppi
    final allGroupIds = contextManager.userGroups.map((g) => g.id).toSet();
    final currentGroupIds = currentView.groupIds.toSet();

    return allGroupIds.length == currentGroupIds.length &&
        allGroupIds.every((id) => currentGroupIds.contains(id));
  }

  /// Ottiene la preferenza "include personal" per la vista "Tutti i gruppi"
  bool _getAllGroupsIncludesPersonal(ContextManager contextManager) {
    if (_isAllGroupsViewSelected(contextManager)) {
      return contextManager.currentContext.view?.includePersonal ?? false;
    }
    return false;
  }

  /// Toggle "include personal" per la vista "Tutti i gruppi"
  Future<void> _toggleAllGroupsPersonal(ContextManager contextManager) async {
    final currentValue = _getAllGroupsIncludesPersonal(contextManager);
    contextManager.switchToAllGroupsView(includePersonal: !currentValue);
    setState(() {});
  }

  /// Determina se un gruppo è correlato (parte di vista selezionata)
  bool _isGroupRelated(String groupId) {
    if (_selectedViewIds.length != 1) return false;

    final contextManager = ContextManager();
    final view = contextManager.userViews.firstWhere(
      (v) => v.id == _selectedViewIds.first,
    );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
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
              // Bottone cestino per eliminare viste (solo per viste custom, non per "Tutti i gruppi")
              if (showEditButton && _isEditingName && _selectedViewIds.length == 1 && _selectedGroupIds.isEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteView(_selectedViewIds.first, contextManager),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Elimina vista',
                ),
                const SizedBox(width: 8),
              ],
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

    // Condizione per mostrare la bubble
    final shouldShowBubble =
        _selectedGroupIds.length > 1 &&
        _selectedViewIds.isEmpty &&
        contextManager.userViews.isEmpty &&
        _showBubble;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Stack(
        children: [
          Column(
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
                        // Chip Personale e "Tutti i gruppi" sulla stessa riga
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ContextChip(
                              id: 'personal',
                              label: 'Personale',
                              type: ContextChipType.personal,
                              isSelected:
                                  contextManager.currentContext.isPersonal &&
                                  !_isInMultiSelectMode,
                              onTap: () => _onChipTap(
                                'personal',
                                ContextChipType.personal,
                              ),
                            ),
                            // Chip "Tutti i gruppi" presettato
                            if (userGroups.isNotEmpty)
                              ContextChip(
                                id: 'all_groups',
                                label: 'Tutti i gruppi',
                                type: ContextChipType.allGroups,
                                isSelected: _isAllGroupsViewSelected(contextManager),
                                includesPersonal: _getAllGroupsIncludesPersonal(contextManager),
                                onTap: () => _onChipTap(
                                  'all_groups',
                                  ContextChipType.allGroups,
                                ),
                                onAddPersonalTap: () => _toggleAllGroupsPersonal(contextManager),
                              ),
                          ],
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
                              final isSelected = _selectedViewIds.contains(
                                view.id,
                              );
                              final isRelated = _isViewRelated(view.id);

                              return ContextChip(
                                id: view.id,
                                label: view.name,
                                type: ContextChipType.view,
                                isSelected: isSelected,
                                isRelated: isRelated,
                                isLightlySelected: _fullySelectedViewIds
                                    .contains(view.id),
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
                            final isInSelectedGroups = _selectedGroupIds
                                .contains(group.id);
                            final isVisuallyHighlighted =
                                _visuallyHighlightedGroupIds.contains(group.id);
                            final isRelated = _isGroupRelated(group.id);
                            final includesPersonal = contextManager
                                .getGroupIncludesPersonal(group.id);

                            // Determina stato visualizzazione gruppi
                            final bool isSelected;
                            final bool isRelatedFinal;
                            final bool isLightlySelected;

                            if (_fullySelectedViewIds.isNotEmpty &&
                                isInSelectedGroups) {
                              // Gruppo derivato da viste con doppio tap: meno trasparente
                              isSelected = false;
                              isRelatedFinal = false;
                              isLightlySelected = true;
                            } else if (_selectedViewIds.isNotEmpty &&
                                isVisuallyHighlighted) {
                              // Gruppo evidenziato da tap singolo su vista: molto trasparente (NON selezionato)
                              isSelected = false;
                              isRelatedFinal = true;
                              isLightlySelected = false;
                            } else {
                              // Comportamento normale
                              isSelected = isInSelectedGroups;
                              isRelatedFinal = isRelated;
                              isLightlySelected = false;
                            }

                            return ContextChip(
                              id: group.id,
                              label: group.name,
                              type: ContextChipType.group,
                              isSelected: isSelected,
                              isRelated: isRelatedFinal,
                              isLightlySelected: isLightlySelected,
                              includesPersonal: includesPersonal,
                              onTap: () =>
                                  _onChipTap(group.id, ContextChipType.group),
                              onAddPersonalTap: () async {
                                await contextManager
                                    .toggleIncludePersonalForGroup(group.id);
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(
                          height: 80,
                        ), // Spazio per bottoni in basso
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bubble informativa (sopra il contenuto)
          if (shouldShowBubble)
            Positioned(
              top: 120, // Sotto il Dynamic Header
              left: 0,
              right: 0,
              child: CreateViewBubble(
                onDismiss: () {
                  setState(() {
                    _showBubble = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
