import 'package:flutter/material.dart';
import 'package:solducci/views/hubs/feed_home_view.dart';
import 'package:solducci/views/hubs/economy_hub_view.dart';
import 'package:solducci/views/hubs/action_hub_view.dart';
import 'package:solducci/views/hubs/archive_hub_view.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cosa vuoi fare?', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildOmniOption(bottomSheetContext, 'Spesa', Icons.attach_money, const Color(0xFF10B981), () {
                    if (Navigator.canPop(bottomSheetContext)) Navigator.pop(bottomSheetContext);
                    _openExpenseForm(context);
                  }),
                  const SizedBox(width: 16),
                  _buildOmniOption(bottomSheetContext, 'Task', Icons.check_circle_outline, const Color(0xFF3B82F6), () {
                    if (Navigator.canPop(bottomSheetContext)) Navigator.pop(bottomSheetContext);
                    context.push('/space/tasks');
                  }),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildOmniOption(bottomSheetContext, 'Evento/Viaggio', Icons.event, const Color(0xFF6366F1), () {
                    if (Navigator.canPop(bottomSheetContext)) Navigator.pop(bottomSheetContext);
                    context.push('/space/time_management');
                  }),
                  const SizedBox(width: 16),
                  _buildOmniOption(bottomSheetContext, 'Nota', Icons.notes, const Color(0xFFF59E0B), () {
                    if (Navigator.canPop(bottomSheetContext)) Navigator.pop(bottomSheetContext);
                    context.push('/space/notes');
                  }),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }
    );
  }

  Widget _buildOmniOption(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
