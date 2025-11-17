import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/user_profile.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/service/profile_service.dart';
import 'package:solducci/service/group_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Profile page with user info, settings, and links to additional features
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileService = ProfileService();
  final _groupService = GroupService();
  final _contextManager = ContextManager();

  UserProfile? _userProfile;
  List<ExpenseGroup> _userGroups = [];
  int _pendingInviteCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    // Listen to context changes to reload groups list
    _contextManager.addListener(_onContextChanged);
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    super.dispose();
  }

  void _onContextChanged() {
    // Reload profile data when groups change (e.g., after leaving a group)
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      // Load profile, groups, and pending invites in parallel
      final results = await Future.wait([
        _profileService.getCurrentUserProfile(),
        _groupService.getUserGroups(),
        _groupService.getPendingInviteCount(),
      ]);

      setState(() {
        _userProfile = results[0] as UserProfile?;
        _userGroups = results[1] as List<ExpenseGroup>;
        _pendingInviteCount = results[2] as int;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editNickname() async {
    final controller = TextEditingController(text: _userProfile?.nickname ?? '');

    final newNickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica Nickname'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nickname',
            hintText: 'Il tuo nome o soprannome',
          ),
          maxLength: 50,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (newNickname != null && newNickname.isNotEmpty && newNickname != _userProfile?.nickname) {
      try {
        await _profileService.updateNickname(newNickname);
        await _loadProfileData(); // Reload to show updated nickname
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nickname aggiornato!')),
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
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // User Info Card
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Avatar with initials
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.purple[200],
                            child: _userProfile?.avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _userProfile!.avatarUrl!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Text(
                                        _userProfile?.initials ?? '?',
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple[700],
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    _userProfile?.initials ?? '?',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[700],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          // Nickname with edit button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _userProfile?.nickname ?? 'Utente',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: _editNickname,
                                tooltip: 'Modifica nickname',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.createdAt != null
                                ? 'Membro da ${_formatDate(DateTime.parse(user!.createdAt))}'
                                : 'Membro recente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Groups Section
                  _buildSectionTitle('I Miei Gruppi'),
                  const SizedBox(height: 8),

                  if (_userGroups.isEmpty)
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.grey),
                        title: const Text('Nessun gruppo'),
                        subtitle: const Text(
                            'Crea un gruppo per condividere spese con altri'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/groups/create'),
                      ),
                    )
                  else
                    ..._userGroups.map((group) => Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withValues(alpha: 0.2),
                              child: const Icon(Icons.group, color: Colors.blue),
                            ),
                            title: Text(group.name),
                            subtitle: Text(
                              group.description ?? '${group.memberCount ?? 0} membri',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              debugPrint('🔄 Navigating to group detail: ${group.id}');
                              context.push('/groups/${group.id}');
                            },
                          ),
                        )),

                  const SizedBox(height: 16),

                  // Pending Invites Badge
                  if (_pendingInviteCount > 0)
                    _buildListTile(
                      context: context,
                      icon: Icons.mail_outline,
                      title: 'Inviti Pendenti',
                      subtitle: 'Hai $_pendingInviteCount inviti in attesa',
                      color: Colors.red,
                      onTap: () => context.push('/invites/pending'),
                      badge: '$_pendingInviteCount',
                    ),

                  const SizedBox(height: 24),

                  // Features Section
                  _buildSectionTitle('Funzionalità'),
                  const SizedBox(height: 8),

                  _buildListTile(
                    context: context,
                    icon: Icons.person_outline,
                    title: 'Spese Personali',
                    subtitle: 'Visualizza le tue spese collegate all\'account',
                    color: Colors.blue,
                    onTap: () => context.push('/personal-expenses'),
                    badge: 'Prossimamente',
                  ),

                  _buildListTile(
                    context: context,
                    icon: Icons.note_alt_outlined,
                    title: 'Note & Liste',
                    subtitle: 'Lista della spesa, dispensa, promemoria',
                    color: Colors.orange,
                    onTap: () => context.push('/notes'),
                    badge: 'Prossimamente',
                  ),

                  const SizedBox(height: 24),

                  // Settings Section
                  _buildSectionTitle('Impostazioni'),
                  const SizedBox(height: 8),

                  _buildListTile(
                    context: context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifiche',
                    subtitle: 'Gestisci le notifiche',
                    color: Colors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funzionalità in arrivo')),
                      );
                    },
                  ),

                  _buildListTile(
                    context: context,
                    icon: Icons.palette_outlined,
                    title: 'Tema',
                    subtitle: 'Personalizza l\'aspetto dell\'app',
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funzionalità in arrivo')),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Info Section
                  _buildSectionTitle('Info & Supporto'),
                  const SizedBox(height: 8),

                  _buildListTile(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'Info App',
                    subtitle: 'Versione 1.0.0',
                    color: Colors.grey,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Solducci',
                        applicationVersion: '1.0.0',
                        applicationIcon: Icon(
                          Icons.account_balance_wallet,
                          size: 50,
                          color: Colors.purple[700],
                        ),
                      );
                    },
                  ),
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

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Text(title),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = [
      'gen',
      'feb',
      'mar',
      'apr',
      'mag',
      'giu',
      'lug',
      'ago',
      'set',
      'ott',
      'nov',
      'dic'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
