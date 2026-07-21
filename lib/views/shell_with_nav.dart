import 'package:flutter/material.dart';
import 'package:solducci/views/hubs/feed_home_view.dart';
import 'package:solducci/views/hubs/economy_hub_view.dart';
import 'package:solducci/views/hubs/action_hub_view.dart';
import 'package:solducci/views/hubs/archive_hub_view.dart';
import 'package:solducci/features/space/views/space_home_view.dart';
import 'package:solducci/widgets/constellation_menu.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/widgets/quick_add/pantry_quick_add_sheet.dart';
import 'package:solducci/widgets/quick_add/shopping_quick_add_sheet.dart';
import 'package:solducci/widgets/quick_add/routine_quick_add_sheet.dart';
import 'package:solducci/widgets/quick_add/resource_quick_add_sheet.dart';
import 'package:solducci/widgets/quick_add/simple_content_quick_add_sheet.dart';
import 'package:solducci/widgets/quick_add/base_quick_add_sheet.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/routine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  final GlobalKey<ConstellationMenuOverlayState> _overlayKey = GlobalKey();
  final ValueNotifier<Offset?> _dragNotifier = ValueNotifier(null);
  OverlayEntry? _overlayEntry;

  // List of tab pages
  static const List<Widget> _pages = [
    FeedHomeView(),
    EconomyHubView(),
    ActionHubView(),
    ArchiveHubView(),
    SpaceHomeView(),
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
      case 3: return const Color(0xFF3B82F6); // Spazio - Blue
      case 4: return const Color(0xFF8B5CF6); // Lab - Purple
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
              PantryQuickAddForm.show(
                context: context,
                foldersFuture: _getFolders('dispensa'),
                onAdded: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Prodotto aggiunto alla dispensa!')),
                  );
                },
              );
            },
          ),
          ConstellationAction(
            label: 'Lista Spesa',
            icon: Icons.shopping_cart,
            onTap: () {
              ShoppingQuickAddForm.show(
                context: context,
                foldersFuture: _getFolders('shopping_list'),
                onAdded: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Prodotto aggiunto alla spesa!')),
                  );
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
              RoutineQuickAddForm.show(
                context: context,
                foldersFuture: _getRoutineCategories(),
                onAdded: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nuova routine creata con successo!')),
                  );
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
      case 3: // Spazio
        return [
          ConstellationAction(
            label: 'Asterisco',
            icon: Icons.star,
            onTap: () {
              SimpleContentQuickAddForm.show(
                context: context,
                title: 'Nuovo Asterisco',
                themeColor: const Color(0xFF3B82F6),
                type: 'asterisk',
                foldersFuture: _getFolders('asterisk'),
                onAdded: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Asterisco creato!')),
                  );
                },
              );
            },
          ),
          ConstellationAction(
            label: 'Risorsa',
            icon: Icons.book,
            onTap: () {
              ResourceQuickAddForm.show(
                context: context,
                foldersFuture: _getFolders('resource_list'),
                onAdded: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nuova risorsa creata!')),
                  );
                },
              );
            },
          ),
          ConstellationAction(
            label: 'Note',
            icon: Icons.note_add,
            onTap: () {
              SimpleContentQuickAddForm.show(
                context: context,
                title: 'Nuova Nota',
                themeColor: const Color(0xFF3B82F6),
                type: 'note',
                foldersFuture: _getFolders('note'),
                onAdded: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nota creata!')),
                  );
                },
              );
            },
          ),
        ];
      case 4: // SpaceHomeView
        return [];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: GestureDetector(
        onPanStart: (details) {
          _showOmniMenu(context);
          _dragNotifier.value = details.globalPosition;
        },
        onPanUpdate: (details) {
          _dragNotifier.value = details.globalPosition;
        },
        onPanEnd: (details) {
          _dragNotifier.value = null;
          _overlayKey.currentState?.executeHoveredAction();
        },
        child: FloatingActionButton(
          key: _fabKey,
          onPressed: () => _showOmniMenu(context),
          backgroundColor: const Color(0xFF6366F1),
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        )
        .animate()
        .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.8), curve: Curves.easeOutQuad)
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.06, 1.06), duration: 2.seconds, curve: Curves.easeInOutSine),
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
            const SizedBox(width: 40), // Spazio per il FAB (ridotto un po' per far spazio a 5 elementi)
            _buildNavItem(2, Icons.bolt, 'Azione'),
            _buildNavItem(3, Icons.inventory_2, 'Spazio'),
            _buildNavItem(4, Icons.science, 'Lab'),
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
          key: _overlayKey,
          dragNotifier: _dragNotifier,
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
