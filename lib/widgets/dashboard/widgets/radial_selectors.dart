import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/widgets/circular_context_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Representation of a user for radial selector choices
class RadialUserItem {
  final String id;
  final String name;

  const RadialUserItem({required this.id, required this.name});
}

enum RadialOverlayType { user, category, group }

class RadialUserSelector extends StatefulWidget {
  final String label;
  final bool isDefaultAll;
  final ValueChanged<String?>? onPayerChanged;
  final ValueChanged<List<String>>? onSplitMembersChanged;

  const RadialUserSelector({
    super.key,
    required this.label,
    this.isDefaultAll = false,
    this.onPayerChanged,
    this.onSplitMembersChanged,
  });

  @override
  State<RadialUserSelector> createState() => _RadialUserSelectorState();
}

class _RadialUserSelectorState extends State<RadialUserSelector> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<String> _selectedUserIds = [];
  List<RadialUserItem> _loadedMembers = [];

  List<RadialUserItem> get _allUsers {
    if (_loadedMembers.isNotEmpty) {
      return _loadedMembers;
    }
    final ctx = ContextManager().currentContext;
    if (ctx.isGroup && ctx.group != null && ctx.group!.members != null && ctx.group!.members!.isNotEmpty) {
      return ctx.group!.members!
          .map((m) => RadialUserItem(
                id: m.userId,
                name: m.nickname ?? m.email?.split('@').first ?? 'Membro',
              ))
          .toList();
    }
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? 'io';
    return [RadialUserItem(id: currentUserId, name: 'Io')];
  }

  @override
  void initState() {
    super.initState();
    ContextManager().addListener(_loadMembers);
    _loadMembers();
  }

  @override
  void dispose() {
    ContextManager().removeListener(_loadMembers);
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final ctx = ContextManager().currentContext;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? 'io';

    if (ctx.isGroup && ctx.groupId != null) {
      try {
        final members = await GroupServiceCached().getGroupMembers(ctx.groupId!);
        if (members.isNotEmpty && mounted) {
          final items = members
              .map((m) => RadialUserItem(
                    id: m.userId,
                    name: m.nickname ?? m.email?.split('@').first ?? 'Membro',
                  ))
              .toList();
          setState(() {
            _loadedMembers = items;
            if (widget.isDefaultAll) {
              _selectedUserIds = items.map((m) => m.id).toList();
              widget.onSplitMembersChanged?.call(_selectedUserIds);
            } else {
              final defaultPayer = items.any((m) => m.id == currentUserId)
                  ? currentUserId
                  : items.first.id;
              _selectedUserIds = [defaultPayer];
              widget.onPayerChanged?.call(defaultPayer);
            }
          });
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      final defaultUsers = _allUsers;
      setState(() {
        _loadedMembers = defaultUsers;
        if (widget.isDefaultAll) {
          _selectedUserIds = defaultUsers.map((m) => m.id).toList();
          widget.onSplitMembersChanged?.call(_selectedUserIds);
        } else {
          _selectedUserIds = [defaultUsers.first.id];
          widget.onPayerChanged?.call(defaultUsers.first.id);
        }
      });
    }
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    final double centerX = offset.dx + size.width / 2;
    final double centerY = offset.dy + size.height / 2;
    final double menuSize = 320.0;

    double left = centerX - menuSize / 2;
    double top = centerY - menuSize / 2;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Dark backdrop with blur for clean contrast
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  behavior: HitTestBehavior.opaque,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: SizedBox(
                  width: menuSize,
                  height: menuSize,
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      return _RadialMenuOverlay(
                        type: RadialOverlayType.user,
                        onClose: _closeMenu,
                        items: _allUsers.map((u) => u.name).toList(),
                        selectedItems: _selectedUserIds
                            .map((id) => _allUsers.firstWhere((u) => u.id == id, orElse: () => RadialUserItem(id: id, name: id)).name)
                            .toList(),
                        onSelected: (selectedName) {
                          final userItem = _allUsers.firstWhere(
                            (u) => u.name == selectedName,
                            orElse: () => _allUsers.first,
                          );

                          if (widget.isDefaultAll) {
                            // Multi-selection (Per / Beneficiari)
                            setState(() {
                              if (_selectedUserIds.contains(userItem.id)) {
                                if (_selectedUserIds.length > 1) {
                                  _selectedUserIds.remove(userItem.id);
                                }
                              } else {
                                _selectedUserIds.add(userItem.id);
                              }
                            });
                            widget.onSplitMembersChanged?.call(_selectedUserIds);
                            setOverlayState(() {});
                          } else {
                            // Single-selection (Paga / Chi ha pagato)
                            setState(() {
                              _selectedUserIds = [userItem.id];
                            });
                            widget.onPayerChanged?.call(userItem.id);
                            _closeMenu();
                          }
                        },
                        radius: 75,
                        centerPosition: Offset(centerX, centerY),
                        screenSize: screenSize,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  Widget _buildSingleAvatar(String name, double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF6366F1).withOpacity(0.25),
        border: Border.all(color: const Color(0xFF6366F1), width: 1.2),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: TextStyle(
            fontSize: radius * 0.9,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCluster(double baseRadius) {
    final selectedNames = _selectedUserIds
        .map((id) => _allUsers.firstWhere((u) => u.id == id, orElse: () => RadialUserItem(id: id, name: '?')).name)
        .toList();

    if (selectedNames.isEmpty) {
      return _buildSingleAvatar('?', baseRadius);
    } else if (selectedNames.length == 1) {
      return _buildSingleAvatar(selectedNames.first, baseRadius);
    } else if (widget.isDefaultAll && selectedNames.length == _allUsers.length && _allUsers.length > 1) {
      // "Tutti" badge
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF10B981), width: 1),
        ),
        child: const Text(
          'TUTTI',
          style: TextStyle(
            color: Color(0xFF10B981),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else {
      final int count = selectedNames.length > 3 ? 3 : selectedNames.length;
      final double smallRadius = baseRadius * 0.75;

      List<Widget> stackChildren = [];
      for (int i = count - 1; i >= 0; i--) {
        Widget child;
        if (i == 2 && selectedNames.length > 3) {
          child = Container(
            width: smallRadius * 2,
            height: smallRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade800,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Center(
              child: Text(
                '+${selectedNames.length - 2}',
                style: TextStyle(fontSize: smallRadius * 0.85, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          );
        } else {
          child = _buildSingleAvatar(selectedNames[i], smallRadius);
        }

        stackChildren.add(
          Positioned(
            left: i * (baseRadius * 0.85),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: child,
            ),
          ),
        );
      }

      return SizedBox(
        width: baseRadius * 2 + (count - 1) * (baseRadius * 0.85),
        height: baseRadius * 2,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: stackChildren,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _toggleMenu,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _buildAvatarCluster(13.0),
        ],
      ),
    );
  }
}

class RadialCategorySelector extends StatefulWidget {
  final Tipologia selectedCategory;
  final ValueChanged<Tipologia>? onCategoryChanged;

  const RadialCategorySelector({
    super.key,
    this.selectedCategory = Tipologia.cibo,
    this.onCategoryChanged,
  });

  @override
  State<RadialCategorySelector> createState() => _RadialCategorySelectorState();
}

class _RadialCategorySelectorState extends State<RadialCategorySelector> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  IconData get _selectedIcon => CategoryHelpers.getCategoryIcon(widget.selectedCategory);
  Color get _selectedColor => CategoryHelpers.getCategoryColor(widget.selectedCategory);

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    final double centerX = offset.dx + size.width / 2;
    final double centerY = offset.dy + size.height / 2;
    final double menuSize = 320.0;

    double left = centerX - menuSize / 2;
    double top = centerY - menuSize / 2;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  behavior: HitTestBehavior.opaque,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: SizedBox(
                  width: menuSize,
                  height: menuSize,
                  child: _RadialMenuOverlay(
                    type: RadialOverlayType.category,
                    onClose: _closeMenu,
                    items: Tipologia.values.map((t) => t.name).toList(),
                    selectedItems: [widget.selectedCategory.name],
                    onSelected: (catName) {
                      final matched = Tipologia.values.firstWhere(
                        (t) => t.name == catName,
                        orElse: () => Tipologia.cibo,
                      );
                      widget.onCategoryChanged?.call(matched);
                      _closeMenu();
                    },
                    radius: 80,
                    centerPosition: Offset(centerX, centerY),
                    screenSize: screenSize,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _toggleMenu,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Cat:', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedColor.withOpacity(0.2),
              border: Border.all(color: _selectedColor, width: 1.5),
            ),
            child: Center(
              child: Icon(_selectedIcon, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class RadialGroupSelector extends StatefulWidget {
  final String label;
  final ValueChanged<String?>? onGroupChanged;

  const RadialGroupSelector({super.key, required this.label, this.onGroupChanged});

  @override
  State<RadialGroupSelector> createState() => _RadialGroupSelectorState();
}

class _RadialGroupSelectorState extends State<RadialGroupSelector> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String? _selectedGroupId;

  List<ExpenseGroup> get _availableGroups {
    final ctx = ContextManager().currentContext;
    if (ctx.isView) {
      return ctx.view?.groups ?? [];
    }
    return [];
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final groups = _availableGroups;
    if (groups.isEmpty) return;

    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    final double centerX = offset.dx + size.width / 2;
    final double centerY = offset.dy + size.height / 2;
    final double menuSize = 320.0;

    double left = centerX - menuSize / 2;
    double top = centerY - menuSize / 2;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  behavior: HitTestBehavior.opaque,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: SizedBox(
                  width: menuSize,
                  height: menuSize,
                  child: _RadialMenuOverlay(
                    type: RadialOverlayType.group,
                    onClose: _closeMenu,
                    items: groups.map((g) => g.name).toList(),
                    selectedItems: [
                      if (_selectedGroupId != null)
                        groups.firstWhere((g) => g.id == _selectedGroupId, orElse: () => groups.first).name
                      else
                        groups.first.name
                    ],
                    onSelected: (groupName) {
                      final g = groups.firstWhere((g) => g.name == groupName);
                      setState(() {
                        _selectedGroupId = g.id;
                      });
                      widget.onGroupChanged?.call(g.id);
                      _closeMenu();
                    },
                    radius: 75,
                    centerPosition: Offset(centerX, centerY),
                    screenSize: screenSize,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _availableGroups;
    if (groups.isEmpty) return const SizedBox.shrink();

    if (_selectedGroupId == null || !groups.any((g) => g.id == _selectedGroupId)) {
      _selectedGroupId = groups.first.id;
    }

    final selectedGroup = groups.firstWhere((g) => g.id == _selectedGroupId);

    return GestureDetector(
      key: _key,
      onTap: _toggleMenu,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          CircularContextAvatar(
            expenseContext: ExpenseContext.group(selectedGroup),
            radius: 14,
            showLabel: false,
          ),
        ],
      ),
    );
  }
}

class _RadialMenuOverlay extends StatefulWidget {
  final RadialOverlayType type;
  final VoidCallback onClose;
  final List<String> items;
  final List<String> selectedItems;
  final Function(String) onSelected;
  final double radius;
  final Offset centerPosition;
  final Size screenSize;

  const _RadialMenuOverlay({
    required this.type,
    required this.onClose,
    required this.items,
    required this.selectedItems,
    required this.onSelected,
    required this.centerPosition,
    required this.screenSize,
    this.radius = 70.0,
  });

  @override
  State<_RadialMenuOverlay> createState() => _RadialMenuOverlayState();
}

class _RadialMenuOverlayState extends State<_RadialMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double startAngle = -pi / 2;
        double sweepAngle = 2 * pi;

        bool overflowRight = widget.centerPosition.dx + widget.radius + 40 > widget.screenSize.width;
        bool overflowLeft = widget.centerPosition.dx - widget.radius - 40 < 0;
        bool overflowTop = widget.centerPosition.dy - widget.radius - 40 < 0;
        bool overflowBottom = widget.centerPosition.dy + widget.radius + 40 > widget.screenSize.height;

        if (overflowRight && overflowTop) {
          startAngle = pi / 2; sweepAngle = pi / 2;
        } else if (overflowRight && overflowBottom) {
          startAngle = pi; sweepAngle = pi / 2;
        } else if (overflowLeft && overflowTop) {
          startAngle = 0; sweepAngle = pi / 2;
        } else if (overflowLeft && overflowBottom) {
          startAngle = -pi / 2; sweepAngle = pi / 2;
        } else if (overflowRight) {
          startAngle = pi / 2; sweepAngle = pi;
        } else if (overflowLeft) {
          startAngle = -pi / 2; sweepAngle = pi;
        } else if (overflowTop) {
          startAngle = 0; sweepAngle = pi;
        } else if (overflowBottom) {
          startAngle = pi; sweepAngle = pi;
        }

        final int total = widget.items.length;
        final double angleStep = sweepAngle >= 2 * pi - 0.01
            ? (sweepAngle / (total > 0 ? total : 1))
            : (sweepAngle / (total > 1 ? total - 1 : 1));

        double targetRadius = widget.radius;
        if (total > 1 && angleStep > 0) {
          double requiredChord = widget.type == RadialOverlayType.category ? 46.0 : 54.0;
          double minRadius = requiredChord / (2 * sin(angleStep / 2));
          if (minRadius > targetRadius) {
            targetRadius = minRadius;
          }
          if (targetRadius > 135.0) targetRadius = 135.0;
        }

        final currentRadius = targetRadius * CurvedAnimation(parent: _controller, curve: Curves.easeOutBack).value;
        final borderThickness = 48.0;
        final containerSize = (currentRadius + borderThickness / 2) * 2;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (currentRadius > 0)
              Opacity(
                opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut).value,
                child: Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: borderThickness,
                    ),
                  ),
                ),
              ),
            for (int i = 0; i < widget.items.length; i++)
              _buildRadialItem(i, startAngle, angleStep, currentRadius),
          ],
        );
      },
    );
  }

  Widget _buildRadialItem(int index, double startAngle, double angleStep, double currentRadius) {
    final angle = startAngle + angleStep * index;
    final dx = currentRadius * cos(angle);
    final dy = currentRadius * sin(angle);

    final item = widget.items[index];
    final isSelected = widget.selectedItems.contains(item);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut).value,
        child: GestureDetector(
          onTap: () => widget.onSelected(item),
          behavior: HitTestBehavior.opaque,
          child: switch (widget.type) {
            RadialOverlayType.user => _buildUserItem(item, isSelected),
            RadialOverlayType.category => _buildCategoryItem(item, isSelected),
            RadialOverlayType.group => _buildGroupItem(item, isSelected),
          },
        ),
      ),
    );
  }

  Widget _buildUserItem(String name, bool isSelected) {
    final accent = isSelected ? const Color(0xFF10B981) : const Color(0xFF6366F1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(isSelected ? 0.35 : 0.18),
            border: Border.all(
              color: accent,
              width: isSelected ? 2.5 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(color: accent.withOpacity(0.4), blurRadius: 10, spreadRadius: 1),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? accent : Colors.white24, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            name,
            style: TextStyle(
              color: isSelected ? accent : Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String catName, bool isSelected) {
    final tipologia = Tipologia.values.firstWhere(
      (t) => t.name.toLowerCase() == catName.toLowerCase() || t.label.toLowerCase() == catName.toLowerCase(),
      orElse: () => Tipologia.altro,
    );
    final icon = CategoryHelpers.getCategoryIcon(tipologia);
    final color = CategoryHelpers.getCategoryColor(tipologia);
    final label = CategoryHelpers.getCategoryLabel(tipologia);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(isSelected ? 0.35 : 0.18),
            border: Border.all(color: color, width: isSelected ? 2.2 : 1.2),
            boxShadow: isSelected
                ? [
                    BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, spreadRadius: 1),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? color : Colors.white24, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupItem(String groupName, bool isSelected) {
    const accent = Color(0xFF38BDF8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(isSelected ? 0.35 : 0.18),
            border: Border.all(color: accent, width: isSelected ? 2.2 : 1.2),
            boxShadow: isSelected
                ? [
                    BoxShadow(color: accent.withOpacity(0.4), blurRadius: 10, spreadRadius: 1),
                  ]
                : null,
          ),
          child: const Center(
            child: Icon(Icons.group_rounded, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? accent : Colors.white24, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            groupName,
            style: TextStyle(
              color: isSelected ? accent : Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
