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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOmniMenu(context),
        child: const Icon(Icons.add, size: 32),
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
    final color = isSelected ? const Color(0xFF6366F1) : Colors.white30;
    
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
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent, // Background handled by ConstellationMenu
      transitionDuration: const Duration(milliseconds: 0), // Handled by ConstellationMenu
      pageBuilder: (context, animation, secondaryAnimation) {
        return ConstellationMenu(
          onSpesa: () => _openExpenseForm(context),
          onTask: () => context.push('/space/tasks'),
          onEvento: () => context.push('/space/time_management'),
          onNota: () => context.push('/space/notes'),
        );
      },
    );
  }
}
