import 'package:flutter/material.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/utils/app_image_helper.dart';

/// Group Avatar component that:
/// 1. Displays the custom group image if set (supporting URLs & base64)
/// 2. Defaults to a 4-quadrant mosaic composition of the participants' avatars/initials
class GroupMosaicAvatar extends StatelessWidget {
  final ExpenseGroup group;
  final double radius;
  final List<GroupMember>? members;
  final bool showBorder;
  final Color? borderColor;

  const GroupMosaicAvatar({
    super.key,
    required this.group,
    this.radius = 20.0,
    this.members,
    this.showBorder = false,
    this.borderColor,
  });

  static const List<Color> _quadrantColors = [
    Color(0xFF059669), // Emerald
    Color(0xFF4F46E5), // Indigo
    Color(0xFFD97706), // Amber
    Color(0xFFDB2777), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;

    Widget avatarContent;

    // 1. If group has its own custom image, show it directly
    if (group.imageUrl != null && group.imageUrl!.trim().isNotEmpty) {
      final imageProvider = AppImageHelper.getImageProvider(group.imageUrl);
      avatarContent = Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10B981).withOpacity(0.2),
          image: imageProvider != null
              ? DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageProvider == null
            ? _buildFallbackInitials(group.initials)
            : null,
      );
    } else if (members != null) {
      // 2. Members are preloaded
      avatarContent = _buildMosaicFromMembers(members!);
    } else {
      // 3. Fetch members via cache/service
      avatarContent = FutureBuilder<List<GroupMember>>(
        future: GroupServiceCached().getGroupMembers(group.id),
        builder: (context, snapshot) {
          final loadedMembers = snapshot.data ?? group.members;
          if (loadedMembers == null || loadedMembers.isEmpty) {
            return _buildFallbackInitials(group.initials);
          }
          return _buildMosaicFromMembers(loadedMembers);
        },
      );
    }

    if (showBorder) {
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.12),
            width: 1.5,
          ),
        ),
        child: ClipOval(child: avatarContent),
      );
    }

    return SizedBox(
      width: diameter,
      height: diameter,
      child: ClipOval(child: avatarContent),
    );
  }

  Widget _buildFallbackInitials(String initials) {
    return Container(
      color: const Color(0xFF10B981).withOpacity(0.2),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: const Color(0xFF34D399),
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }

  Widget _buildMosaicFromMembers(List<GroupMember> memberList) {
    final effectiveMembers = memberList.take(4).toList();

    if (effectiveMembers.isEmpty) {
      return _buildFallbackInitials(group.initials);
    }

    if (effectiveMembers.length == 1) {
      return _buildParticipantTile(effectiveMembers[0], 0, isSingle: true);
    }

    if (effectiveMembers.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildParticipantTile(effectiveMembers[0], 0)),
          Container(width: 1, color: const Color(0xFF18181D)),
          Expanded(child: _buildParticipantTile(effectiveMembers[1], 1)),
        ],
      );
    }

    if (effectiveMembers.length == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildParticipantTile(effectiveMembers[0], 0)),
                Container(width: 1, color: const Color(0xFF18181D)),
                Expanded(child: _buildParticipantTile(effectiveMembers[1], 1)),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFF18181D)),
          Expanded(
            child: _buildParticipantTile(effectiveMembers[2], 2),
          ),
        ],
      );
    }

    // 4 members (2x2 grid)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildParticipantTile(effectiveMembers[0], 0)),
              Container(width: 1, color: const Color(0xFF18181D)),
              Expanded(child: _buildParticipantTile(effectiveMembers[1], 1)),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFF18181D)),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildParticipantTile(effectiveMembers[2], 2)),
              Container(width: 1, color: const Color(0xFF18181D)),
              Expanded(child: _buildParticipantTile(effectiveMembers[3], 3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(
    GroupMember member,
    int index, {
    bool isSingle = false,
  }) {
    final color = _quadrantColors[index % _quadrantColors.length];
    final avatarUrl = member.avatarUrl?.trim();

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      final imageProvider = AppImageHelper.getImageProvider(avatarUrl);
      if (imageProvider != null) {
        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildParticipantInitialTile(member, color, isSingle),
        );
      }
    }

    return _buildParticipantInitialTile(member, color, isSingle);
  }

  Widget _buildParticipantInitialTile(
    GroupMember member,
    Color bgColor,
    bool isSingle,
  ) {
    final fontSize = isSingle ? radius * 0.9 : radius * 0.45;

    return Container(
      color: bgColor.withOpacity(0.35),
      alignment: Alignment.center,
      child: Text(
        member.initials,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
