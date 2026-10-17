import 'package:flutter/material.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/expense_view.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/theme/app_theme.dart';

/// Context selection result returned by [ViewGroupPickerSheet].
class ContextChoice {
  final bool isPersonal;
  final ExpenseGroup? group;

  const ContextChoice.personal()
      : isPersonal = true,
        group = null;

  const ContextChoice.group(this.group)
      : isPersonal = false;

  String? get groupId => group?.id;
  String get displayName => isPersonal ? 'Personale' : (group?.name ?? '');
}

/// Modal bottom sheet allowing the user to select the destination group (or personal)
/// when creating items from within a Multi-Group View context (`isView == true`).
class ViewGroupPickerSheet extends StatelessWidget {
  final List<ExpenseGroup> availableGroups;
  final bool allowPersonal;
  final String title;
  final String subtitle;

  const ViewGroupPickerSheet({
    super.key,
    required this.availableGroups,
    this.allowPersonal = false,
    this.title = 'Seleziona Gruppo di Destinazione',
    this.subtitle = 'Questa vista aggrega più gruppi. Scegli dove creare questo elemento.',
  });

  /// Displays the picker sheet and returns the selected [ContextChoice], or `null` if dismissed.
  static Future<ContextChoice?> show(
    BuildContext context, {
    ExpenseView? view,
    List<ExpenseGroup>? groups,
    bool? allowPersonal,
    String? title,
    String? subtitle,
  }) async {
    final contextManager = ContextManager();
    final effectiveView = view ?? contextManager.currentContext.view;
    final allGroups = groups ?? contextManager.userGroups;

    // Filter groups belonging to the active view if specified
    final filteredGroups = effectiveView != null
        ? allGroups.where((g) => effectiveView.groupIds.contains(g.id)).toList()
        : allGroups;

    final canIncludePersonal =
        allowPersonal ?? (effectiveView?.includePersonal ?? false);

    return showModalBottomSheet<ContextChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ViewGroupPickerSheet(
        availableGroups: filteredGroups,
        allowPersonal: canIncludePersonal,
        title: title ?? 'Seleziona Gruppo di Destinazione',
        subtitle: subtitle ??
            'Questa vista aggrega più gruppi. Scegli dove creare questo elemento.',
      ),
    );
  }

  /// Convenience method that guarantees returning an [ExpenseGroup] or `null`.
  static Future<ExpenseGroup?> showForGroup(
    BuildContext context, {
    ExpenseView? view,
    List<ExpenseGroup>? groups,
    String? title,
    String? subtitle,
  }) async {
    final result = await show(
      context,
      view: view,
      groups: groups,
      allowPersonal: false,
      title: title,
      subtitle: subtitle,
    );
    return result?.group;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.view_agenda_rounded,
                    color: Color(0xFF6366F1),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Optional Personal Option
            if (allowPersonal) ...[
              _buildOptionTile(
                context: context,
                title: 'Personale',
                subtitle: 'Visibile solo a te',
                icon: Icons.person_rounded,
                iconColor: Colors.blueAccent,
                onTap: () {
                  Navigator.of(context).pop(const ContextChoice.personal());
                },
              ),
              const SizedBox(height: 8),
            ],

            // Groups List
            if (availableGroups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Nessun gruppo disponibile nella vista',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: availableGroups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final group = availableGroups[index];
                    return _buildOptionTile(
                      context: context,
                      title: group.name,
                      subtitle: group.description ?? 'Gruppo condiviso',
                      icon: Icons.group_rounded,
                      iconColor: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.of(context)
                            .pop(ContextChoice.group(group));
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
