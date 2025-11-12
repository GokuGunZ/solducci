import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/context_manager.dart';

/// Page per creare un nuovo gruppo
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final contextManager = ContextManager();
      final group = await contextManager.createAndSwitchToGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (group != null && mounted) {
        // Success! Go back and show success message
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gruppo "${group.name}" creato con successo!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Dettagli',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Navigate to group detail when implemented
                context.push('/groups/${group.id}');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante la creazione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea Nuovo Gruppo'),
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_add,
                  size: 50,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Nome gruppo field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Gruppo *',
                hintText: 'Es: Coppia, Casa, Viaggio in Spagna',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Il nome del gruppo è obbligatorio';
                }
                if (value.trim().length < 2) {
                  return 'Il nome deve essere di almeno 2 caratteri';
                }
                return null;
              },
              enabled: !_isLoading,
            ),

            const SizedBox(height: 16),

            // Descrizione field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
                hintText: 'Es: Spese di casa, Viaggio estivo 2025',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                helperText: 'Aiuta i membri a capire lo scopo del gruppo',
              ),
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isLoading,
            ),

            const SizedBox(height: 24),

            // Info card
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Cosa succede dopo?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Diventerai automaticamente admin del gruppo\n'
                      '• Il contesto si switcherà al nuovo gruppo\n'
                      '• Potrai invitare altri membri via email\n'
                      '• Potrai creare spese condivise con il gruppo',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Create button
            FilledButton.icon(
              onPressed: _isLoading ? null : _createGroup,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_isLoading ? 'Creazione in corso...' : 'Crea Gruppo'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),

            const SizedBox(height: 12),

            // Cancel button
            OutlinedButton(
              onPressed: _isLoading ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Annulla'),
            ),
          ],
        ),
      ),
    );
  }
}
