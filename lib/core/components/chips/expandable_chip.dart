import 'package:flutter/material.dart';

/// Generic chip that expands to show additional content when selected
///
/// A versatile chip component with smooth slide-in/out animations for expanded content.
/// The chip consists of two parts:
/// - **Base content**: Always visible, typically shows item identification (avatar, name, etc.)
/// - **Expanded content**: Slides in from the right when selected, can contain any interactive widgets
///
/// ## Type Parameters
/// - `T`: Type of the data item this chip represents
///
/// ## Features
/// - Smooth slide-in/out animation (250ms) using ClipRect + AnimatedAlign
/// - Builder pattern for flexible content customization
/// - Dynamic sizing based on content (uses IntrinsicWidth)
/// - Selection state management
/// - Configurable colors for selected/unselected states
/// - Optional divider between base and expanded sections
///
/// ## Example
///
/// ```dart
/// class User {
///   final String id;
///   final String name;
///   final String avatarUrl;
/// }
///
/// ExpandableChip<User>(
///   item: user,
///   isSelected: selectedUsers.contains(user.id),
///   baseContentBuilder: (context, user) => Row(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
///       SizedBox(width: 8),
///       Text(user.name),
///     ],
///   ),
///   expandedContentBuilder: (context, user) => Row(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       TextField(
///         decoration: InputDecoration(hintText: 'Amount'),
///         keyboardType: TextInputType.number,
///       ),
///       IconButton(
///         icon: Icon(Icons.check),
///         onPressed: () => print('Confirmed for ${user.name}'),
///       ),
///     ],
///   ),
///   onSelectionChanged: (selected) {
///     setState(() {
///       if (selected) {
///         selectedUsers.add(user.id);
///       } else {
///         selectedUsers.remove(user.id);
///       }
///     });
///   },
/// )
/// ```
///
/// ## Design Patterns
/// - **Builder Pattern**: Flexible content construction via builder functions
/// - **Composite Pattern**: Combines multiple widgets into cohesive unit
/// - **Template Method**: Defines structure while allowing customization
class ExpandableChip<T> extends StatelessWidget {
  /// The data item this chip represents
  final T item;

  /// Whether the chip is selected (expanded)
  final bool isSelected;

  /// Builder for the base chip content (always visible)
  ///
  /// This should typically contain:
  /// - An avatar or icon
  /// - Item name or identifier
  /// - Any badges or status indicators
  ///
  /// The content is displayed on the left side and is always visible.
  final Widget Function(BuildContext context, T item) baseContentBuilder;

  /// Builder for the expanded content (slides in when selected)
  ///
  /// This can contain any interactive widgets:
  /// - Text fields for input
  /// - Action buttons
  /// - Additional information
  /// - Dropdown menus
  ///
  /// The content slides in from the right when the chip is selected.
  final Widget Function(BuildContext context, T item) expandedContentBuilder;

  /// Callback when selection state changes
  ///
  /// Called when the user taps the base chip area.
  final ValueChanged<bool> onSelectionChanged;

  /// Background color when selected
  final Color? selectedBackgroundColor;

  /// Background color when not selected
  final Color? unselectedBackgroundColor;

  /// Border color when selected
  final Color? selectedBorderColor;

  /// Border color when not selected
  final Color? unselectedBorderColor;

  /// Border width when selected
  final double selectedBorderWidth;

  /// Border width when not selected
  final double unselectedBorderWidth;

  /// Border radius for the chip
  final double borderRadius;

  /// Animation duration for expand/collapse
  final Duration animationDuration;

  /// Whether to show a divider between base and expanded content
  final bool showDivider;

  /// Color of the divider
  final Color? dividerColor;

  /// Width of the divider
  final double dividerWidth;

  /// Height of the divider
  final double dividerHeight;

  /// Padding for the base content
  final EdgeInsets baseContentPadding;

  /// Padding for the expanded content
  final EdgeInsets expandedContentPadding;

