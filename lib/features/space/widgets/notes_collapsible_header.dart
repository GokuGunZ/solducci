import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/services/note_folder_service.dart';
import 'package:solducci/features/space/widgets/notes_miller_columns_explorer.dart';

class NotesCollapsibleHeader extends StatefulWidget {
  final List<NoteFolder> folders;
  final NoteFolder selectedFolder;
  final List<NoteDocument> notesInSelectedFolder;
  final String? activeNoteId;
  final ValueChanged<NoteFolder> onFolderSelected;
  final ValueChanged<NoteDocument> onNoteSelected;
  final VoidCallback onAddFolder;
  final VoidCallback onAddNote;
  final String? editingNoteId;
  final void Function(NoteFolder currentFolder)? onAddSubfolder;
  final void Function(NoteFolder folder)? onFolderOptions;
  final void Function(NoteDocument doc)? onNoteOptions;
  final void Function(NoteDocument note, String newTitle)? onCommitNoteTitle;
  final bool isExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const NotesCollapsibleHeader({
    super.key,
    required this.folders,
    required this.selectedFolder,
    required this.notesInSelectedFolder,
    required this.activeNoteId,
    this.editingNoteId,
    required this.onFolderSelected,
    required this.onNoteSelected,
    required this.onAddFolder,
    required this.onAddNote,
    this.onAddSubfolder,
    this.onFolderOptions,
    this.onNoteOptions,
    this.onCommitNoteTitle,
    this.isExpanded = false,
    this.onExpansionChanged,
  });

  @override
  State<NotesCollapsibleHeader> createState() => _NotesCollapsibleHeaderState();
}

class _NotesCollapsibleHeaderState extends State<NotesCollapsibleHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _curvedAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant NotesCollapsibleHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    HapticFeedback.lightImpact();
    if (_animController.value > 0.5) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _expand() {
    _animController.forward().then((_) {
      widget.onExpansionChanged?.call(true);
    });
  }

  void _collapse() {
    _animController.reverse().then((_) {
      widget.onExpansionChanged?.call(false);
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double totalRange) {
    if (totalRange <= 0) return;
    final delta = details.primaryDelta ?? 0;
    _animController.value = (_animController.value + (delta / totalRange)).clamp(0.0, 1.0);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final vy = details.primaryVelocity ?? 0;
    if (vy > 350) {
      _expand();
    } else if (vy < -350) {
      _collapse();
    } else {
      if (_animController.value >= 0.45) {
        _expand();
      } else {
        _collapse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final screenHeight = mediaQuery.size.height;

    // Compact height: status bar + top bar (48) + carousel (44) + drag handle (18) = 110 + topPadding
    final compactHeight = topPadding + 110.0;
    // Expanded height: 50% of the screen height, at least 380px
    final expandedHeight = (screenHeight * 0.52).clamp(380.0, 560.0);
    final totalRange = expandedHeight - compactHeight;

    return AnimatedBuilder(
      animation: _curvedAnimation,
      builder: (context, _) {
        final progress = _curvedAnimation.value;
        final currentHeight = lerpDouble(compactHeight, expandedHeight, progress)!;

        return Container(
          height: currentHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF101014),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35 + (0.25 * progress)),
                blurRadius: 16 + (16 * progress),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top Bar
              SizedBox(height: topPadding),
              _buildTopBar(context, progress),

              // Content Area: Either Horizontal Carousel (compact) or Miller Columns (expanded)
              Expanded(
                child: Stack(
                  children: [
                    // Compact Carousel View
                    if (progress < 0.95)
                      Positioned.fill(
                        child: Opacity(
                          opacity: (1.0 - (progress * 2.0)).clamp(0.0, 1.0),
                          child: IgnorePointer(
                            ignoring: progress > 0.3,
                            child: _buildCompactCarousel(),
                          ),
                        ),
                      ),

                    // Expanded 2-Column Miller Finder View
                    if (progress > 0.05)
                      Positioned.fill(
                        child: Opacity(
                          opacity: ((progress - 0.2) / 0.8).clamp(0.0, 1.0),
                          child: IgnorePointer(
                            ignoring: progress < 0.7,
                            child: NotesMillerColumnsExplorer(
                              folders: widget.folders,
                              selectedFolder: widget.selectedFolder,
                              notesInSelectedFolder: widget.notesInSelectedFolder,
                              onFolderSelected: (folder) {
                                widget.onFolderSelected(folder);
                              },
                              onNoteSelected: (note) {
                                widget.onNoteSelected(note);
                                if (widget.editingNoteId != note.id) {
                                  _collapse();
                                }
                              },
                              activeNoteId: widget.activeNoteId,
                              editingNoteId: widget.editingNoteId,
                              onAddFolder: widget.onAddFolder,
                              onAddNote: widget.onAddNote,
                              onAddSubfolder: widget.onAddSubfolder,
                              onFolderOptions: widget.onFolderOptions,
                              onNoteOptions: widget.onNoteOptions,
                              onCommitNoteTitle: widget.onCommitNoteTitle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Drag Handle Bar
              _buildDragHandle(totalRange, progress),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, double progress) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white70),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            visualDensity: VisualDensity.compact,
            tooltip: 'Indietro',
          ),

          const SizedBox(width: 4),

          // Center: Folder Selector Pill (Interactive toggle)
          Expanded(
            child: GestureDetector(
              onTap: _toggleExpansion,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: progress > 0.3
                            ? const Color(0xFFF59E0B).withOpacity(0.4)
                            : Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.selectedFolder.icon,
                          size: 15,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.selectedFolder.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        AnimatedRotation(
                          turns: progress * 0.5, // Rotates 180 degrees when expanded
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (progress > 0.3)
                    Flexible(
                      child: Text(
                        'Esplora note',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action: New Note
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFF59E0B), size: 22),
            onPressed: widget.onAddNote,
            tooltip: 'Nuova nota',
            visualDensity: VisualDensity.compact,
          ),

          // Toggle Expand/Collapse Button
          IconButton(
            icon: Icon(
              progress > 0.5 ? Icons.expand_less_rounded : Icons.folder_open_rounded,
              color: progress > 0.5 ? const Color(0xFFF59E0B) : Colors.white60,
              size: 20,
            ),
            onPressed: _toggleExpansion,
            tooltip: progress > 0.5 ? 'Comprimi' : 'Esplora cartelle',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCarousel() {
    final notes = widget.notesInSelectedFolder;

    if (notes.isEmpty) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              'Nessuna nota in "${widget.selectedFolder.name}"',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: widget.onAddNote,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add, size: 14, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text(
                      'Crea ora',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: notes.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == notes.length) {
            // Add note button at the end of the carousel
            return InkWell(
              onTap: widget.onAddNote,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text(
                      'Nota',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final note = notes[index];
          final isSelected = note.id == widget.activeNoteId;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onNoteSelected(note);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF59E0B).withOpacity(0.18)
                    : const Color(0xFF16161B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF59E0B)
                      : Colors.white.withOpacity(0.08),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFFF59E0B)
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    note.title.trim().isEmpty ? 'Senza titolo' : note.title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle(double totalRange, double progress) {
    return GestureDetector(
      onVerticalDragUpdate: (details) => _onVerticalDragUpdate(details, totalRange),
      onVerticalDragEnd: _onVerticalDragEnd,
      onTap: _toggleExpansion,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 18,
        width: double.infinity,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: progress > 0.5
                ? const Color(0xFFF59E0B).withOpacity(0.7)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
