import 'package:flutter/material.dart';

/// Style configuration for [InlineToggle]
///
/// Defines the visual appearance of the toggleable text in both active and inactive states.
class InlineToggleStyle {
  /// Font size for all text
  final double fontSize;

  /// Font weight for the toggleable text
  final FontWeight fontWeight;

  /// Font weight for the remaining text
  final FontWeight? remainingTextFontWeight;

  /// Text color when active
  final Color activeColor;

  /// Text color when inactive
  final Color inactiveColor;

  /// Background color when active
  ///
  /// If null, no background is shown.
  final Color? activeBackgroundColor;

  /// Background color when inactive
  ///
  /// If null, no background is shown.
  final Color? inactiveBackgroundColor;

  /// Border radius for the background container
  final double borderRadius;

  /// Padding around the toggleable text
  final EdgeInsets padding;

  /// Thickness of the strikethrough decoration when inactive
  final double decorationThickness;

  /// Color for the remaining (non-toggleable) text
  final Color? remainingTextColor;

  const InlineToggleStyle({
    this.fontSize = 13,
    this.fontWeight = FontWeight.bold,
    this.remainingTextFontWeight,
    required this.activeColor,
    required this.inactiveColor,
    this.activeBackgroundColor,
    this.inactiveBackgroundColor,
    this.borderRadius = 4,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.decorationThickness = 2,
    this.remainingTextColor,
  });

  /// Create a copy with modified properties
  InlineToggleStyle copyWith({
    double? fontSize,
    FontWeight? fontWeight,
    FontWeight? remainingTextFontWeight,
    Color? activeColor,
    Color? inactiveColor,
    Color? activeBackgroundColor,
    Color? inactiveBackgroundColor,
    double? borderRadius,
    EdgeInsets? padding,
    double? decorationThickness,
    Color? remainingTextColor,
  }) {
    return InlineToggleStyle(
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      remainingTextFontWeight:
          remainingTextFontWeight ?? this.remainingTextFontWeight,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      activeBackgroundColor:
          activeBackgroundColor ?? this.activeBackgroundColor,
      inactiveBackgroundColor:
          inactiveBackgroundColor ?? this.inactiveBackgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      decorationThickness: decorationThickness ?? this.decorationThickness,
      remainingTextColor: remainingTextColor ?? this.remainingTextColor,
    );
  }
}

/// Inline toggleable text with animated state changes
///
/// Displays a sentence where one word is toggleable (clickable) with visual state changes.
/// When inactive, the toggleable word shows strikethrough decoration and changes color.
///
/// ## Features
/// - Strikethrough animation when inactive (200ms)
/// - Color and background color transitions
/// - Smooth animations with AnimatedContainer and AnimatedDefaultTextStyle
/// - Clickable only on the toggle word, not the entire text
/// - Highly customizable through [InlineToggleStyle]
///
/// ## Example
///
/// ```dart
/// InlineToggle(
///   isActive: autoSave,
///   toggleText: 'Auto-save',
///   remainingText: ' enabled for this document',
///   style: InlineToggleStyle(
///     activeColor: Colors.green.shade700,
///     inactiveColor: Colors.grey.shade500,
///     activeBackgroundColor: Colors.green.shade50,
///   ),
///   onToggle: () => setState(() => autoSave = !autoSave),
/// )
/// ```
///
/// ### Advanced Example with Custom Styling
///
/// ```dart
/// InlineToggle(
///   isActive: notificationsEnabled,
///   toggleText: 'Notifications',
///   remainingText: ' will be sent to your email',
///   style: InlineToggleStyle(
///     fontSize: 15,
///     fontWeight: FontWeight.w700,
///     activeColor: Colors.blue.shade800,
///     inactiveColor: Colors.grey.shade400,
///     activeBackgroundColor: Colors.blue.shade100,
///     inactiveBackgroundColor: Colors.transparent,
///     borderRadius: 6,
///     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
///     decorationThickness: 2.5,
///     remainingTextColor: Colors.grey.shade700,
///   ),
///   animationDuration: Duration(milliseconds: 250),
///   onToggle: () {
///     setState(() => notificationsEnabled = !notificationsEnabled);
///     // Additional logic...
///   },
/// )
/// ```
///
/// ## Design Patterns
/// - **State Pattern**: Visual representation changes based on state
/// - **Template Method**: Defines structure with customizable style
class InlineToggle extends StatelessWidget {
  /// Whether the toggle is active
  ///
  /// When true, shows normal text without strikethrough.
  /// When false, shows strikethrough decoration.
  final bool isActive;

