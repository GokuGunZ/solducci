import 'package:flutter/material.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/widgets/group_mosaic_avatar.dart';
import 'package:solducci/utils/app_image_helper.dart';
import 'package:solducci/service/profile_service_cached.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CircularContextAvatar extends StatelessWidget {
  final ExpenseContext expenseContext;
  final double radius;
  final bool showLabel;

  const CircularContextAvatar({
    super.key,
    required this.expenseContext,
    this.radius = 20.0,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    if (expenseContext.isPersonal) {
      return _buildPersonalAvatar();
    } else if (expenseContext.isView) {
      return _buildViewAvatar(context);
    } else {
      return _buildGroupAvatar(expenseContext.group, radius);
    }
  }

  Widget _buildPersonalAvatar() {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user != null ? ProfileServiceCached().getAvatarUrl(user.id) : null;
    final imageProvider = AppImageHelper.getImageProvider(avatarUrl);

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFA855F7).withOpacity(0.22),
      foregroundColor: const Color(0xFFC084FC),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(Icons.person_rounded, size: radius * 1.3)
          : null,
    );

    if (!showLabel) return avatar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: 2),
        SizedBox(
          width: radius * 2.5,
          child: const Text(
            'Personale',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupAvatar(ExpenseGroup? group, double r) {
    if (group == null) {
      return CircleAvatar(
        radius: r,
        backgroundColor: const Color(0xFF27272A),
        child: Icon(Icons.group_rounded, color: Colors.white54, size: r * 1.3),
      );
    }

    final avatar = GroupMosaicAvatar(
      group: group,
      radius: r,
      members: group.members,
    );

    // Se è un sub-avatar di un cluster o showLabel è falso, restituiamo solo l'avatar
    if (radius != r || !showLabel) {
      return avatar;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: 2),
        SizedBox(
          width: radius * 2.5,
          child: Text(
            expenseContext.displayName, // handles " 👤" if personal is included
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildViewAvatar(BuildContext context) {
    final view = expenseContext.view!;
    final groupIds = view.groupIds;
    final contextManager = ContextManager();
    final groups = contextManager.userGroups.where((g) => groupIds.contains(g.id)).toList();

    Widget avatarCluster;
    
    if (groups.isEmpty) {
      avatarCluster = CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF3B82F6).withOpacity(0.22),
        child: Icon(Icons.view_list_rounded, color: const Color(0xFF60A5FA), size: radius * 1.3),
      );
    } else if (groups.length == 1) {
      avatarCluster = CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF3B82F6).withOpacity(0.22),
        child: Icon(Icons.view_list_rounded, color: const Color(0xFF60A5FA), size: radius * 1.3),
      );
    } else {
      final int count = groups.length > 3 ? 3 : groups.length;
      final double smallRadius = radius * 0.7;
      
      List<Widget> stackChildren = [];
      
      for (int i = count - 1; i >= 0; i--) {
        Widget child;
        if (i == 2 && groups.length > 3) {
          child = CircleAvatar(
            radius: smallRadius,
            backgroundColor: const Color(0xFF27272A),
            child: Text(
              '+${groups.length - 2}',
              style: TextStyle(fontSize: smallRadius * 0.9, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          );
        } else {
          child = _buildGroupAvatar(groups[i], smallRadius);
        }

        stackChildren.add(
          Positioned(
            left: i * (radius * 0.8),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF09090B), width: 2),
              ),
              child: child,
            ),
          ),
        );
      }

      avatarCluster = SizedBox(
        width: radius * 2 + (count - 1) * (radius * 0.8),
        height: radius * 2,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: stackChildren,
        ),
      );
    }

    if (!showLabel) return avatarCluster;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatarCluster,
        const SizedBox(height: 2),
        SizedBox(
          width: radius * 3.5, // slightly wider for views
          child: Text(
            expenseContext.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
