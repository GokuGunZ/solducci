import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/user_profile.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/service/profile_service.dart';
import 'package:solducci/service/group_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:solducci/features/csv_importer/views/merchant_rules_manager_view.dart';
import 'package:solducci/utils/app_image_helper.dart';
import 'package:solducci/widgets/common/app_image_viewer.dart';

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
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento dati: $e')),
        );
      }
    }
  }

  Future<void> _editNickname() async {
    final currentNickname = _userProfile?.nickname ?? '';
    final controller = TextEditingController(text: currentNickname);

    final newNickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica Nickname'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Inserisci il tuo nickname',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (newNickname != null &&
        newNickname.isNotEmpty &&
        newNickname != _userProfile?.nickname) {
      try {
        await _profileService.updateNickname(newNickname);
        await _loadProfileData(); // Reload to show updated nickname
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Nickname aggiornato!')));
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

  Future<void> _updateAvatar() async {
    final newUrl = await AppImageHelper.showAvatarPickerDialog(
      context,
      title: 'Foto Profilo',
      currentUrl: _userProfile?.avatarUrl,
    );

    if (newUrl != null && mounted) {
      try {
        await _profileService.updateAvatarUrl(newUrl.isEmpty ? null : newUrl);
        await _loadProfileData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newUrl.isEmpty
                    ? 'Foto profilo rimossa'
                    : 'Foto profilo aggiornata con successo!',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante l\'aggiornamento: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: const SolducciAppBar(titleText: 'Profilo'),
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
                          // Avatar with edit badge & fullscreen view
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_userProfile?.avatarUrl != null &&
                                      _userProfile!.avatarUrl!.trim().isNotEmpty) {
                                    AppImageViewer.show(
                                      context,
                                      imageUrl: _userProfile!.avatarUrl!,
                                      title: _userProfile?.nickname ?? 'Il tuo profilo',
                                      subtitle: 'Foto profilo',
                                      onEdit: _updateAvatar,
                                    );
                                  } else {
                                    _updateAvatar();
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFFA855F7).withOpacity(0.2),
                                  backgroundImage: AppImageHelper.getImageProvider(
                                    _userProfile?.avatarUrl,
                                  ),
                                  child: _userProfile?.avatarUrl == null ||
                                          _userProfile!.avatarUrl!.trim().isEmpty
                                      ? Text(
                                          _userProfile?.initials ?? '?',
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFC084FC),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              GestureDetector(
                                onTap: _updateAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF18181D),
                                      width: 2.5,
                                    ),
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
                        leading: const Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                        ),
                        title: const Text('Nessun gruppo'),
                        subtitle: const Text(
                          'Crea un gruppo per condividere spese con altri',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/groups/create'),
                      ),
                    )
                  else
                    ..._userGroups.map(
                      (group) => Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            child: const Icon(Icons.group, color: Colors.blue),
                          ),
                          title: Text(group.name),
                          subtitle: Text(
                            group.description ??
                                '${group.memberCount ?? 0} membri',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            context.push('/groups/${group.id}');
                          },
                        ),
                      ),
                    ),

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

                  _buildListTile(
                    context: context,
                    icon: Icons.auto_fix_high_rounded,
                    title: 'Regole Esercenti Bancari',
                    subtitle: 'Personalizza alias e categorie automatiche',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantRulesManagerView(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Info Section
                  _buildSectionTitle('Info & Supporto'),
                  const SizedBox(height: 8),

                  // Mosaico Design System - visible only in dev mode
                  if (const String.fromEnvironment('ENVIRONMENT') == 'development')
                    _buildListTile(
                      context: context,
                      icon: Icons.dashboard_customize,
                      title: 'Mosaico (Design System)',
                      subtitle: 'Galleria componenti Neon & OLED',
                      color: Colors.purple,
                      onTap: () {
                        context.push('/mosaico');
                      },
                    ),

                  _buildListTile(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'Info App',
                    subtitle: 'Versione 1.0.1',
                    color: Colors.grey,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Solducci',
                        applicationVersion: '1.0.1',
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
          backgroundColor: color.withOpacity(0.2),
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
      'dic',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
