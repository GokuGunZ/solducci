import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/context_manager.dart';

/// Widget che mostra il contesto corrente (Personal/Gruppo) e permette di switchare
class ContextSwitcher extends StatelessWidget {
  const ContextSwitcher({super.key});

  void _showContextPicker(BuildContext context) {
    final contextManager = ContextManager();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Seleziona Contesto',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            const Divider(height: 1),

            // Lista contesti
            Expanded(
              child: ListenableBuilder(
                listenable: contextManager,
                builder: (context, child) {
                  final currentContext = contextManager.currentContext;
                  final userGroups = contextManager.userGroups;

                  return ListView(
                    controller: scrollController,
                    children: [
                      // Opzione Personal
                      RadioListTile<String?>(
                        value: null,
                        groupValue: currentContext.groupId,
                        onChanged: (_) {
                          contextManager.switchToPersonal();
                          Navigator.pop(context);
                        },
                        title: const Row(
                          children: [
                            Icon(Icons.person, color: Colors.purple),
                            SizedBox(width: 12),
                            Text('Personale'),
                          ],
                        ),
                        subtitle: const Text('Le tue spese personali'),
                        secondary: currentContext.isPersonal
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),

                      if (userGroups.isNotEmpty) ...[
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'I TUOI GRUPPI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],

                      // Lista gruppi
                      ...userGroups.map((group) {
                        final isSelected = currentContext.groupId == group.id;

                        return RadioListTile<String?>(
                          value: group.id,
                          groupValue: currentContext.groupId,
                          onChanged: (_) {
                            contextManager.switchToGroup(group);
                            Navigator.pop(context);
                          },
                          title: Row(
                            children: [
                              Icon(
                                Icons.group,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  group.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            group.description ??
                                '${group.memberCount ?? 0} membri',
                          ),
                          secondary: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : null,
                        );
                      }),

                      const Divider(),

                      // Bottone "Crea Nuovo Gruppo"
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.add, color: Colors.green),
                        ),
                        title: const Text(
                          'Crea Nuovo Gruppo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/groups/create');
                        },
                      ),

                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ContextManager(),
      builder: (context, child) {
        final contextManager = ContextManager();
        final currentContext = contextManager.currentContext;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showContextPicker(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentContext.isPersonal ? Icons.person : Icons.group,
                    size: 20,
                    color: currentContext.isPersonal
                        ? Colors.purple
                        : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      currentContext.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
