import 'package:flutter/material.dart';
import 'package:solducci/views/hubs/feed_home_view.dart';
import 'package:solducci/views/hubs/economy_hub_view.dart';
import 'package:solducci/views/hubs/action_hub_view.dart';
import 'package:solducci/views/hubs/archive_hub_view.dart';
import 'package:solducci/widgets/constellation_menu.dart';
import 'package:solducci/models/expense_form.dart';
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

  List<ConstellationAction> _getCurrentTabActions(BuildContext context) {
    switch (_selectedIndex) {
      case 0: // Feed
        return [
          ConstellationAction(
            label: 'Gruppo',
            icon: Icons.group_add,
            onTap: () => context.push('/groups/create'),
          ),
          ConstellationAction(
            label: 'Importanti',
            icon: Icons.priority_high,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hub Importanti in arrivo!')),
              );
            },
          ),
        ];
      case 1: // Economia
        return [
          ConstellationAction(
            label: 'Grafici',
            icon: Icons.pie_chart,
            onTap: () => context.push('/dashboard/monthly'),
          ),
          ConstellationAction(
            label: 'Dispense',
            icon: Icons.kitchen,
            onTap: () => context.push('/space/pantry'),
          ),
          ConstellationAction(
            label: 'Liste Spesa',
            icon: Icons.shopping_cart,
            onTap: () => context.push('/space/shopping'),
          ),
        ];
      case 2: // Azione
        return [
          ConstellationAction(
            label: 'Routine',
            icon: Icons.repeat,
            onTap: () => context.push('/space/time_management/routines'),
          ),
          ConstellationAction(
            label: 'Focus',
            icon: Icons.timer,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Focus Mode in arrivo!')),
              );
            },
          ),
          ConstellationAction(
            label: 'Abitudini',
            icon: Icons.check_circle,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Habit Tracker in arrivo!')),
              );
            },
          ),
        ];
      case 3: // Archivio
        return [
          ConstellationAction(
            label: 'Asterisco',
            icon: Icons.star,
            onTap: () => context.push('/space/asterisks'),
          ),
          ConstellationAction(
            label: 'Risorsa',
            icon: Icons.book,
            onTap: () => context.push('/space/resources'),
          ),
          ConstellationAction(
            label: 'Note',
            icon: Icons.note_add,
            onTap: () => context.push('/space/notes'),
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
