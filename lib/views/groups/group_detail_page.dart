import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/service/group_service.dart';
import 'package:solducci/service/context_manager.dart';

/// Page che mostra i dettagli di un gruppo
class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final _groupService = GroupService();
  final _contextManager = ContextManager();

  ExpenseGroup? _group;
  List<GroupMember> _members = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _groupService.getGroupById(widget.groupId),
        _groupService.getGroupMembers(widget.groupId),
      ]);

      final group = results[0] as ExpenseGroup?;
      final members = results[1] as List<GroupMember>;

      if (group != null) {
        // Check if current user is admin
        final isAdmin = await _groupService.isUserAdmin(widget.groupId);

        setState(() {
          _group = group;
          _members = members;
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Gruppo non trovato')));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lascia Gruppo'),
        content: Text(
          _isAdmin
              ? 'Sei l\'admin di questo gruppo. Se lo lasci, il gruppo potrebbe rimanere senza admin. Vuoi continuare?'
              : 'Vuoi davvero lasciare questo gruppo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lascia', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // FIX: Leave the group being viewed (widget.groupId), not the current context group
        await _groupService.leaveGroup(widget.groupId);

        // Reload the ContextManager to update the groups list
        await _contextManager.loadUserGroups();

        // If we just left the current context group, switch to personal
        if (_contextManager.currentContext.groupId == widget.groupId) {
          _contextManager.switchToPersonal();
        }

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hai lasciato il gruppo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Errore: $e')));
        }
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Gruppo'),
        content: const Text(
          'ATTENZIONE: Questa azione è irreversibile!\n\n'
          'Eliminando il gruppo verranno rimosse:\n'
          '• Tutte le spese del gruppo\n'
          '• Tutti i membri\n'
          '• Tutti gli inviti pendenti\n\n'
          'Vuoi continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // FIX: Delete the specific group, then reload context
        await _groupService.deleteGroup(widget.groupId);

        // Reload the ContextManager to update the groups list
        await _contextManager.loadUserGroups();

        // If we just deleted the current context group, switch to personal
        if (_contextManager.currentContext.groupId == widget.groupId) {
          _contextManager.switchToPersonal();
        }

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gruppo eliminato'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Errore: $e')));
        }
      }
    }
  }

  Future<void> _updateGroupImage() async {
    final controller = TextEditingController(text: _group?.imageUrl ?? '');
    final newUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181D),
        title: const Text('Immagine Gruppo', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inserisci l\'URL dell\'immagine o avatar per questo gruppo:',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                  onPressed: () => controller.clear(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          if (_group?.imageUrl != null && _group!.imageUrl!.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, ''), // Rimuovi immagine
              child: const Text('Rimuovi', style: TextStyle(color: Colors.redAccent)),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.black,
            ),
            child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newUrl != null && mounted && _group != null) {
      try {
        final updatedGroup = _group!.copyWith(imageUrl: newUrl.isEmpty ? null : newUrl);
        await _groupService.updateGroup(updatedGroup);
        await _contextManager.loadUserGroups();
        if (_contextManager.currentContext.groupId == widget.groupId) {
          _contextManager.switchToGroup(updatedGroup);
        }

        setState(() {
          _group = updatedGroup;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Immagine del gruppo aggiornata!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: SolducciAppBar(title: const Text('Caricamento...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_group == null) {
      return Scaffold(
        appBar: SolducciAppBar(title: const Text('Errore')),
        body: const Center(child: Text('Gruppo non trovato')),
      );
    }

    return Scaffold(
      appBar: SolducciAppBar(
        title: Text(_group!.name),
        elevation: 2,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Settings page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funzionalità in arrivo')),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroupData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group Info Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: _isAdmin ? _updateGroupImage : null,
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                            backgroundImage: _group!.imageUrl != null && _group!.imageUrl!.isNotEmpty
                                ? NetworkImage(_group!.imageUrl!)
                                : null,
                            child: _group!.imageUrl == null || _group!.imageUrl!.isEmpty
                                ? Text(
                                    _group!.initials,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF34D399),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (_isAdmin)
                          GestureDetector(
                            onTap: _updateGroupImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _group!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_group!.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _group!.description!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Members Section
            _buildSectionTitle('Membri (${_members.length})'),
            const SizedBox(height: 8),

            ..._members.map(
              (member) => Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple[200],
                    child: Text(
                      (member.nickname ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(member.nickname ?? 'Unknown'),
                  subtitle: Text(member.email ?? ''),
                  trailing: member.role == GroupRole.admin
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Invite button
            if (_isAdmin)
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await context.push(
                    '/groups/${widget.groupId}/invite?name=${Uri.encodeComponent(_group!.name)}',
                  );
                  // Reload members if invite was sent successfully
                  if (result == true && mounted) {
                    await _loadGroupData();
                  }
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Invita Membro'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

            const SizedBox(height: 24),

            // Actions Section
            _buildSectionTitle('Azioni'),
            const SizedBox(height: 8),

            // Leave group button
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                title: const Text('Lascia Gruppo'),
                subtitle: const Text('Abbandona questo gruppo'),
                onTap: _leaveGroup,
              ),
            ),

            // Delete group button (only admin)
            if (_isAdmin)
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Elimina Gruppo'),
                  subtitle: const Text('Rimuovi permanentemente questo gruppo'),
                  onTap: _deleteGroup,
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
