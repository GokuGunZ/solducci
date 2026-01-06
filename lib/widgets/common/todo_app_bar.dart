import 'package:flutter/material.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Reusable AppBar widget for the ToDo section with consistent purple gradient styling
///
/// This widget provides a standardized AppBar design across all ToDo-related pages:
/// - Transparent background with purple gradient
/// - Purple bottom border
/// - Purple icons and text
/// - Consistent spacing and sizing
///
/// Usage:
/// ```dart
/// Scaffold(
///   appBar: TodoAppBar(
///     title: 'My Page',
///     actions: [IconButton(...)],
///   ),
///   body: ...,
/// )
/// ```
class TodoAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title displayed in the AppBar
  final String title;

  /// Optional actions to display on the right side of the AppBar
  final List<Widget>? actions;

  /// Whether to show the back button (default: true, uses Navigator.canPop)
  final bool automaticallyImplyLeading;

  /// Custom leading widget (overrides the back button)
  final Widget? leading;

  /// Height of the AppBar (default: 56.0)
  final double height;

  /// Whether to center the title (default: false)
  final bool centerTitle;

  const TodoAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.height = 56.0,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: TodoTheme.appBarDecoration,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              // Leading widget (back button or custom)
              if (leading != null)
                leading!
              else if (automaticallyImplyLeading && Navigator.canPop(context))
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: TodoTheme.iconColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),

              // Title
              if (centerTitle)
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: TodoTheme.appBarTitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      title,
                      style: TodoTheme.appBarTitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              // Actions
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height + 48); // 48 = typical SafeArea top padding
}

/// Simplified AppBar without gradient (solid purple background)
/// Used for dialogs and modals where gradient might be too much
class TodoSolidAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final bool centerTitle;

  const TodoSolidAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.height = 56.0,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      backgroundColor: TodoTheme.primaryPurple,
      foregroundColor: TodoTheme.onPrimaryColor,
      elevation: 0,
      leading: leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
