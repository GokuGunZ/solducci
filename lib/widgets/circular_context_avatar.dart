import 'package:flutter/material.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/models/group.dart';

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
    // We could use an avatarUrl here if the Profile model has one, 
    // for now we use the purple theme with a person icon.
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.purple.shade100,
      foregroundColor: Colors.purple.shade800,
      child: Icon(Icons.person, size: radius * 1.4), // increased from 1.2
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
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
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
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.group, color: Colors.grey, size: r * 1.4),
      );
    }

    Widget avatar;
    if (group.imageUrl != null && group.imageUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: r,
        backgroundImage: NetworkImage(group.imageUrl!),
        backgroundColor: Colors.green.shade100,
      );
    } else {
      avatar = CircleAvatar(
        radius: r,
        backgroundColor: Colors.green.shade100,
        foregroundColor: Colors.green.shade800,
        child: Text(
          group.initials,
          style: TextStyle(fontSize: r * 1.0, fontWeight: FontWeight.bold), // increased from 0.8
        ),
      );
    }

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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
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
        backgroundColor: Colors.orange.shade100,
        child: Icon(Icons.view_list_rounded, color: Colors.orange.shade800, size: radius * 1.4),
      );
    } else if (groups.length == 1) {
      // Strip text part since we handle it below for view
      avatarCluster = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.orange.shade100,
        child: Icon(Icons.view_list_rounded, color: Colors.orange.shade800, size: radius * 1.4),
      ); // Fallback to list icon or we can use the single group's avatar
    } else {
      // Create a stack of 2 or 3 overlapping avatars
      final int count = groups.length > 3 ? 3 : groups.length;
      final double smallRadius = radius * 0.7;
      
      List<Widget> stackChildren = [];
      
      for (int i = count - 1; i >= 0; i--) {
        Widget child;
        if (i == 2 && groups.length > 3) {
          child = CircleAvatar(
            radius: smallRadius,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              '+${groups.length - 2}',
              style: TextStyle(fontSize: smallRadius * 0.9, fontWeight: FontWeight.bold, color: Colors.black87),
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
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
