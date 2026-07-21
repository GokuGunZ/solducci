import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/core/templates/canvas_template_registry.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/features/space/controllers/canvas_tree_controller.dart';
import 'package:solducci/features/space/services/canvas_sync_service.dart';
import 'package:solducci/features/space/repositories/canvas_local_repository.dart';
import 'package:solducci/features/space/widgets/nodes/markdown_node_widget.dart';
import 'package:solducci/features/space/widgets/omni_radial_menu.dart';
import 'package:solducci/features/space/widgets/manila_folder_painter.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/core/onboarding/services/feature_onboarding_service.dart';
import 'package:solducci/core/onboarding/models/onboarding_config.dart';
import 'package:solducci/core/onboarding/views/feature_onboarding_wizard.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InfiniteCanvasView extends StatefulWidget {
  final String? groupId;
  final String? userId;

  const InfiniteCanvasView({super.key, this.groupId, this.userId});

  @override
  State<InfiniteCanvasView> createState() => _InfiniteCanvasViewState();
}

class _InfiniteCanvasViewState extends State<InfiniteCanvasView> {
  late final CanvasTreeController _controller;
  final ScrollController _breadcrumbsScrollController = ScrollController();
  bool _isInitialized = false;
  double _canvasScale = 1.0;
  int _pointerCount = 0;
  String? _selectionMode; // 'move' or 'delete'
  Set<String> _selectedNodeIds = {};
  bool _showWizard = false;

  @override
  void initState() {
    super.initState();
    _initCanvas();
  }

  Future<void> _initCanvas() async {
    await CanvasSyncService().initialize();
    
    // Esegui la Cache Eviction policy (pulisci payload più vecchi di 90 giorni)
    await CanvasLocalRepository().clearEvictedPayloads();
    
    String? gId = widget.groupId;
    String? uId = widget.userId;
    
    if (gId == null && uId == null) {
      final ctx = ContextManager().currentContext;
      if (ctx.isGroup) {
        gId = ctx.groupId;
      } else {
        uId = Supabase.instance.client.auth.currentUser?.id;
      }
    }
    
    _controller = CanvasTreeController(groupId: gId, userId: uId);
    _controller.addListener(_onTreeUpdated);
    
    // Start sync and wait for initial skeleton fetch
    await CanvasSyncService().startSync();
    
    // Check if user has onboarded
    final hasOnboarded = await FeatureOnboardingService().hasOnboarded('infinite_canvas');
    
    // Wait for the UI to be ready
    if (!mounted) return;

    final userNodes = _controller.allNodes.where((n) {
      if (_controller.groupId != null) return n.groupId == _controller.groupId;
      return n.userId == _controller.userId && n.groupId == null;
    });

    if (!hasOnboarded && userNodes.isEmpty) {
      setState(() {
        _showWizard = true;
        _isInitialized = true;
      });
    } else {
      setState(() {
        _showWizard = false;
        _isInitialized = true;
      });
    }
  }

