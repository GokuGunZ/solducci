import 'package:flutter/material.dart';
import 'package:solducci/service/context_manager.dart';

/// Dialog per creare una nuova vista da selezione multipla
class CreateViewDialog extends StatefulWidget {
  final List<String> selectedGroupIds;
  final List<String> selectedViewIds;

  const CreateViewDialog({
    required this.selectedGroupIds,
    required this.selectedViewIds,
    super.key,
  });

  @override
  State<CreateViewDialog> createState() => _CreateViewDialogState();
}

class _CreateViewDialogState extends State<CreateViewDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _includePersonal = false;

  /// Ottieni tutti i group IDs flatten (da gruppi + viste selezionate)
  List<String> get _flatGroupIds {
    final contextManager = ContextManager();
    final allIds = <String>{};

    // Aggiungi gruppi selezionati direttamente
    allIds.addAll(widget.selectedGroupIds);

    // Aggiungi gruppi dalle viste selezionate (flatten hierarchy)
    for (final viewId in widget.selectedViewIds) {
      try {
        final view = contextManager.userViews.firstWhere((v) => v.id == viewId);
        allIds.addAll(view.groupIds);
      } catch (e) {
        // Vista non trovata, skip
      }
    }

    return allIds.toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crea Nuova Vista'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Vista *',
                hintText: 'Es. Famiglia + Amici',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
                hintText: 'Descrivi questa vista...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Includi spese personali'),
              subtitle: const Text('Mostra anche le tue spese private'),
              value: _includePersonal,
              onChanged: (value) =>
                  setState(() => _includePersonal = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gruppi inclusi: ${_flatGroupIds.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _createView,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('Crea Vista'),
        ),
      ],
    );
  }

  Future<void> _createView() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un nome per la vista'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_flatGroupIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona almeno un gruppo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final contextManager = ContextManager();

    // Check if a view with the same groups already exists
    final existingView = contextManager.findViewWithSameGroups(_flatGroupIds);

    if (existingView != null) {
      // Vista già esistente: switcha a quella invece di crearne una nuova
      contextManager.switchToView(existingView);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vista "${existingView.name}" già esistente con questi gruppi',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue[700],
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return true = success
      }
      return;
    }

    // Vista non esiste: creala
    try {
      await contextManager.createAndSwitchToView(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        groupIds: _flatGroupIds,
        includePersonal: _includePersonal,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true = success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore creazione vista: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