  const ExpandableChip({
    super.key,
    required this.item,
    required this.isSelected,
    required this.baseContentBuilder,
    required this.expandedContentBuilder,
    required this.onSelectionChanged,
    this.selectedBackgroundColor,
    this.unselectedBackgroundColor,
    this.selectedBorderColor,
    this.unselectedBorderColor,
    this.selectedBorderWidth = 2,
    this.unselectedBorderWidth = 1,
    this.borderRadius = 20,
    this.animationDuration = const Duration(milliseconds: 250),
    this.showDivider = true,
    this.dividerColor,
    this.dividerWidth = 1,
    this.dividerHeight = 24,
    this.baseContentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    this.expandedContentPadding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 8,
    ),
  });

  @override
  Widget build(BuildContext context) {
    // Default colors based on theme
    final defaultSelectedBg = Colors.blue.shade50;
    final defaultUnselectedBg = Colors.grey.shade100;
    final defaultSelectedBorder = Colors.blue.shade300;
    final defaultUnselectedBorder = Colors.grey.shade300;
    final defaultDividerColor = Colors.grey.shade300;

    final backgroundColor = isSelected
        ? (selectedBackgroundColor ?? defaultSelectedBg)
        : (unselectedBackgroundColor ?? defaultUnselectedBg);

    final borderColor = isSelected
        ? (selectedBorderColor ?? defaultSelectedBorder)
        : (unselectedBorderColor ?? defaultUnselectedBorder);

    final borderWidth =
        isSelected ? selectedBorderWidth : unselectedBorderWidth;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Base chip (always visible)
        GestureDetector(
          onTap: () => onSelectionChanged(!isSelected),
          child: Container(
            padding: baseContentPadding,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              borderRadius: isSelected
                  ? BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      bottomLeft: Radius.circular(borderRadius),
                    )
                  : BorderRadius.circular(borderRadius),
            ),
            child: baseContentBuilder(context, item),
          ),
        ),

        // Expanded content (animated slide-in/out)
        ClipRect(
          child: AnimatedAlign(
            duration: animationDuration,
            curve: Curves.easeInOut,
            alignment: Alignment.centerLeft,
            widthFactor: isSelected ? 1.0 : 0.0,
            child: Container(
              padding: expandedContentPadding,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: borderWidth),
                  right: BorderSide(color: borderColor, width: borderWidth),
                  bottom: BorderSide(color: borderColor, width: borderWidth),
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(borderRadius),
                  bottomRight: Radius.circular(borderRadius),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Divider (optional)
                  if (showDivider)
                    Container(
                      width: dividerWidth,
                      height: dividerHeight,
                      color: dividerColor ?? defaultDividerColor,
                      margin: const EdgeInsets.only(right: 6),
                    ),

                  // Expanded content
                  expandedContentBuilder(context, item),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Preset color schemes for [ExpandableChip]
///
/// Provides common color combinations for quick styling.
class ExpandableChipColors {
  /// Blue theme (default)
  static const blue = ExpandableChipColorScheme(
    selectedBackground: Color(0xFFEBF5FF),
    unselectedBackground: Color(0xFFF3F4F6),
    selectedBorder: Color(0xFF93C5FD),
    unselectedBorder: Color(0xFFD1D5DB),
  );

  /// Green theme
  static const green = ExpandableChipColorScheme(
    selectedBackground: Color(0xFFD1FAE5),
    unselectedBackground: Color(0xFFF3F4F6),
    selectedBorder: Color(0xFF6EE7B7),
    unselectedBorder: Color(0xFFD1D5DB),
  );

  /// Red theme
  static const red = ExpandableChipColorScheme(
    selectedBackground: Color(0xFFFEE2E2),
    unselectedBackground: Color(0xFFF3F4F6),
    selectedBorder: Color(0xFFFCA5A5),
    unselectedBorder: Color(0xFFD1D5DB),
  );

  /// Purple theme
  static const purple = ExpandableChipColorScheme(
    selectedBackground: Color(0xFFF3E8FF),
    unselectedBackground: Color(0xFFF3F4F6),
    selectedBorder: Color(0xFFD8B4FE),
    unselectedBorder: Color(0xFFD1D5DB),
  );

  /// Amber theme
  static const amber = ExpandableChipColorScheme(
    selectedBackground: Color(0xFFFEF3C7),
    unselectedBackground: Color(0xFFF3F4F6),
    selectedBorder: Color(0xFFFDE68A),
    unselectedBorder: Color(0xFFD1D5DB),
  );
}

/// Color scheme configuration for [ExpandableChip]
class ExpandableChipColorScheme {
  final Color selectedBackground;
  final Color unselectedBackground;
  final Color selectedBorder;
  final Color unselectedBorder;

  const ExpandableChipColorScheme({
    required this.selectedBackground,
    required this.unselectedBackground,
    required this.selectedBorder,
    required this.unselectedBorder,
  });

  /// Apply this color scheme to an [ExpandableChip]
  ExpandableChip<T> apply<T>(ExpandableChip<T> chip) {
    return ExpandableChip<T>(
      item: chip.item,
      isSelected: chip.isSelected,
      baseContentBuilder: chip.baseContentBuilder,
      expandedContentBuilder: chip.expandedContentBuilder,
      onSelectionChanged: chip.onSelectionChanged,
      selectedBackgroundColor: selectedBackground,
      unselectedBackgroundColor: unselectedBackground,
      selectedBorderColor: selectedBorder,
      unselectedBorderColor: unselectedBorder,
      selectedBorderWidth: chip.selectedBorderWidth,
      unselectedBorderWidth: chip.unselectedBorderWidth,
      borderRadius: chip.borderRadius,
      animationDuration: chip.animationDuration,
      showDivider: chip.showDivider,
      dividerColor: chip.dividerColor,
      dividerWidth: chip.dividerWidth,
      dividerHeight: chip.dividerHeight,
      baseContentPadding: chip.baseContentPadding,
      expandedContentPadding: chip.expandedContentPadding,
    );
  }
}