  /// The toggleable word (clickable)
  ///
  /// This text is interactive and triggers [onToggle] when tapped.
  final String toggleText;

  /// The remaining text (not clickable)
  ///
  /// This text is displayed after the toggleable word but is not interactive.
  final String remainingText;

  /// Style configuration for the toggle
  ///
  /// Defines colors, fonts, padding, and other visual properties.
  final InlineToggleStyle style;

  /// Callback when toggle is tapped
  ///
  /// Called when the user taps on the toggleable text.
  final VoidCallback onToggle;

  /// Animation duration for state transitions
  final Duration animationDuration;

  const InlineToggle({
    super.key,
    required this.isActive,
    required this.toggleText,
    required this.remainingText,
    required this.style,
    required this.onToggle,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Toggleable word (clickable)
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: animationDuration,
            padding: style.padding,
            decoration: BoxDecoration(
              color: isActive
                  ? style.activeBackgroundColor
                  : style.inactiveBackgroundColor,
              borderRadius: BorderRadius.circular(style.borderRadius),
            ),
            child: AnimatedDefaultTextStyle(
              duration: animationDuration,
              style: TextStyle(
                fontSize: style.fontSize,
                fontWeight: style.fontWeight,
                color: isActive ? style.activeColor : style.inactiveColor,
                decoration:
                    isActive ? TextDecoration.none : TextDecoration.lineThrough,
                decorationThickness: style.decorationThickness,
              ),
              child: Text(toggleText),
            ),
          ),
        ),

        // Remaining text (not clickable)
        Text(
          remainingText,
          style: TextStyle(
            fontSize: style.fontSize,
            fontWeight: style.remainingTextFontWeight ?? FontWeight.w500,
            color: style.remainingTextColor ?? Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

/// Preset style configurations for [InlineToggle]
///
/// Provides common styling combinations for quick use.
class InlineToggleStyles {
  /// Blue theme (default)
  static InlineToggleStyle blue = InlineToggleStyle(
    activeColor: Colors.blue.shade700,
    inactiveColor: Colors.grey.shade500,
    activeBackgroundColor: Colors.blue.shade50,
    inactiveBackgroundColor: Colors.transparent,
  );

  /// Green theme
  static InlineToggleStyle green = InlineToggleStyle(
    activeColor: Colors.green.shade700,
    inactiveColor: Colors.grey.shade500,
    activeBackgroundColor: Colors.green.shade50,
    inactiveBackgroundColor: Colors.transparent,
  );

  /// Red theme
  static InlineToggleStyle red = InlineToggleStyle(
    activeColor: Colors.red.shade700,
    inactiveColor: Colors.grey.shade500,
    activeBackgroundColor: Colors.red.shade50,
    inactiveBackgroundColor: Colors.transparent,
  );

  /// Purple theme
  static InlineToggleStyle purple = InlineToggleStyle(
    activeColor: Colors.purple.shade700,
    inactiveColor: Colors.grey.shade500,
    activeBackgroundColor: Colors.purple.shade50,
    inactiveBackgroundColor: Colors.transparent,
  );

  /// Amber theme
  static InlineToggleStyle amber = InlineToggleStyle(
    activeColor: Colors.amber.shade800,
    inactiveColor: Colors.grey.shade500,
    activeBackgroundColor: Colors.amber.shade50,
    inactiveBackgroundColor: Colors.transparent,
  );

  /// Minimal theme (no background)
  static InlineToggleStyle minimal = InlineToggleStyle(
    activeColor: Colors.black87,
    inactiveColor: Colors.grey.shade400,
    activeBackgroundColor: Colors.transparent,
    inactiveBackgroundColor: Colors.transparent,
  );

  /// Bold theme (thicker text and decoration)
  static InlineToggleStyle bold = InlineToggleStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    activeColor: Colors.blue.shade800,
    inactiveColor: Colors.grey.shade600,
    activeBackgroundColor: Colors.blue.shade100,
    inactiveBackgroundColor: Colors.grey.shade100,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decorationThickness: 3,
  );
}
