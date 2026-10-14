import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

/// Compact Premium Filter & Sort Bar - Solution 8
/// Single-line floating pills with interactive chips
class CompactFilterSortBar extends StatefulWidget {
  final FilterSortConfig filterConfig;
  final ValueChanged<FilterSortConfig> onFilterChanged;
  final List<Tag>? availableTags; // Optional: if provided, tag filter will be enabled

  const CompactFilterSortBar({
    super.key,
    required this.filterConfig,
    required this.onFilterChanged,
    this.availableTags,
  });

  @override
  State<CompactFilterSortBar> createState() => _CompactFilterSortBarState();
}

class _CompactFilterSortBarState extends State<CompactFilterSortBar> {
  late FilterSortConfig _internalConfig;

  @override
  void initState() {
    super.initState();
    _internalConfig = widget.filterConfig;
  }

  @override
  void didUpdateWidget(CompactFilterSortBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update only if the parent changed the config externally
    if (widget.filterConfig != oldWidget.filterConfig) {
      _internalConfig = widget.filterConfig;
    }
  }

  void _updateFilter(FilterSortConfig newConfig) {
    // Update internal state immediately (no parent rebuild)
    setState(() {
      _internalConfig = newConfig;
    });
    // Notify parent to update the list only
    widget.onFilterChanged(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isola il widget per evitare repaint inutili
    return RepaintBoundary(
      child: Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Filter container - single line with icon and chips
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141417),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt,
                          size: 18, color: Color(0xFF818CF8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildFilterChip(
                              context: context,
                              icon: Icons.flag,
                              label: _getPriorityLabels(_internalConfig.priorities),
                              color: _internalConfig.priorities.isEmpty
                                  ? null
                                  : const Color(0xFF8B5CF6),
                              onTap: () => _showPriorityFilter(context),
                            ),
                            _buildFilterChip(
                              context: context,
                              icon: Icons.check_circle,
                              label: _getStatusLabels(_internalConfig.statuses),
                              color: _internalConfig.statuses.isEmpty
                                  ? null
                                  : const Color(0xFF38BDF8),
                              onTap: () => _showStatusFilter(context),
                            ),
                            _buildFilterChip(
                              context: context,
                              icon: Icons.straighten,
                              label: _getSizeLabels(_internalConfig.sizes),
                              color: _internalConfig.sizes.isEmpty
                                  ? null
                                  : const Color(0xFFFB923C),
                              onTap: () => _showSizeFilter(context),
                            ),
                            _buildFilterChip(
                              context: context,
                              icon: Icons.calendar_today,
                              label: _internalConfig.dateFilter?.label,
                              color: _internalConfig.dateFilter == null
                                  ? null
                                  : const Color(0xFF2DD4BF),
                              onTap: () => _showDateFilter(context),
                            ),
                            _buildFilterChip(
                              context: context,
                              icon: Icons.label,
                              label: _internalConfig.tagIds.isEmpty
                                  ? null
                                  : '${_internalConfig.tagIds.length}',
                              color: _internalConfig.tagIds.isEmpty
                                  ? null
                                  : const Color(0xFF34D399),
                              onTap: () => _showTagFilter(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sort container - single line with icon and chips (aligned right)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141417),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      // Clear sort button on the left if active
                      if (_internalConfig.sortBy != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: _clearSort,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end, // Align chips to the right
                          children: [
                            _buildSortChip(
                              icon: Icons.calendar_today,
                              label: 'Data',
                              value: TaskSortOption.dueDate,
                              onTap: () => _toggleSort(TaskSortOption.dueDate),
                            ),
                            _buildSortChip(
                              icon: Icons.priority_high,
                              label: 'Priorità',
                              value: TaskSortOption.priority,
                              onTap: () => _toggleSort(TaskSortOption.priority),
                            ),
                            _buildSortChip(
                              icon: Icons.straighten,
                              label: 'Dimensione',
                              value: TaskSortOption.size,
                              onTap: () => _toggleSort(TaskSortOption.size),
                            ),
                            _buildSortChip(
                              icon: Icons.sort_by_alpha,
                              label: 'Nome',
                              value: TaskSortOption.title,
                              onTap: () => _toggleSort(TaskSortOption.title),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.sort, size: 18, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  String? _getPriorityLabels(Set<TaskPriority> priorities) {
    if (priorities.isEmpty) return null;

    final labels = priorities.map((p) {
      switch (p) {
        case TaskPriority.urgent:
          return 'Urgente';
        case TaskPriority.high:
          return 'Alta';
        case TaskPriority.medium:
          return 'Media';
        case TaskPriority.low:
          return 'Bassa';
      }
    }).toList();

    return labels.join(', ');
  }

  String? _getStatusLabels(Set<TaskStatus> statuses) {
    if (statuses.isEmpty) return null;

    final labels = statuses.map((s) {
      switch (s) {
        case TaskStatus.pending:
          return 'Pending';
        case TaskStatus.inProgress:
          return 'In Progress';
        case TaskStatus.assigned:
          return 'Assigned';
        case TaskStatus.completed:
          return 'Completed';
      }
    }).toList();

    return labels.join(', ');
  }

  String? _getSizeLabels(Set<TShirtSize> sizes) {
    if (sizes.isEmpty) return null;

    final labels = sizes.map((s) => s.label).toList();
    return labels.join(', ');
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required IconData icon,
    String? label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final bool hasActiveFilter = label != null && color != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: hasActiveFilter ? 10 : 6,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: hasActiveFilter
              ? color.withOpacity(0.25)
              : const Color(0xFF1C1C21),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasActiveFilter ? color : Colors.white12,
            width: 1,
          ),
          boxShadow: hasActiveFilter
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: hasActiveFilter ? Colors.white : Colors.white54,
            ),
            if (hasActiveFilter) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required IconData icon,
    required String label,
    required TaskSortOption value,
    required VoidCallback onTap,
  }) {
    final bool isActive = _internalConfig.sortBy == value;
    final bool ascending = _internalConfig.sortAscending;
    const accent = Color(0xFF34D399); // Emerald neon

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 10 : 6,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? accent.withOpacity(0.25)
              : const Color(0xFF1C1C21),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? accent : Colors.white12,
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : Colors.white54,
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleSort(TaskSortOption sortBy) {
    if (_internalConfig.sortBy == sortBy) {
      // Toggle ascending/descending
      _updateFilter(_internalConfig.copyWith(
        sortAscending: !_internalConfig.sortAscending,
      ));
    } else {
      // Set new sort field (default ascending)
      _updateFilter(_internalConfig.copyWith(
        sortBy: sortBy,
        sortAscending: true,
      ));
    }
  }

  void _clearSort() {
    _updateFilter(_internalConfig.copyWith(
      clearSortBy: true,
      sortAscending: true,
    ));
  }

  void _showPriorityFilter(BuildContext context) {
    // Find the RenderBox of the chip to position the dropdown
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final overlayPosition = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _FadeScaleDropdown(
        position: overlayPosition,
        onClose: () {
          overlayEntry.remove();
        },
        child: _PriorityFilterContent(
          selectedPriorities: _internalConfig.priorities,
          onChanged: (newSet) {
            _updateFilter(_internalConfig.copyWith(
              priorities: newSet,
            ));
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _showStatusFilter(BuildContext context) {
    // Find the RenderBox of the chip to position the dropdown
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final overlayPosition = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _FadeScaleDropdown(
        position: overlayPosition,
        onClose: () {
          overlayEntry.remove();
        },
        child: _StatusFilterContent(
          selectedStatuses: _internalConfig.statuses,
          onChanged: (newSet) {
            _updateFilter(_internalConfig.copyWith(
              statuses: newSet,
            ));
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _showSizeFilter(BuildContext context) {
    // Find the RenderBox of the chip to position the dropdown
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final overlayPosition = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _FadeScaleDropdown(
        position: overlayPosition,
        onClose: () {
          overlayEntry.remove();
        },
        child: _SizeFilterContent(
          selectedSizes: _internalConfig.sizes,
          onChanged: (newSet) {
            _updateFilter(_internalConfig.copyWith(
              sizes: newSet,
            ));
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _showDateFilter(BuildContext context) {
    // Find the RenderBox of the chip to position the dropdown
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final overlayPosition = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _FadeScaleDropdown(
        position: overlayPosition,
        onClose: () {
          overlayEntry.remove();
        },
        child: _DateFilterContent(
          selectedDate: _internalConfig.dateFilter,
          onChanged: (newFilter) {
            _updateFilter(_internalConfig.copyWith(
              dateFilter: newFilter,
              clearDateFilter: newFilter == null,
            ));
            overlayEntry.remove();
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _showTagFilter(BuildContext context) {
    // Check if tags are available
    if (widget.availableTags == null || widget.availableTags!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun tag disponibile')),
      );
      return;
    }

    // Find the RenderBox of the chip to position the dropdown
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final overlayPosition = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _FadeScaleDropdown(
        position: overlayPosition,
        onClose: () {
          overlayEntry.remove();
        },
        child: _TagFilterContent(
          availableTags: widget.availableTags!,
          selectedTagIds: _internalConfig.tagIds,
          onChanged: (newSet) {
            _updateFilter(_internalConfig.copyWith(
              tagIds: newSet,
            ));
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

// ========== FADE & SCALE DROPDOWN (Solution 2) ==========

/// Animated dropdown overlay with fade and scale animation
class _FadeScaleDropdown extends StatefulWidget {
  final Offset position;
  final VoidCallback onClose;
  final Widget child;

  const _FadeScaleDropdown({
    required this.position,
    required this.onClose,
    required this.child,
  });

  @override
  State<_FadeScaleDropdown> createState() => _FadeScaleDropdownState();
}

class _FadeScaleDropdownState extends State<_FadeScaleDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double menuWidth = 240.0;
    final double left = (widget.position.dx + menuWidth > screenWidth - 16)
        ? (screenWidth - menuWidth - 16).clamp(16.0, screenWidth)
        : widget.position.dx.clamp(16.0, screenWidth - menuWidth - 16);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: widget.onClose,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Transparent background to capture outside taps
            Container(color: Colors.transparent),
            // Positioned dropdown
            Positioned(
              left: left,
              top: widget.position.dy + 46,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: Alignment.topLeft,
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable container for filter modal dropdowns with refined OLED sfumato
class _FilterModalContainer extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;

  const _FilterModalContainer({
    required this.title,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF22222A), accentColor, 0.16)!,
                  const Color(0xFF141417),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.8),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable row item for filter dropdown options
class _FilterOptionItem extends StatelessWidget {
  final String label;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterOptionItem({
    required this.label,
    required this.activeColor,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: activeColor.withOpacity(0.35), width: 1.0)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFF26262D),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? activeColor : Colors.white24,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? activeColor : Colors.white54,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Priority filter content widget
class _PriorityFilterContent extends StatefulWidget {
  final Set<TaskPriority> selectedPriorities;
  final ValueChanged<Set<TaskPriority>> onChanged;

  const _PriorityFilterContent({
    required this.selectedPriorities,
    required this.onChanged,
  });

  @override
  State<_PriorityFilterContent> createState() => _PriorityFilterContentState();
}

class _PriorityFilterContentState extends State<_PriorityFilterContent> {
  late Set<TaskPriority> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedPriorities);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF818CF8);
    return _FilterModalContainer(
      title: 'Priorità',
      accentColor: accent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: TaskPriority.values.map((priority) {
          final isSelected = _selected.contains(priority);
          return _FilterOptionItem(
            label: priority.label,
            activeColor: priority.color,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selected.remove(priority);
                } else {
                  _selected.add(priority);
                }
              });
              widget.onChanged(_selected);
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Status filter content widget
class _StatusFilterContent extends StatefulWidget {
  final Set<TaskStatus> selectedStatuses;
  final ValueChanged<Set<TaskStatus>> onChanged;

  const _StatusFilterContent({
    required this.selectedStatuses,
    required this.onChanged,
  });

  @override
  State<_StatusFilterContent> createState() => _StatusFilterContentState();
}

class _StatusFilterContentState extends State<_StatusFilterContent> {
  late Set<TaskStatus> _selected;

  final Map<TaskStatus, String> _statusLabels = {
    TaskStatus.pending: 'In attesa',
    TaskStatus.assigned: 'Assegnata',
    TaskStatus.inProgress: 'In corso',
  };

  final Map<TaskStatus, Color> _statusColors = {
    TaskStatus.pending: const Color(0xFF94A3B8),
    TaskStatus.assigned: const Color(0xFF60A5FA),
    TaskStatus.inProgress: const Color(0xFFFBBF24),
  };

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedStatuses);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF60A5FA);
    return _FilterModalContainer(
      title: 'Stato',
      accentColor: accent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _statusLabels.entries.map((entry) {
          final status = entry.key;
          final label = entry.value;
          final color = _statusColors[status]!;
          final isSelected = _selected.contains(status);

          return _FilterOptionItem(
            label: label,
            activeColor: color,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selected.remove(status);
                } else {
                  _selected.add(status);
                }
              });
              widget.onChanged(_selected);
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Size filter content widget
class _SizeFilterContent extends StatefulWidget {
  final Set<TShirtSize> selectedSizes;
  final ValueChanged<Set<TShirtSize>> onChanged;

  const _SizeFilterContent({
    required this.selectedSizes,
    required this.onChanged,
  });

  @override
  State<_SizeFilterContent> createState() => _SizeFilterContentState();
}

class _SizeFilterContentState extends State<_SizeFilterContent> {
  late Set<TShirtSize> _selected;

  final Map<TShirtSize, Color> _sizeColors = {
    TShirtSize.xs: const Color(0xFF34D399),
    TShirtSize.s: const Color(0xFF4ADE80),
    TShirtSize.m: const Color(0xFFFBBF24),
    TShirtSize.l: const Color(0xFFFB923C),
    TShirtSize.xl: const Color(0xFFF87171),
  };

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedSizes);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFB923C);
    return _FilterModalContainer(
      title: 'Dimensione',
      accentColor: accent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: TShirtSize.values.map((size) {
          final isSelected = _selected.contains(size);
          final color = _sizeColors[size]!;

          return _FilterOptionItem(
            label: size.label,
            activeColor: color,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selected.remove(size);
                } else {
                  _selected.add(size);
                }
              });
              widget.onChanged(_selected);
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Date filter content widget
class _DateFilterContent extends StatelessWidget {
  final DateFilterOption? selectedDate;
  final ValueChanged<DateFilterOption?> onChanged;

  const _DateFilterContent({
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2DD4BF);
    return _FilterModalContainer(
      title: 'Data di scadenza',
      accentColor: accent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: DateFilterOption.values.map((option) {
          final isSelected = selectedDate == option;

          return _FilterOptionItem(
            label: option.label,
            activeColor: accent,
            isSelected: isSelected,
            onTap: () {
              onChanged(isSelected ? null : option);
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Tag filter content widget
class _TagFilterContent extends StatefulWidget {
  final List<Tag> availableTags;
  final Set<String> selectedTagIds;
  final ValueChanged<Set<String>> onChanged;

  const _TagFilterContent({
    required this.availableTags,
    required this.selectedTagIds,
    required this.onChanged,
  });

  @override
  State<_TagFilterContent> createState() => _TagFilterContentState();
}

class _TagFilterContentState extends State<_TagFilterContent> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedTagIds);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF34D399);
    return _FilterModalContainer(
      title: 'Tag',
      accentColor: accent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.availableTags.map((tag) {
              final isSelected = _selected.contains(tag.id);
              final color = tag.colorObject ?? accent;

              return _FilterOptionItem(
                label: tag.name,
                activeColor: color,
                isSelected: isSelected,
                icon: tag.iconData,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selected.remove(tag.id);
                    } else {
                      _selected.add(tag.id);
                    }
                  });
                  widget.onChanged(_selected);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

