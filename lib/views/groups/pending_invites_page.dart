import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/group_invite.dart';
import 'package:solducci/service/group_service.dart';
import 'package:solducci/service/context_manager.dart';

/// Page per visualizzare e gestire gli inviti pendenti
class PendingInvitesPage extends StatefulWidget {
  const PendingInvitesPage({super.key});

  @override
  State<PendingInvitesPage> createState() => _PendingInvitesPageState();
}

class _PendingInvitesPageState extends State<PendingInvitesPage> {
  final _groupService = GroupService();
  final _contextManager = ContextManager();

  List<GroupInvite> _invites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    debugPrint('🔄 Loading pending invites...');
    setState(() => _isLoading = true);

    try {
      final invites = await _groupService.getPendingInvites();
      debugPrint('✅ Loaded ${invites.length} pending invites');

      setState(() {
        _invites = invites;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading invites: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptInvite(GroupInvite invite) async {
    debugPrint('🔄 Accepting invite: ${invite.id}');
    debugPrint('   Group: ${invite.groupName} (${invite.groupId})');

    try {
      await _groupService.acceptInvite(invite.id);
      debugPrint('✅ Invite accepted successfully');

      // Reload user groups in ContextManager
      debugPrint('🔄 Reloading ContextManager...');
      await _contextManager.initialize();
      debugPrint('✅ ContextManager reloaded');

      if (mounted) {
        // Remove invite from list
        debugPrint('🗑️ Removing invite from local list...');
        setState(() {
          _invites.removeWhere((i) => i.id == invite.id);
        });
        debugPrint('✅ Invite removed from list. Remaining: ${_invites.length}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hai accettato l\'invito al gruppo "${invite.groupName}"'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Visualizza',
              textColor: Colors.white,
              onPressed: () {
                context.push('/groups/${invite.groupId}');
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error accepting invite: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectInvite(GroupInvite invite) async {
    debugPrint('🔄 Rejecting invite: ${invite.id}');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rifiuta Invito'),
        content: Text(
          'Vuoi davvero rifiutare l\'invito al gruppo "${invite.groupName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Rifiuta',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _groupService.rejectInvite(invite.id);
      debugPrint('✅ Invite rejected');

      setState(() {
        _invites.removeWhere((i) => i.id == invite.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invito rifiutato'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error rejecting invite: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatExpiryDate(DateTime? expiresAt) {
    if (expiresAt == null) return 'Data sconosciuta';

    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Scaduto';
    } else if (difference.inDays > 0) {
      return 'Scade tra ${difference.inDays} giorni';
    } else if (difference.inHours > 0) {
      return 'Scade tra ${difference.inHours} ore';
    } else {
      return 'Scade a breve';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inviti Pendenti'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invites.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadInvites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invites.length,
                    itemBuilder: (context, index) {
                      final invite = _invites[index];
                      return _buildInviteCard(invite);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Nessun invito pendente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quando riceverai inviti a gruppi,\napparirranno qui',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(GroupInvite invite) {
    final expiryDate = invite.expiresAt;
    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group name and icon
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[200],
                  child: Icon(
                    Icons.group,
                    color: Colors.blue[700],
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.groupName ?? 'Gruppo Sconosciuto',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Da: ${invite.inviterNickname ?? "Sconosciuto"}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Expiry info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpired ? Icons.warning : Icons.access_time,
                    size: 20,
                    color: isExpired ? Colors.red[700] : Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatExpiryDate(invite.expiresAt),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isExpired ? Colors.red[700] : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),

            if (!isExpired) ...[
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _acceptInvite(invite),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accetta'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectInvite(invite),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Rifiuta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),

              // Expired - show remove button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _rejectInvite(invite),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Rimuovi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