  void _onTreeUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.removeListener(_onTreeUpdated);
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _showOmniAddSheet(String? parentId) async {
    final TextEditingController titleController = TextEditingController();
    String selectedType = 'markdown'; // default to markdown

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aggiungi al Canvas', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Type Selectors
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedType = 'markdown'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedType == 'markdown' ? const Color(0xFF6366F1).withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selectedType == 'markdown' ? const Color(0xFF6366F1) : Colors.white10),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.edit_note, color: selectedType == 'markdown' ? const Color(0xFF6366F1) : Colors.white54, size: 32),
                                const SizedBox(height: 8),
                                Text('Appunto', style: TextStyle(color: selectedType == 'markdown' ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedType = 'folder'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedType == 'folder' ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selectedType == 'folder' ? const Color(0xFF10B981) : Colors.white10),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.folder, color: selectedType == 'folder' ? const Color(0xFF10B981) : Colors.white54, size: 32),
                                const SizedBox(height: 8),
                                Text('Cartella', style: TextStyle(color: selectedType == 'folder' ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedType = 'bookmark'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedType == 'bookmark' ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selectedType == 'bookmark' ? const Color(0xFFF59E0B) : Colors.white10),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.bookmark, color: selectedType == 'bookmark' ? const Color(0xFFF59E0B) : Colors.white54, size: 32),
                                const SizedBox(height: 8),
                                Text('Bookmark', style: TextStyle(color: selectedType == 'bookmark' ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Text('Posizione: ${parentId == null ? 'Root' : _controller.getNode(parentId)?.title ?? 'Sconosciuta'}', style: const TextStyle(color: Colors.white70)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // TODO: Apri selettore posizione completo
                        },
                        child: const Text('Cambia'),
                      )
                    ]
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Title input
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: selectedType == 'folder' ? 'Nome della cartella...' : 'Titolo dell\'appunto...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _controller.createNode(
                          title: val.trim(),
                          type: selectedType,
                          parentId: parentId,
                          payloadText: '',
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedType == 'folder' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isNotEmpty) {
                          _controller.createNode(
                            title: titleController.text.trim(),
                            type: selectedType,
                            parentId: parentId,
                            payloadText: '',
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Crea', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Conferma Eliminazione', style: TextStyle(color: Colors.white)),
        content: Text('Vuoi davvero eliminare ${_selectedNodeIds.length} elementi?\nQuesta azione non è reversibile.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              for (final id in _selectedNodeIds) {
                _controller.deleteNode(id);
              }
              setState(() {
                _selectionMode = null;
                _selectedNodeIds.clear();
              });
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMoveModal() {
    String selectedTab = 'Tree';
    String? selectedTargetGroupId = _controller.groupId;
    String? selectedTargetFolderId;
    bool showAllSpaces = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            List<String?> availableGroupIds = [];
            if (showAllSpaces) {
              availableGroupIds.add(null);
              availableGroupIds.addAll(GroupServiceCached().getAllCachedGroups().map((g) => g.id));
            } else {
              availableGroupIds = _controller.allNodes.map((n) => n.groupId).toSet().toList();
              if (!availableGroupIds.contains(null)) availableGroupIds.insert(0, null);
              if (!availableGroupIds.contains(selectedTargetGroupId)) availableGroupIds.add(selectedTargetGroupId);
            }

            Color getTabColor(String tab) {
              switch (tab) {
                case 'Bookmarks': return const Color(0xFFFBBF24); // Amber
                case 'Recenti': return const Color(0xFF38BDF8); // Cyan
                case 'Nuove': return const Color(0xFF34D399); // Emerald
                case 'Tree': return const Color(0xFF818CF8); // Indigo
                default: return Colors.white;
              }
            }

            List<Widget> buildTree(String? parentId, int depth) {
              final children = _controller.allNodes.where((n) => n.type == 'folder' && n.groupId == selectedTargetGroupId && n.parentId == parentId).toList();
              List<Widget> widgets = [];
              for (var folder in children) {
                final isSelectedToMove = _selectedNodeIds.contains(folder.id);
                final isTarget = selectedTargetFolderId == folder.id;
                widgets.add(
                  Container(
                    color: isTarget ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.only(left: 16.0 + (depth * 24.0), right: 16.0),
                      leading: Icon(isTarget ? Icons.folder_open : Icons.folder, color: isTarget ? Colors.white : getTabColor('Tree').withValues(alpha: 0.8)),
                      title: Text(folder.title, style: TextStyle(color: isSelectedToMove ? Colors.white30 : (isTarget ? Colors.white : Colors.white))),
                      enabled: !isSelectedToMove,
                      onTap: isSelectedToMove ? null : () {
                        setModalState(() {
                          selectedTargetFolderId = folder.id;
                        });
                      },
                    ),
                  )
                );
                widgets.addAll(buildTree(folder.id, depth + 1));
              }
              return widgets;
            }

            List<CanvasNode> getTabFolders() {
              final folders = _controller.allNodes.where((n) => n.type == 'folder' && n.groupId == selectedTargetGroupId).toList();

              switch (selectedTab) {
                case 'Recenti':
                  folders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                  return folders.take(15).toList();
                case 'Nuove':
                  folders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  return folders.take(15).toList();
                case 'Bookmarks':
                  return folders.where((n) => n.metadata['isBookmarked'] == true).toList();
                default:
                  return [];
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Color(0xFF09090B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sposta nodi', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            if (!showAllSpaces)
                              TextButton(
                                onPressed: () {
                                  setModalState(() => showAllSpaces = true);
                                },
                                child: const Text('Altri spazi', style: TextStyle(color: Colors.amber)),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                              onPressed: () => _executeMove(selectedTargetFolderId, ctx, selectedTargetGroupId),
                              child: const Text('Conferma', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: availableGroupIds.map((gId) {
                        final isSelected = selectedTargetGroupId == gId;
                        String label = 'Spazio Personale';
                        if (gId != null) {
                          final groupName = GroupServiceCached().getGroupName(gId);
                          label = groupName != null ? 'Gruppo: $groupName' : 'Gruppo: ${gId.substring(0, 8)}';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: Colors.amber.withValues(alpha: 0.2),
                            backgroundColor: const Color(0xFF1E1E2C),
                            labelStyle: TextStyle(color: isSelected ? Colors.amber : Colors.white70),
                            avatar: Icon(Icons.home, size: 18, color: isSelected ? Colors.amber : Colors.white70),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            showCheckmark: false,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedTargetGroupId = gId;
                                  selectedTargetFolderId = null;
                                  selectedTab = 'Tree';
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131A), // Darker recessed background
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                      ),
                      child: Row(
                        children: ['Bookmarks', 'Recenti', 'Nuove', 'Tree'].map((tab) {
                          final isSelected = selectedTab == tab;
                          final tabColor = getTabColor(tab);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedTab = tab),
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF2B2B36) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSelected 
                                      ? [BoxShadow(color: tabColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 1))]
                                      : [],
                                  border: Border.all(
                                    color: isSelected ? tabColor.withValues(alpha: 0.3) : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  style: TextStyle(
                                    color: isSelected ? tabColor : Colors.white38, 
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, 
                                    fontSize: 13,
                                    fontFamily: 'Inter', // Assuming Inter or similar is used, falls back gracefully
                                  ),
                                  child: Text(tab),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            getTabColor(selectedTab).withValues(alpha: 0.08),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.25, 1.0],
                        ),
                      ),
                      child: selectedTab == 'Tree' 
                        ? ListView(
                            children: [
                              Container(
                                color: selectedTargetFolderId == null ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                                child: ListTile(
                                  leading: Icon(selectedTargetFolderId == null ? Icons.home : Icons.home_outlined, color: selectedTargetFolderId == null ? Colors.white : getTabColor('Tree').withValues(alpha: 0.8)),
                                  title: Text('Root (${selectedTargetGroupId == null ? "Spazio Personale" : "Gruppo"})', style: TextStyle(color: selectedTargetFolderId == null ? Colors.white : Colors.white, fontWeight: FontWeight.bold)),
                                  onTap: () {
                                    setModalState(() => selectedTargetFolderId = null);
                                  },
                                ),
                              ),
                              const Divider(color: Colors.white10, height: 1),
                              ...buildTree(null, 0),
                            ],
                          )
                        : Builder(
                            builder: (ctx) {
                              final tabFolders = getTabFolders();
                              if (tabFolders.isEmpty) {
                                return Center(
                                  child: Text('Nessun elemento in $selectedTab', style: const TextStyle(color: Colors.white54)),
                                );
                              }
                              return ListView.builder(
                                itemCount: tabFolders.length,
                                itemBuilder: (context, index) {
                                  final folder = tabFolders[index];
                                  final isSelectedToMove = _selectedNodeIds.contains(folder.id);
                                  final isTarget = selectedTargetFolderId == folder.id;
                                  return Container(
                                    color: isTarget ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                                    child: ListTile(
                                      leading: Icon(isTarget ? Icons.folder_open : Icons.folder, color: isTarget ? Colors.white : getTabColor(selectedTab).withValues(alpha: 0.8)),
                                      title: Text(folder.title, style: TextStyle(color: isSelectedToMove ? Colors.white30 : (isTarget ? Colors.white : Colors.white))),
                                      subtitle: Text(
                                        selectedTab == 'Nuove' 
                                            ? 'Creata il ${folder.createdAt.day}/${folder.createdAt.month}/${folder.createdAt.year}' 
                                            : 'Modificata il ${folder.updatedAt.day}/${folder.updatedAt.month}/${folder.updatedAt.year}', 
                                        style: const TextStyle(color: Colors.white38, fontSize: 12)
                                      ),
                                      enabled: !isSelectedToMove,
                                      onTap: isSelectedToMove ? null : () {
                                        setModalState(() {
                                          selectedTargetFolderId = folder.id;
                                        });
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _executeMove(String? targetParentId, BuildContext modalContext, String? targetGroupId) {
    Navigator.pop(modalContext);
    for (final id in _selectedNodeIds) {
      _controller.moveNode(id, targetParentId, targetGroupId: targetGroupId);
    }
    setState(() {
      _selectionMode = null;
      _selectedNodeIds.clear();
    });
  }

  void _showLayoutSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Impostazioni Layout', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Text('Dimensione Testo Appunti', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Slider(
                      value: _controller.markdownFontSize,
                      min: 10.0,
                      max: 24.0,
                      divisions: 14,
                      activeColor: const Color(0xFF6366F1),
                      label: _controller.markdownFontSize.round().toString(),
                      onChanged: (val) {
                        setStateModal(() {
                          _controller.updateMarkdownFontSize(val);
                        });
                      },
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    const Text('Mostra voci di menù', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SwitchListTile(
                      title: const Text('Bookmarks', style: TextStyle(color: Colors.white)),
                      value: _controller.showBookmarksMenu,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (val) {
                        setStateModal(() => _controller.updateMenuVisibility(bookmarks: val));
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Genera Template Test', style: TextStyle(color: Colors.white)),
                      value: _controller.showTemplateMenu,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (val) {
                        setStateModal(() => _controller.updateMenuVisibility(template: val));
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Reimposta viste', style: TextStyle(color: Colors.white)),
                      value: _controller.showRefreshMenu,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (val) {
                        setStateModal(() => _controller.updateMenuVisibility(refresh: val));
                      },
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    const Text('Sviluppo', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ListTile(
                      title: const Text('Ripristina Wizard (Reset)', style: TextStyle(color: Colors.redAccent)),
                      onTap: () async {
                        await FeatureOnboardingService().resetOnboarding('infinite_canvas');
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Onboarding ripristinato. Ricarica la vista!')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            }
          ),
        );
      }
    );
  }

  Widget _buildSubNavbar() {
    final path = _controller.navigationPath;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Breadcrumbs
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_breadcrumbsScrollController.hasClients) {
                    _breadcrumbsScrollController.jumpTo(_breadcrumbsScrollController.position.maxScrollExtent);
                  }
                });
                return SingleChildScrollView(
                  controller: _breadcrumbsScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _controller.jumpToFolder(null),
                        child: const Text('Root', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      ),
                      for (var node in path) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('/', style: TextStyle(color: Colors.white30)),
                        ),
                        GestureDetector(
                          onTap: () => _controller.jumpToFolder(node.id),
                          onLongPress: node.id == _controller.currentCanvasRootId ? () {
                            final textController = TextEditingController(text: node.title);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E2C),
                                title: const Text('Rinomina cartella', style: TextStyle(color: Colors.white)),
                                content: TextField(
                                  controller: textController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                                  ),
                                  autofocus: true,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annulla', style: TextStyle(color: Colors.white70)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _controller.updateNodeTitle(node, textController.text);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Salva', style: TextStyle(color: Color(0xFF6366F1))),
                                  ),
                                ],
                              ),
                            );
                          } : null,
                          child: Text(node.title, style: TextStyle(color: node.id == _controller.currentCanvasRootId ? const Color(0xFF6366F1) : Colors.white70, fontWeight: node.id == _controller.currentCanvasRootId ? FontWeight.bold : FontWeight.normal)),
                        ),
                      ]
                    ],
                  ),
                );
              }
            ),
          ),
          // Depth controller
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18, color: Colors.white54),
                onPressed: () => _controller.setCurrentDepthLimit(_controller.currentDepthLimit - 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text('Livelli: ${_controller.currentDepthLimit}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, size: 18, color: Colors.white54),
                onPressed: () => _controller.setCurrentDepthLimit(_controller.currentDepthLimit + 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (_showWizard) {
      return FeatureOnboardingWizard(
        config: OnboardingConfig(
          featureKey: 'infinite_canvas',
          presentationTitle: 'Il tuo Spazio Mentale Infinito',
          presentationSubtitle: 'Appunti liquidi, gerarchie infinite, zero limiti.\nDai forma al tuo pensiero.',
          presentationImageAssetPath: 'assets/images/onboarding/canvas_boilerplate_preview.jpg',
          infoModalTitle: 'Cos\'è l\'Infinite Canvas?',
          infoModalContent: 'L\'Infinite Canvas è uno spazio di lavoro 3D non lineare. Puoi creare cartelle e note annidate all\'infinito. Il Boilerplate crea un set di note iniziali che ti fungeranno da tutorial pratico direttamente sul canvas.',
          options: [
            const OnboardingOption(
              id: 'boilerplate',
              title: 'Spazio Guidato',
              description: 'Inizia con un template e note esplicative che ti guideranno.',
              heroImageAssetPath: 'assets/images/onboarding/canvas_boilerplate_preview.jpg',
              isDefault: true,
            ),
            const OnboardingOption(
              id: 'empty',
              title: 'Canvas Vuoto',
              description: 'Parti da zero, un universo oscuro tutto da creare.',
              heroImageAssetPath: 'assets/images/onboarding/canvas_empty_preview.jpg',
            ),
          ],
        ),
        onComplete: (selectedOption) async {
          if (selectedOption == 'boilerplate') {
            await _controller.injectTemplate(CanvasTemplateRegistry.welcomeCanvas);
          }
          await FeatureOnboardingService().markAsOnboarded('infinite_canvas');
          if (mounted) {
            setState(() {
              _showWizard = false;
            });
          }
        },
      );
    }

    return PopScope(
      canPop: _controller.currentCanvasRootId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        final currentRootId = _controller.currentCanvasRootId;
        if (currentRootId != null) {
          final currentNode = _controller.getNode(currentRootId);
          _controller.jumpToFolder(currentNode?.parentId);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF09090B), // OLED black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Infinite Canvas', style: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold)),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectionMode != null) ...[
                Text('${_selectedNodeIds.length} selezionati', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (_selectionMode == 'move')
                  IconButton(
                    icon: const Icon(Icons.drive_file_move, size: 20, color: Colors.blueAccent),
                    tooltip: 'Conferma Spostamento',
                    onPressed: _selectedNodeIds.isEmpty ? null : _showMoveModal,
                  )
                else if (_selectionMode == 'delete')
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    tooltip: 'Conferma Eliminazione',
                    onPressed: _selectedNodeIds.isEmpty ? null : _showDeleteModal,
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.white30),
                  tooltip: 'Annulla selezione',
                  onPressed: () {
                    setState(() {
                      _selectionMode = null;
                      _selectedNodeIds.clear();
                    });
                  },
                ),
              ] else ...[
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF6366F1)),
                  tooltip: 'Opzioni',
                  color: const Color(0xFF1E1E2C),
                  onSelected: (value) {
                    if (value == 'move' || value == 'delete') {
                      setState(() {
                        _selectionMode = value;
                      });
                    } else if (value == 'bookmarks') {
                      // TODO: Apri modal bookmarks
                    } else if (value == 'refresh') {
                      _controller.resetAllOverrides();
                    } else if (value == 'template') {
                      _controller.injectTemplate(CanvasTemplateRegistry.welcomeCanvas);
                    } else if (value == 'settings') {
                      _showLayoutSettingsModal();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(value: 'move', child: Text('Sposta', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Elimina', style: TextStyle(color: Colors.redAccent))),
                    const PopupMenuDivider(),
                    if (_controller.showBookmarksMenu)
                      const PopupMenuItem(value: 'bookmarks', child: Text('Bookmarks', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'settings', child: Text('Impostazioni layout', style: TextStyle(color: Colors.white))),
                    const PopupMenuDivider(),
                    if (_controller.showRefreshMenu)
                      const PopupMenuItem(value: 'refresh', child: Text('Reimposta viste', style: TextStyle(color: Colors.white))),
                    if (_controller.showTemplateMenu)
                      const PopupMenuItem(value: 'template', child: Text('Genera Template Test', style: TextStyle(color: Colors.white))),
                  ],
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSubNavbar(),
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                if (details.data == 'omni-plus') {
                  _showOmniAddSheet(_controller.currentCanvasRootId);
                }
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                final isNested = _controller.currentCanvasRootId != null;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isHovering ? const Color(0xFF6366F1).withValues(alpha: 0.05) : Colors.transparent,
                    border: isNested 
                        ? Border(
                            left: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 2),
                            right: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 2),
                            bottom: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 2),
                          )
                        : null,
                    boxShadow: isNested 
                        ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.05), blurRadius: 40, spreadRadius: 0)] 
                        : null,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: GestureDetector(
                      onScaleStart: (details) {
                        setState(() {
                          _pointerCount = details.pointerCount;
                        });
                      },
                      onScaleUpdate: (details) {
                        if (details.pointerCount >= 2) {
                          setState(() {
                            _pointerCount = details.pointerCount;
                            _canvasScale = details.scale;
                          });
                        }
                      },
                      onScaleEnd: (details) {
                        // Pinch-out (zoom out) to go back to parent folder
                        if (_canvasScale < 0.8) {
                          final currentRootId = _controller.currentCanvasRootId;
                          if (currentRootId != null) {
                            final currentNode = _controller.getNode(currentRootId);
                            _controller.jumpToFolder(currentNode?.parentId);
                          }
                        }
                        setState(() {
                          _canvasScale = 1.0;
                          _pointerCount = 0;
                        });
                      },
                      child: Transform.scale(
                        scale: _canvasScale.clamp(0.5, 1.0),
                        child: CustomScrollView(
                          physics: _pointerCount >= 2 ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                          key: ValueKey(_controller.currentCanvasRootId ?? 'root'),
                      // Viewport-aware overscanning
                      cacheExtent: 1500, // Pre-render 1500px outside viewport
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final node = _controller.currentCanvasNodes[index];
                                if (node.type == 'folder') {
                                  return _FolderNodeWidget(
                                    node: node,
                                    controller: _controller,
                                    depth: 0,
                                    forceExpandLevelsRemaining: _controller.currentDepthLimit,
                                    onAddChild: _showOmniAddSheet,
                                    selectionMode: _selectionMode,
                                    isNodeSelected: (id) => _selectedNodeIds.contains(id),
                                    onNodeSelected: (id, selected) {
                                      setState(() {
                                        if (selected) _selectedNodeIds.add(id);
                                        else _selectedNodeIds.remove(id);
                                      });
                                    },
                                  );
                                } else if (node.type == 'markdown') {
                                  final child = MarkdownNodeWidget(
                                    node: node,
                                    controller: _controller,
                                    depth: 0,
                                    limit: _controller.currentDepthLimit,
                                    selectionMode: _selectionMode,
                                    isSelected: _selectedNodeIds.contains(node.id),
                                    onSelect: (selected) {
                                      setState(() {
                                        if (selected) _selectedNodeIds.add(node.id);
                                        else _selectedNodeIds.remove(node.id);
                                      });
                                    },
                                  );

                                  return child;
                                }
                                return const SizedBox.shrink();
                              },
                              childCount: _controller.currentCanvasNodes.length,
                            ),
                          ),
                        ),
                        // Spazio vuoto dinamico per la tastiera e l'overscroll
                        SliverToBoxAdapter(
                          child: SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 200),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: OmniRadialMenu(
        onCreateNode: (type) async {
          // If the user taps the radial button, we create the node in the current canvas root
          // If it's a markdown, we should ideally trigger it to be editing.
          final newId = await _controller.createNodeAndReturnId(
            title: '', // Start empty as requested
            type: type,
            parentId: _controller.currentCanvasRootId,
            payloadText: '',
          );
          
          if (type == 'markdown') {
            // TODO: Ensure it opens in edit mode automatically.
            // A simple way is to dispatch an event or rely on focus, but for now we just create it.
          }
        },
      ),
      ),
    );
  }
}

