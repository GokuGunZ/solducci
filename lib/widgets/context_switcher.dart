import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/widgets/context_chip.dart';
import 'package:solducci/widgets/create_view_bubble.dart';
import 'package:solducci/widgets/circular_context_avatar.dart';
import 'package:solducci/widgets/group_mosaic_avatar.dart';
import 'package:solducci/utils/app_image_helper.dart';
import 'package:solducci/service/profile_service_cached.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:solducci/models/expense_view.dart';

/// Widget che mostra il contesto corrente (Personal/Gruppo/Vista) e permette di switchare
class ContextSwitcher extends StatelessWidget {
  const ContextSwitcher({super.key});

  void _showContextPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

        return Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showContextPicker(context),
              borderRadius: BorderRadius.circular(20), // More circular bounding box for ripples
              child: CircularContextAvatar(
                expenseContext: currentContext,
                radius: kToolbarHeight * 0.425,
                showLabel: false,
              ),
            ),
          ),
        );
      },
    );
  }

  // The `_buildContextName` is no longer needed in ContextSwitcher 
  // as it's handled by CircularContextAvatar, but we can leave it or remove it.
  // I am removing it to clean up the code.
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
        return;
      } else if (contextManager.currentContext.isGroup && contextManager.currentContext.group != null) {
        // Fallback: se stiamo modificando il gruppo del contesto corrente
        final updatedGroup = contextManager.currentContext.group!.copyWith(name: name);
        await contextManager.updateGroup(updatedGroup);
      } else if (contextManager.currentContext.isView && contextManager.currentContext.view != null) {
        // Fallback: se stiamo modificando la vista del contesto corrente
        final updatedView = contextManager.currentContext.view!.copyWith(name: name);
        await contextManager.updateView(updatedView);
      }

      setState(() {
        _isEditingName = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore durante il salvataggio: $e')));
      }
    }
  }

  /// Build dynamic header with group avatar, editable title, participants, and personal toggle
  Widget _buildDynamicHeader(ContextManager contextManager) {
    String titleText;
    String? placeholder;
    bool showEditButton = false;
    bool isEditable = false;
    ExpenseGroup? selectedGroup;
    ExpenseView? selectedView;
    List<ExpenseGroup> viewGroups = [];

    // Determina stato dell'header
    if (_selectedGroupIds.length == 1 && _selectedViewIds.isEmpty) {
      // Single gruppo selezionato
      final matching = contextManager.userGroups.where((g) => g.id == _selectedGroupIds.first).toList();
      if (matching.isNotEmpty) {
        selectedGroup = matching.first;
        titleText = selectedGroup.name;
        isEditable = true;
        showEditButton = true;
      } else {
        titleText = contextManager.currentContext.displayName;
      }
    } else if (_selectedViewIds.length == 1 && _selectedGroupIds.isEmpty) {
      // Vista selezionata
      final matching = contextManager.userViews.where((v) => v.id == _selectedViewIds.first).toList();
      if (matching.isNotEmpty) {
        selectedView = matching.first;
        titleText = selectedView.name;
        isEditable = true;
        showEditButton = true;
        viewGroups = contextManager.userGroups.where((g) => selectedView!.groupIds.contains(g.id)).toList();
      } else {
        titleText = contextManager.currentContext.displayName;
      }
    } else if (_selectedGroupIds.length > 1 || _selectedViewIds.length > 1) {
      // Multi-select gruppi o viste
      for (final view in contextManager.userViews) {
        if (_isViewRelated(view.id)) {
          selectedView = view;
          break;
        }
      }

      if (selectedView != null) {
        titleText = selectedView.name;
        isEditable = true;
        showEditButton = true;
        viewGroups = contextManager.userGroups.where((g) => selectedView!.groupIds.contains(g.id)).toList();
      } else {
        titleText = '';
        placeholder = 'Nuova Vista';
        isEditable = true;
        showEditButton = true;
        viewGroups = contextManager.userGroups.where((g) => _selectedGroupIds.contains(g.id)).toList();
      }
    } else {
      // Nessuna selezione esplicita: verifica current context
      if (contextManager.currentContext.isGroup && contextManager.currentContext.group != null) {
        selectedGroup = contextManager.currentContext.group;
        titleText = selectedGroup!.name;
        isEditable = true;
        showEditButton = true;
      } else if (contextManager.currentContext.isView && contextManager.currentContext.view != null) {
        selectedView = contextManager.currentContext.view;
        titleText = selectedView!.name;
        isEditable = true;
        showEditButton = true;
        viewGroups = contextManager.userGroups.where((g) => selectedView!.groupIds.contains(g.id)).toList();
      } else {
        titleText = contextManager.currentContext.displayName;
        isEditable = false;
      }
    }

    // Inizializza controller solo se non stiamo attualmente scrivendo
    if (isEditable && !_isEditingName && _nameController.text != titleText) {
      _nameController.text = titleText;
    }

    final bool isPersonalActive = contextManager.currentContext.isPersonal && _selectedGroupIds.isEmpty && _selectedViewIds.isEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONTESTO SELEZIONATO',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white38,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedGroup != null)
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/groups/${selectedGroup!.id}');
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Apri team',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Selected Context Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF18181D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Context / Group Avatar with direct navigation
                GestureDetector(
                  onTap: () {
                    if (selectedGroup != null) {
                      Navigator.pop(context);
                      context.push('/groups/${selectedGroup.id}');
                    } else if (selectedView != null && viewGroups.isNotEmpty) {
                      // Navigate to first group in view if tapped
                      Navigator.pop(context);
                      context.push('/groups/${viewGroups.first.id}');
                    }
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedGroup != null
                                ? const Color(0xFF10B981).withOpacity(0.6)
                                : selectedView != null
                                    ? const Color(0xFF3B82F6).withOpacity(0.6)
                                    : const Color(0xFFA855F7).withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: selectedGroup != null
                              ? GroupMosaicAvatar(
                                  group: selectedGroup,
                                  radius: 25,
                                  members: selectedGroup.members,
                                )
                              : selectedView != null
                                  ? Container(
                                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                                      child: const Icon(Icons.view_list_rounded, color: Color(0xFF60A5FA), size: 26),
                                    )
                                  : _buildPersonalAvatar(),
                        ),
                      ),
                      if (selectedGroup != null)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.open_in_new_rounded, size: 10, color: Colors.black),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Participants Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name editing row
                      Row(
                        children: [
                          Expanded(
                            child: isEditable
                                ? TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: placeholder ?? 'Nome contesto...',
                                      hintStyle: const TextStyle(
                                        color: Colors.white38,
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
                                    onSubmitted: (_) => _saveEditedName(),
                                  )
                                : Text(
                                    titleText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          if (showEditButton && _isEditingName) ...[
                            const SizedBox(width: 4),
                            // Save button
                            IconButton(
                              icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                              onPressed: _saveEditedName,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Salva nome',
                            ),
                            const SizedBox(width: 8),
                            // Cancel edit button
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                              onPressed: () {
                                setState(() {
                                  _isEditingName = false;
                                  _nameController.text = titleText;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Annulla',
                            ),
                          ] else if (showEditButton) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 16),
                              onPressed: () {
                                setState(() {
                                  _isEditingName = true;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Modifica nome',
                            ),
                          ],
                          if (showEditButton && _selectedViewIds.length == 1 && _selectedGroupIds.isEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                              onPressed: () => _deleteView(_selectedViewIds.first, contextManager),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Elimina vista',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Participants Display
                      _buildParticipantsPreview(
                        selectedGroup: selectedGroup,
                        selectedView: selectedView,
                        viewGroups: viewGroups,
                        isPersonal: isPersonalActive,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Personal Expenses Toggle Pill (for groups and views)
          if (!isPersonalActive) ...[
            const SizedBox(height: 10),
            _buildPersonalExpensesToggle(contextManager, selectedGroup, selectedView),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalAvatar() {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user != null ? ProfileServiceCached().getAvatarUrl(user.id) : null;
    final imageProvider = AppImageHelper.getImageProvider(avatarUrl);

    if (imageProvider != null) {
      return Image(
        image: imageProvider,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFA855F7).withOpacity(0.2),
          child: const Icon(Icons.person_rounded, color: Color(0xFFC084FC), size: 26),
        ),
      );
    }

    return Container(
      color: const Color(0xFFA855F7).withOpacity(0.2),
      child: const Icon(Icons.person_rounded, color: Color(0xFFC084FC), size: 26),
    );
  }

  /// Build participants list for the selected context
  Widget _buildParticipantsPreview({
    ExpenseGroup? selectedGroup,
    ExpenseView? selectedView,
    required List<ExpenseGroup> viewGroups,
    required bool isPersonal,
  }) {
    if (isPersonal) {
      return const Text(
        'Solo tu • Spese personali',
        style: TextStyle(fontSize: 11.5, color: Colors.white54),
      );
    }

    if (selectedGroup != null) {
      return FutureBuilder<List<GroupMember>>(
        future: GroupServiceCached().getGroupMembers(selectedGroup.id),
        builder: (context, snapshot) {
          final members = snapshot.data ?? selectedGroup.members ?? [];
          if (members.isEmpty) {
            return const Text(
              'Nessun partecipante caricato',
              style: TextStyle(fontSize: 11, color: Colors.white38),
            );
          }

          final memberNames = members.map((m) => m.nickname ?? m.email?.split('@').first ?? 'Membro').take(4).join(', ');
          final extraCount = members.length > 4 ? ' +${members.length - 4}' : '';

          return Row(
            children: [
              const Icon(Icons.people_outline_rounded, size: 13, color: Colors.white38),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$memberNames$extraCount',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      );
    }

    if (selectedView != null || viewGroups.isNotEmpty) {
      return FutureBuilder<Map<String, List<GroupMember>>>(
        future: GroupServiceCached().getBulkGroupMembers(
          viewGroups.map((g) => g.id).toList(),
        ),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          if (viewGroups.isEmpty) {
            return const Text('Nessun gruppo nella vista', style: TextStyle(fontSize: 11, color: Colors.white38));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: viewGroups.take(3).map((g) {
              final members = data[g.id] ?? g.members ?? [];
              final names = members.map((m) => m.nickname ?? m.email?.split('@').first ?? 'Membro').take(3).join(', ');
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${g.name}: ${names.isNotEmpty ? names : "membri..."}',
                        style: const TextStyle(fontSize: 10.5, color: Colors.white60),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  /// Build toggle switch for including/excluding personal expenses in the context
  Widget _buildPersonalExpensesToggle(
    ContextManager contextManager,
    ExpenseGroup? selectedGroup,
    ExpenseView? selectedView,
  ) {
    bool includePersonal = false;
    VoidCallback onToggle;

    if (selectedGroup != null) {
      includePersonal = contextManager.getGroupIncludesPersonal(selectedGroup.id);
      onToggle = () async {
        await contextManager.toggleIncludePersonalForGroup(selectedGroup.id);
        setState(() {});
      };
    } else if (selectedView != null) {
      includePersonal = selectedView.includePersonal;
      onToggle = () async {
        await contextManager.toggleIncludePersonalForView(selectedView.id);
        setState(() {});
      };
    } else if (_isAllGroupsViewSelected(contextManager)) {
      includePersonal = _getAllGroupsIncludesPersonal(contextManager);
      onToggle = () => _toggleAllGroupsPersonal(contextManager);
    } else {
      includePersonal = contextManager.currentContext.includesPersonal;
      onToggle = () async {
        if (contextManager.currentContext.isGroup) {
          await contextManager.toggleIncludePersonalForCurrentGroup();
        } else if (contextManager.currentContext.isView) {
          await contextManager.toggleIncludePersonalForCurrentView();
        }
        setState(() {});
      };
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16161B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: includePersonal ? const Color(0xFFA855F7).withOpacity(0.4) : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_rounded,
            size: 16,
            color: includePersonal ? const Color(0xFFC084FC) : Colors.white38,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Includi spese personali',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  includePersonal
                      ? 'I pagamenti personali sono visibili in questo contesto'
                      : 'Mostra solo le spese condivise',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: includePersonal,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFFA855F7),
              activeTrackColor: const Color(0xFFA855F7).withOpacity(0.3),
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: Colors.white10,
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
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121215), // Deep Dark OLED
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12))),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              children: [
                // Handle bar
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

                // Dynamic Header
                _buildDynamicHeader(contextManager),

                Divider(height: 1, color: Colors.white.withOpacity(0.08)),

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
                            const Text(
                              'LE TUE VISTE',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white38,
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
                          const Text(
                            'I TUOI GRUPPI',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white38,
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
                                isSelected = false;
                                isRelatedFinal = false;
                                isLightlySelected = true;
                              } else if (_selectedViewIds.isNotEmpty &&
                                  isVisuallyHighlighted) {
                                isSelected = false;
                                isRelatedFinal = true;
                                isLightlySelected = false;
                              } else {
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

                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),

                // Bottoni in basso con Dark OLED surface (rimosso il bianco!)
                Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161A),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/groups/create');
                      },
                      icon: const Icon(Icons.group_add_rounded, size: 20),
                      label: const Text('Crea Nuovo Gruppo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 24,
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Bubble informativa (sopra il contenuto)
            if (shouldShowBubble)
              Positioned(
                top: 120,
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
      ),
    );
  }
}
