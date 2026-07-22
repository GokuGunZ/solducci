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
  final double? titleSpacing;

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
    this.titleSpacing,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> finalActions = actions != null ? List.from(actions!) : [];

    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    final bool useCloseButton = parentRoute is PageRoute<dynamic> && parentRoute.fullscreenDialog;

    Widget? currentLeading = leading;

    // Se non è stato passato un leading ma possiamo fare pop, inseriamo il back button standard
    if (currentLeading == null && canPop) {
      currentLeading = useCloseButton ? const CloseButton() : const BackButton();
    }

    double? currentLeadingWidth;

    if (showContextSwitcher) {
      if (currentLeading != null) {
        currentLeading = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            currentLeading,
            const Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: ContextSwitcher(),
            ),
          ],
        );
        currentLeadingWidth = 110.0; // BackButton(48) + Padding(4) + Switcher(~55)
      } else {
        currentLeading = const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: ContextSwitcher(),
        );
        currentLeadingWidth = 75.0; // Padding(16) + Switcher(~55)
      }
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
      leading: currentLeading,
      leadingWidth: currentLeadingWidth,
      bottom: bottom,
      titleSpacing: titleSpacing,
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