typedef AddChildCallback = void Function(String parentId);

class _FolderNodeWidget extends StatefulWidget {
  final CanvasNode node;
  final CanvasTreeController controller;
  final int depth;
  final int forceExpandLevelsRemaining;
  final AddChildCallback onAddChild;
  final String? selectionMode;
  final bool Function(String) isNodeSelected;
  final void Function(String, bool) onNodeSelected;

  const _FolderNodeWidget({
    Key? key,
    required this.node,
    required this.controller,
    required this.depth,
    required this.forceExpandLevelsRemaining,
    required this.onAddChild,
    this.selectionMode,
    required this.isNodeSelected,
    required this.onNodeSelected,
  }) : super(key: key);

  @override
  State<_FolderNodeWidget> createState() => _FolderNodeWidgetState();
}

class _FolderNodeWidgetState extends State<_FolderNodeWidget> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final double leftPadding = widget.depth == 0 ? 0.0 : 6.0;
    final double rightPadding = widget.depth == 0 ? 0.0 : 6.0;
    
    final bool? explicitState = widget.controller.getFolderState(widget.node.id);
    final int? localLimitOverride = widget.controller.getDepthLimit(widget.node.id);
    
    final int effectiveLimit = localLimitOverride ?? widget.forceExpandLevelsRemaining;
    
    // Specific state overrides parent inherited state
    final bool visuallyExpanded = explicitState ?? (effectiveLimit > 1);
    
    int nextForceLevels = 0;
    if (visuallyExpanded) {
      nextForceLevels = effectiveLimit > 0 ? effectiveLimit - 1 : 0;
      // If manually expanded but effectiveLimit was 1 or 0, ensure files inside render in extended mode
      if (explicitState == true && nextForceLevels == 0) {
        nextForceLevels = 1;
      }
    }

    final children = visuallyExpanded ? widget.controller.getChildren(widget.node.id) : <CanvasNode>[];

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, right: rightPadding, bottom: 8.0),
      child: GestureDetector(
        onScaleUpdate: (details) {
          if (details.pointerCount >= 2) {
            setState(() {
              _scale = details.scale.clamp(0.8, 1.5);
            });
          }
        },
        onScaleEnd: (details) {
          if (_scale > 1.2) {
            widget.controller.enterFolder(widget.node.id);
          }
          setState(() {
            _scale = 1.0;
          });
        },
        child: Transform.scale(
          scale: _scale,
          child: DragTarget<Map<String, String>>(
            onAcceptWithDetails: (details) async {
              final type = details.data['omni-type'];
              if (type != null) {
                await widget.controller.createNodeAndReturnId(
                  title: '',
                  type: type,
                  parentId: widget.node.id,
                );
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              final isSelected = widget.isNodeSelected(widget.node.id);
              Color folderColor = isHovering ? const Color(0xFF4338CA).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04);
              if (widget.selectionMode != null && isSelected) {
                if (widget.selectionMode == 'move') folderColor = const Color(0xFF3B82F6).withValues(alpha: 0.4);
                if (widget.selectionMode == 'delete') folderColor = const Color(0xFFEF4444).withValues(alpha: 0.4);
              }
              
              return GestureDetector(
                onTap: widget.selectionMode != null ? () {
                  widget.onNodeSelected(widget.node.id, !isSelected);
                } : null,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: ManilaFolderPainter(
                        baseColor: folderColor,
                        isOpen: visuallyExpanded,
                      ),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: visuallyExpanded ? 64 : 96),
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: SizedBox(
                              width: constraints.maxWidth * 0.6 - 32, // 60% of width minus horizontal padding
                              child: Row(
                                children: [
                                  if (widget.selectionMode == null)
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => widget.controller.toggleExpand(widget.node.id, visuallyExpanded),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          // We use SingleChildScrollView to allow natural scroll if marquee is not fully implemented
                                          // A true marquee would use an animation controller.
                                          child: Text(
                                            widget.node.title, 
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                          widget.node.title, 
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }
                      ),
                        // Inner content
                        if (visuallyExpanded && children.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children.map((childNode) {
                                if (childNode.type == 'folder') {
                                  return _FolderNodeWidget(
                                    node: childNode,
                                    controller: widget.controller,
                                    depth: widget.depth + 1,
                                    forceExpandLevelsRemaining: nextForceLevels,
                                    onAddChild: widget.onAddChild,
                                    selectionMode: widget.selectionMode,
                                    isNodeSelected: widget.isNodeSelected,
                                    onNodeSelected: widget.onNodeSelected,
                                  );
                                } else if (childNode.type == 'markdown') {
                                  return MarkdownNodeWidget(
                                    node: childNode,
                                    controller: widget.controller,
                                    depth: widget.depth + 1,
                                    limit: nextForceLevels,
                                    selectionMode: widget.selectionMode,
                                    isSelected: widget.isNodeSelected(childNode.id),
                                    onSelect: (selected) {
                                      widget.onNodeSelected(childNode.id, selected);
                                    },
                                  );
                                }
                                return const SizedBox.shrink();
                              }).toList(),
                            ),
                          ),
                        ] else if (visuallyExpanded) ...[
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Text('Cartella vuota', style: TextStyle(color: Colors.white30, fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Bookmarks in the top-right empty space (40% width area)
                Positioned(
                  top: 0,
                  right: 16,
                  child: SizedBox(
                    height: 32, // Same height as header
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Zoom-in Tab
                        Container(
                          height: 28,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.8),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                          ),
                          child: InkWell(
                            onTap: () => widget.controller.enterFolder(widget.node.id),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.zoom_in_map, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        // Depth Limits Tab
                        Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.8),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => widget.controller.setDepthLimit(widget.node.id, effectiveLimit - 1),
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 8, right: 4), 
                                  child: Icon(Icons.remove, size: 14, color: Colors.white70)
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text('$effectiveLimit', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              InkWell(
                                onTap: () => widget.controller.setDepthLimit(widget.node.id, effectiveLimit + 1),
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 4, right: 8), 
                                  child: Icon(Icons.add, size: 14, color: Colors.white70)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        ),
      ),
      ),
    );
  }
}
