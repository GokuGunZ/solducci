import 'package:flutter/material.dart';
import 'package:solducci/views/hubs/feed_home_view.dart';
import 'package:solducci/views/hubs/economy_hub_view.dart';
import 'package:solducci/views/hubs/action_hub_view.dart';
import 'package:solducci/views/hubs/archive_hub_view.dart';
import 'package:solducci/widgets/constellation_menu.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/widgets/quick_add_item_modal.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/routine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

/// Shell widget that provides persistent bottom navigation bar
/// Uses IndexedStack to preserve state when switching tabs
class ShellWithNav extends StatefulWidget {
  const ShellWithNav({super.key});

  @override
  State<ShellWithNav> createState() => ShellWithNavState();

  /// Helper method to find and navigate to a specific tab
  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<ShellWithNavState>();
    state?.onItemTapped(index);
  }
}

class ShellWithNavState extends State<ShellWithNav> {
  int _selectedIndex = 0;
  final GlobalKey _fabKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  // List of tab pages
  static const List<Widget> _pages = [
    FeedHomeView(),
    EconomyHubView(),
    ActionHubView(),
    ArchiveHubView(),
  ];

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Color get _currentTabColor {
    switch (_selectedIndex) {
      case 0: return const Color(0xFF6366F1); // Feed - Indigo
      case 1: return const Color(0xFF10B981); // Economia - Emerald
      case 2: return const Color(0xFFF59E0B); // Azione - Amber
      case 3: return const Color(0xFF3B82F6); // Archivio - Blue
      default: return const Color(0xFF6366F1);
    }
  }

  Future<List<CollectionFolder>> _getFolders(String documentType) async {
    final contextManager = ContextManager();
    final docs = await DocumentService().getDocumentsForContext(contextManager.currentContext, documentType);
    return docs.map((d) => CollectionFolder(d.id, d.title)).toList();
  }

  Future<List<CollectionFolder>> _getRoutineCategories() async {
    // Ritorna le categorie per le routine. In futuro potrebbero venire dal DB.
    return [
      CollectionFolder('1', 'Mattina'),
      CollectionFolder('2', 'Sera'),
      CollectionFolder('3', 'Lavoro'),
      CollectionFolder('4', 'Fitness'),
    ];
  }

