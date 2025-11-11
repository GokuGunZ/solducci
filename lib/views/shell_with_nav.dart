import 'package:flutter/material.dart';
import 'package:solducci/views/new_homepage.dart';
import 'package:solducci/views/expense_list.dart';
import 'package:solducci/views/dashboard_hub.dart';
import 'package:solducci/views/profile_page.dart';

/// Shell widget that provides persistent bottom navigation bar
/// Uses IndexedStack to preserve state when switching tabs
class ShellWithNav extends StatefulWidget {
  const ShellWithNav({super.key});

  @override
  State<ShellWithNav> createState() => _ShellWithNavState();
}

class _ShellWithNavState extends State<ShellWithNav> {
  int _selectedIndex = 0;

  // List of tab pages
  static const List<Widget> _pages = [
    NewHomepage(),
    ExpenseList(),
    DashboardHub(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.purple[700],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Spese',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }
}
