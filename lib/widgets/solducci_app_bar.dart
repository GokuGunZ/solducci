import 'package:flutter/material.dart';
import 'package:solducci/widgets/context_switcher.dart';

class SolducciAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final bool showContextSwitcher;
  final bool centerTitle;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final double? elevation;
  final IconThemeData? iconTheme;
  final Widget? flexibleSpace;
  final Color? foregroundColor;

  const SolducciAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.showContextSwitcher = true,
    this.centerTitle = false,
    this.leading,
    this.bottom,
    this.backgroundColor,
    this.elevation,
    this.iconTheme,
    this.flexibleSpace,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> finalActions = actions != null ? List.from(actions!) : [];
    
    if (showContextSwitcher) {
      finalActions.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(child: ContextSwitcher()),
      ));
    }

    return AppBar(
      title: title ?? (titleText != null ? Text(titleText!) : null),
      centerTitle: centerTitle,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 2,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      iconTheme: iconTheme,
      flexibleSpace: flexibleSpace,
      leading: leading,
      bottom: bottom,
      actions: finalActions,
    );
  }

  @override
  Size get preferredSize {
    double height = kToolbarHeight;
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }
    return Size.fromHeight(height);
  }
}