  List<ConstellationAction> _getCurrentTabActions(BuildContext context) {
    switch (_selectedIndex) {
      case 0: // Feed
        return [
          ConstellationAction(
            label: 'Gruppi',
            icon: Icons.group,
            onTap: () => context.push('/groups/management'),
          ),
          ConstellationAction(
            label: 'Importanti',
            icon: Icons.priority_high,
            onTap: () => context.push('/important'),
          ),
        ];
      case 1: // Economia
        return [
          ConstellationAction(
            label: 'Grafici',
            icon: Icons.pie_chart,
            onTap: () => context.push('/economy/charts'),
          ),
          ConstellationAction(
            label: 'Dispensa',
            icon: Icons.kitchen,
            onTap: () {
              QuickAddItemModal.show(
                context: context,
                title: 'Aggiungi in Dispensa',
                themeColor: const Color(0xFF10B981),
                foldersFuture: _getFolders('dispensa'),
                onAdd: (folderId, itemName) async {
                  try {
                    await DocumentService().addPantryItem(folderId, itemName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Aggiunto "$itemName" alla dispensa!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Errore: Impossibile aggiungere l\'elemento.')),
                      );
                    }
                  }
                },
              );
            },
          ),
          ConstellationAction(
            label: 'Lista Spesa',
            icon: Icons.shopping_cart,
            onTap: () {
              QuickAddItemModal.show(
                context: context,
                title: 'Nuovo Elemento Spesa',
                themeColor: const Color(0xFF10B981),
                foldersFuture: _getFolders('shopping_list'),
                onAdd: (folderId, itemName) async {
                  try {
                    await DocumentService().addShoppingListItem(folderId, itemName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Aggiunto "$itemName" alla lista!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Errore nell\'aggiunta.')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ];
      case 2: // Azione
        return [
          ConstellationAction(
            label: 'Routine',
            icon: Icons.repeat,
            onTap: () {
              QuickAddItemModal.show(
                context: context,
                title: 'Nuova Routine',
                themeColor: const Color(0xFFF59E0B),
                foldersFuture: _getRoutineCategories(),
                onAdd: (folderId, itemName) async {
                  try {
                    // Categoria come descrizione per ora
                    final categoryName = ['Mattina', 'Sera', 'Lavoro', 'Fitness'].elementAtOrNull(int.tryParse(folderId) ?? 0) ?? 'Generale';
                    final contextManager = ContextManager();
                    final currentContext = contextManager.currentContext;
                    
                    final newRoutine = RoutineTemplate(
                      id: '', // Generated by Supabase
                      userId: Supabase.instance.client.auth.currentUser?.id ?? '', 
                      groupId: currentContext.isGroup ? currentContext.groupId : null,
                      name: itemName,
                      description: 'Categoria: $categoryName',
                      isActive: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    
                    await TimeManagementService().createRoutineTemplate(newRoutine, [], []);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Creata routine "$itemName"!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Errore: Impossibile creare routine.')),
                      );
                    }
                  }
                },
              );
            },
          ),
          ConstellationAction(
            label: 'Focus',
            icon: Icons.timer,
            onTap: () => context.push('/focus'),
          ),
          ConstellationAction(
            label: 'Abitudini',
            icon: Icons.check_circle,
            onTap: () => context.push('/habits'),
          ),
        ];
      case 3: // Archivio
        return [
          ConstellationAction(
            label: 'Asterisco',
            icon: Icons.star,
            onTap: () {
              QuickAddItemModal.show(
                context: context,
                title: 'Nuovo Asterisco',
                themeColor: const Color(0xFF3B82F6),
                foldersFuture: _getFolders('asterisk'),
                onAdd: (folderId, itemName) async {
                  try {
                    await DocumentService().addAsteriskItem(folderId, itemName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Creato asterisco "$itemName"!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Errore.')),
                      );
                    }
                  }
                },
              );
            },
          ),
          ConstellationAction(
            label: 'Risorsa',
            icon: Icons.book,
            onTap: () {
              QuickAddItemModal.show(
                context: context,
                title: 'Nuova Risorsa',
                themeColor: const Color(0xFF3B82F6),
                foldersFuture: _getFolders('resource_list'),
                onAdd: (folderId, itemName) async {
                  try {
                    await DocumentService().addResourceItem(folderId, itemName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Creata risorsa "$itemName"!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Errore.')),
                      );
                    }
                  }
                },
              );
            },
          ),
          ConstellationAction(
            label: 'Note',
            icon: Icons.note_add,
            onTap: () {
              QuickAddItemModal.show(
                context: context,
                title: 'Nuova Nota',
                themeColor: const Color(0xFF3B82F6),
                foldersFuture: _getFolders('note'),
                onAdd: (folderId, itemName) async {
                  try {
                    await DocumentService().addNoteItem(folderId, itemName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Creata nota "$itemName"!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Errore.')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: () => _showOmniMenu(context),
        backgroundColor: const Color(0xFF6366F1), // Forza un colore fisso per consistenza
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF09090B),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 60,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_filled, 'Feed'),
            _buildNavItem(1, Icons.account_balance_wallet, 'Economia'),
            const SizedBox(width: 48), // Spazio per il FAB
            _buildNavItem(2, Icons.bolt, 'Azione'),
            _buildNavItem(3, Icons.inventory_2, 'Archivio'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? _currentTabColor : Colors.white30; // Use tab specific color if selected
    
    return InkWell(
      onTap: () => onItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  void _openExpenseForm(BuildContext context) {
    final form = ExpenseForm.empty();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text("Nuova Spesa"),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: form.getExpenseView(context),
            ),
          ),
        ),
      ),
    );
  }

  void _showOmniMenu(BuildContext context) {
    if (_overlayEntry != null) return; // Prevent double taps

    final renderBox = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return ConstellationMenuOverlay(
          fabOffset: offset,
          fabSize: size,
          tabColor: _currentTabColor,
          outerActions: _getCurrentTabActions(context),
          onClose: () {
            _overlayEntry?.remove();
            _overlayEntry = null;
          },
          onSpesa: () => _openExpenseForm(context),
          onTask: () => context.push('/space/tasks'),
          onEvento: () => context.push('/space/time_management'),
          onNota: () => context.push('/space/notes'),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }
}
