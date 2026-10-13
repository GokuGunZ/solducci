import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/blocs/dashboard/dashboard_bloc.dart';
import 'package:solducci/blocs/dashboard/dashboard_event.dart';
import 'package:solducci/blocs/dashboard/dashboard_state.dart';
import 'package:solducci/models/dashboard_config.dart';

/// Helper to map stored icon names to Flutter IconData
IconData getTabIconData(String iconName) {
  switch (iconName) {
    case 'home':
      return Icons.home_rounded;
    case 'wallet':
      return Icons.account_balance_wallet_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'analytics':
      return Icons.analytics_rounded;
    case 'shopping_bag':
      return Icons.shopping_bag_rounded;
    case 'flight':
      return Icons.flight_takeoff_rounded;
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'fitness':
      return Icons.fitness_center_rounded;
    case 'pie_chart':
      return Icons.pie_chart_rounded;
    case 'group':
      return Icons.group_rounded;
    case 'visibility':
      return Icons.visibility_rounded;
    case 'dashboard':
    default:
      return Icons.dashboard_rounded;
  }
}

/// Horizontal scrollable chips bar displaying all dashboards belonging to the active context.
class BentoDashboardTabsBar extends StatelessWidget {
  final DashboardLoaded state;

  const BentoDashboardTabsBar({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = state.currentContextTabs;
    final activeTab = state.activeTab;

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length + 1, // + 1 for Add Tab chip
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == tabs.length) {
            return _buildAddTabChip(context);
          }

          final tab = tabs[index];
          final isActive = activeTab?.id == tab.id;
          return _buildTabChip(context, tab, isActive, tabs.length);
        },
      ),
    );
  }

  Widget _buildTabChip(
    BuildContext context,
    BentoDashboardTab tab,
    bool isActive,
    int totalTabsInContext,
  ) {
    final iconData = getTabIconData(tab.iconName);
    final accentColor = tab.accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!isActive) {
            HapticFeedback.selectionClick();
            context.read<DashboardBloc>().add(SelectDashboardTab(tab.id));
          }
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showTabActionsSheet(context, tab, totalTabsInContext);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withOpacity(0.18)
                : const Color(0xFF141417),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? accentColor.withOpacity(0.65)
                  : Colors.white.withOpacity(0.08),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconData,
                size: 16,
                color: isActive ? accentColor : Colors.white60,
              ),
              const SizedBox(width: 7),
              Text(
                tab.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : Colors.white70,
                  letterSpacing: -0.2,
                ),
              ),
              if (state.isEditing && totalTabsInContext > 1) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _confirmDeleteTab(context, tab);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTabChip(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showCreateTabSheet(context);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141417).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              style: BorderStyle.solid,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: Colors.white70,
              ),
              SizedBox(width: 4),
              Text(
                'Nuova',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTabActionsSheet(
    BuildContext context,
    BentoDashboardTab tab,
    int totalTabsInContext,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141417),
      barrierColor: Colors.black.withOpacity(0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(getTabIconData(tab.iconName), color: tab.accentColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        tab.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.white70),
                  title: const Text('Modifica nome e stile', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showEditTabSheet(context, tab);
                  },
                ),
                if (totalTabsInContext > 1) ...[
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    title: const Text('Elimina dashboard', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _confirmDeleteTab(context, tab);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteTab(BuildContext context, BentoDashboardTab tab) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Elimina dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Sei sicuro di voler eliminare "${tab.title}"? I widget in questa dashboard andranno persi.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<DashboardBloc>().add(DeleteDashboardTab(tab.id));
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _showCreateTabSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121215),
      barrierColor: Colors.black.withOpacity(0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _CreateTabModal(
        contextKey: state.currentContextKey,
        onCreated: (title, iconName, color) {
          context.read<DashboardBloc>().add(
                CreateDashboardTab(
                  title: title,
                  contextKey: state.currentContextKey,
                  iconName: iconName,
                  accentColor: color,
                ),
              );
        },
      ),
    );
  }

  void _showEditTabSheet(BuildContext context, BentoDashboardTab tab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121215),
      barrierColor: Colors.black.withOpacity(0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _CreateTabModal(
        contextKey: tab.contextKey,
        initialTitle: tab.title,
        initialIconName: tab.iconName,
        initialColor: tab.accentColor,
        isEditing: true,
        onCreated: (title, iconName, color) {
          context.read<DashboardBloc>().add(
                UpdateDashboardTabInfo(
                  tabId: tab.id,
                  title: title,
                  iconName: iconName,
                  accentColor: color,
                ),
              );
        },
      ),
    );
  }
}

class _CreateTabModal extends StatefulWidget {
  final String contextKey;
  final String? initialTitle;
  final String? initialIconName;
  final Color? initialColor;
  final bool isEditing;
  final void Function(String title, String iconName, Color color) onCreated;

  const _CreateTabModal({
    required this.contextKey,
    this.initialTitle,
    this.initialIconName,
    this.initialColor,
    this.isEditing = false,
    required this.onCreated,
  });

  @override
  State<_CreateTabModal> createState() => _CreateTabModalState();
}

class _CreateTabModalState extends State<_CreateTabModal> {
  late final TextEditingController _titleController;
  late String _selectedIcon;
  late Color _selectedColor;

  static const List<Map<String, dynamic>> _icons = [
    {'name': 'home', 'icon': Icons.home_rounded},
    {'name': 'wallet', 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'bolt', 'icon': Icons.bolt_rounded},
    {'name': 'analytics', 'icon': Icons.analytics_rounded},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag_rounded},
    {'name': 'flight', 'icon': Icons.flight_takeoff_rounded},
    {'name': 'restaurant', 'icon': Icons.restaurant_rounded},
    {'name': 'fitness', 'icon': Icons.fitness_center_rounded},
    {'name': 'pie_chart', 'icon': Icons.pie_chart_rounded},
    {'name': 'dashboard', 'icon': Icons.dashboard_rounded},
  ];

  static const List<Color> _colors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFF0EA5E9), // Sky
    Color(0xFFF59E0B), // Amber
    Color(0xFFF43F5E), // Rose
    Color(0xFF8B5CF6), // Purple
    Color(0xFF14B8A6), // Teal
    Color(0xFFEC4899), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _selectedIcon = widget.initialIconName ?? 'dashboard';
    _selectedColor = widget.initialColor ?? _colors.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isEditing ? 'Modifica Dashboard' : 'Nuova Dashboard',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Nome dashboard',
              labelStyle: const TextStyle(color: Colors.white60),
              hintText: 'es. Spesa, Lavoro, Viaggi...',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF1A1A1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _selectedColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Icona',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _icons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _icons[index];
                final name = item['name'] as String;
                final icon = item['icon'] as IconData;
                final isSelected = _selectedIcon == name;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIcon = name);
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor.withOpacity(0.2) : const Color(0xFF1A1A1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _selectedColor : Colors.white10,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? _selectedColor : Colors.white60,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Colore accento',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final color = _colors[index];
                final isSelected = _selectedColor.value == color.value;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedColor = color);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: isSelected ? 2.5 : 0,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () {
                final text = _titleController.text.trim();
                if (text.isEmpty) return;
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                widget.onCreated(text, _selectedIcon, _selectedColor);
              },
              child: Text(
                widget.isEditing ? 'Salva modifiche' : 'Crea dashboard',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
