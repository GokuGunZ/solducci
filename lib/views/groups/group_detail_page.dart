import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/service/group_service.dart';
import 'package:solducci/service/context_manager.dart';

/// Page che mostra i dettagli di un gruppo
class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({
    super.key,
    required this.groupId,
  });

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
    debugPrint('🔄 Loading group data for groupId: ${widget.groupId}');
    setState(() => _isLoading = true);

    try {
      debugPrint('📊 Fetching group and members...');
      final results = await Future.wait([
        _groupService.getGroupById(widget.groupId),
        _groupService.getGroupMembers(widget.groupId),
      ]);

      final group = results[0] as ExpenseGroup?;
      final members = results[1] as List<GroupMember>;

      debugPrint('✅ Group fetched: ${group?.name}');
      debugPrint('✅ Members count: ${members.length}');

      if (group != null) {
        // Check if current user is admin
        debugPrint('🔐 Checking admin status...');
        final isAdmin = await _groupService.isUserAdmin(widget.groupId);
        debugPrint('✅ Is admin: $isAdmin');

        setState(() {
          _group = group;
          _members = members;
          _isAdmin = isAdmin;
          _isLoading = false;
        });
        debugPrint('✅ Group detail page loaded successfully');
      } else {
        debugPrint('❌ Group is null, showing error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gruppo non trovato')),
          );
          context.pop();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading group data: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
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
            child: const Text(
              'Lascia',
              style: TextStyle(color: Colors.red),
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e')),
          );
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
            child: const Text(
              'Elimina',
              style: TextStyle(color: Colors.red),
            ),
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
        appBar: AppBar(title: const Text('Caricamento...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Errore')),
        body: const Center(child: Text('Gruppo non trovato')),
      );
    }

    return Scaffold(
      appBar: AppBar(
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
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue[200],
                      child: Icon(
                        Icons.group,
                        size: 50,
                        color: Colors.blue[700],
                      ),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
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

            ..._members.map((member) => Card(
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
                )),

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
