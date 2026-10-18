import 'package:flutter/material.dart';
import 'package:solducci/views/shell_with_nav.dart';

class EconomyTarget {
  final String section; // 'wallets', 'categories', 'recurring', 'cashflow', 'investments', 'debts', 'expenses'
  final String? itemId;
  final DateTime timestamp;

  const EconomyTarget({
    required this.section,
    this.itemId,
    required this.timestamp,
  });
}

class AppNavigationCoordinator {
  static final AppNavigationCoordinator _instance = AppNavigationCoordinator._internal();
  factory AppNavigationCoordinator() => _instance;
  AppNavigationCoordinator._internal();

  final ValueNotifier<EconomyTarget?> economyTarget = ValueNotifier(null);

  void navigateToTab(BuildContext context, int tabIndex) {
    ShellWithNav.navigateToTab(context, tabIndex);
  }

  void navigateToEconomy(BuildContext context, {required String section, String? itemId}) {
    ShellWithNav.navigateToTab(context, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      economyTarget.value = EconomyTarget(
        section: section,
        itemId: itemId,
        timestamp: DateTime.now(),
      );
    });
  }
}
