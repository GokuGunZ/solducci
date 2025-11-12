import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/group_service.dart';

/// Page per invitare un nuovo membro al gruppo
class InviteMemberPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const InviteMemberPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends State<InviteMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _groupService = GroupService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _groupService.sendInvite(
        groupId: widget.groupId,
        inviteeEmail: _emailController.text.trim().toLowerCase(),
      );

      if (mounted) {
        context.pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invito inviato a ${_emailController.text.trim()}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
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
        title: const Text('Invita Membro'),
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
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 50,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Group info
            Card(
              color: Colors.blue.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.group, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gruppo:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            widget.groupName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Email field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email del Membro *',
                hintText: 'esempio@email.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                helperText: 'Inserisci l\'email dell\'utente da invitare',
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'email è obbligatoria';
                }

                // Basic email validation
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Email non valida';
                }

                return null;
              },
              enabled: !_isLoading,
            ),

            const SizedBox(height: 24),

            // Info card
            Card(
              color: Colors.orange.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Come funziona?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• L\'utente riceverà un invito via email\n'
                      '• L\'invito scade dopo 7 giorni\n'
                      '• Può accettarlo o rifiutarlo\n'
                      '• Se accetta, entrerà nel gruppo come membro\n'
                      '• Se l\'email non è registrata, può registrarsi',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Send button
            FilledButton.icon(
              onPressed: _isLoading ? null : _sendInvite,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Invio in corso...' : 'Invia Invito'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
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
