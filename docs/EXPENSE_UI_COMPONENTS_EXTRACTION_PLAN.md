# Expense UI Components Extraction Plan

**Date**: 2026-01-15
**Status**: 🎯 Planning Complete - Ready for Implementation
**Author**: Senior Architecture Team

---

## Executive Summary

This document outlines the extraction and abstraction of three reusable UI components from the expense split feature:

1. **SlidableSwitch** - Generic slidable switch with drag support and color gradient animation
2. **ExpandableChip** - Chip that expands to show additional content when selected
3. **InlineToggle** - Inline toggleable text with visual state changes

### Key Goals
1. **Extract Domain Logic**: Separate expense-specific logic from generic UI patterns
2. **Create Reusable Components**: Build generic, type-safe components usable in any context
3. **Maintain Clean Code**: Follow SOLID principles, DRY, and design patterns
4. **Zero Breaking Changes**: Existing expense split functionality remains unchanged

---

## Component Analysis

### 1. SlidableSwitch (from ExpenseTypeSwitch)

**Current Implementation**: [lib/widgets/expense_split/expense_type_switch.dart](../lib/widgets/expense_split/expense_type_switch.dart)

**Domain-Specific Elements**:
- ExpenseType enum (personal, group)
- Hard-coded colors (purple, green)
- Hard-coded icons (person, group)
- Hard-coded labels ("Personale", "Di Gruppo")

**Generic Pattern Identified**:
```
┌─────────────────────────────────────────────────────┐
│  User Interaction                                    │
│  - Click left/right side → Switch option            │
│  - Drag chip → Smooth slide with gradient           │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Visual Behavior                                     │
│  - Animated chip slide (300ms)                      │
│  - Color gradient interpolation during drag         │
│  - Icon + label in chip                             │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Generic Abstraction                                 │
│  SlidableSwitch<T extends Enum>                     │
│  - Any enum type                                     │
│  - Configurable colors, icons, labels               │
│  - Generic onChanged(T value) callback              │
└─────────────────────────────────────────────────────┘
```

**Key Features to Abstract**:
- ✅ Generic enum type support via type parameter `<T extends Enum>`
- ✅ Drag tracking and position calculation
- ✅ Color interpolation between two colors
- ✅ Bidirectional animations
- ✅ Configurable labels, icons, colors per option
- ✅ Enable/disable state

**Design Pattern**: **Strategy Pattern** + **Generic Programming**

---

### 2. ExpandableChip (from UserSplitChip)

**Current Implementation**: [lib/widgets/expense_split/user_split_chip.dart](../lib/widgets/expense_split/user_split_chip.dart)

**Domain-Specific Elements**:
- GroupMember model
- Amount/money-specific logic
- Validation for total amount
- "Add remaining" button logic
- Blue color scheme

**Generic Pattern Identified**:
```
┌─────────────────────────────────────────────────────┐
│  Base State (Not Selected)                          │
│  ┌────────────────┐                                 │
│  │ [Avatar] Name  │                                 │
│  └────────────────┘                                 │
└─────────────────────────────────────────────────────┘
                         ↓ Click
┌─────────────────────────────────────────────────────┐
│  Expanded State (Selected)                          │
│  ┌────────────────┬──────────────────────┐          │
│  │ [Avatar] Name  │ | [Content] [Action] │          │
│  └────────────────┴──────────────────────┘          │
│                    ↑                                 │
│                    Slide-in animation (250ms)       │
└─────────────────────────────────────────────────────┘
```

**Key Features to Abstract**:
- ✅ Generic data type via type parameter `<T>`
- ✅ Base chip content (left side - always visible)
- ✅ Expanded content (right side - animated slide)
- ✅ Selection state management
- ✅ Smooth slide-in/out animation with ClipRect + AnimatedAlign
- ✅ Configurable colors and styling
- ✅ Optional action buttons in expanded area

**Design Pattern**: **Builder Pattern** + **Composite Pattern**

---

### 3. InlineToggle (from EquallySplitToggle)

**Current Implementation**: [lib/widgets/expense_split/equally_split_toggle.dart](../lib/widgets/expense_split/equally_split_toggle.dart)

**Domain-Specific Elements**:
- Text "Equamente diviso tra:"
- Blue color scheme
- Expense context-specific wording

**Generic Pattern Identified**:
```
┌─────────────────────────────────────────────────────┐
│  Active State                                        │
│  [Toggleable Word] remaining text                   │
│  ↑ Bold, colored, clickable                         │
└─────────────────────────────────────────────────────┘
                         ↓ Click
┌─────────────────────────────────────────────────────┐
│  Inactive State                                      │
│  [~~Toggleable Word~~] remaining text               │
│  ↑ Strikethrough, grayed, clickable                 │
└─────────────────────────────────────────────────────┘
```

**Key Features to Abstract**:
- ✅ Inline toggleable word within sentence
- ✅ Animated text style changes (color, decoration, background)
- ✅ Strikethrough animation (200ms)
- ✅ Configurable active/inactive colors
- ✅ Configurable text content
- ✅ State change callback

**Design Pattern**: **State Pattern** + **Template Method Pattern**

---

## Architecture Design

### Layer Structure

```
┌─────────────────────────────────────────────────────────────┐
│  DOMAIN LAYER (Feature-Specific)                            │
│  lib/widgets/expense_split/                                 │
│  - ExpenseTypeSwitch (uses SlidableSwitch<ExpenseType>)    │
│  - UserSplitChip (uses ExpandableChip<GroupMember>)        │
│  - EquallySplitToggle (uses InlineToggle)                  │
└─────────────────────────────────────────────────────────────┘
                           ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  CORE COMPONENT LIBRARY (Generic, Reusable)                 │
│  lib/core/components/                                       │
│  - switches/slidable_switch.dart                           │
│  - chips/expandable_chip.dart                              │
│  - text/inline_toggle.dart                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Specifications

### 1. SlidableSwitch<T extends Enum>

**File**: `lib/core/components/switches/slidable_switch.dart`

**API Design**:

```dart
/// Configuration for each switch option
class SlidableSwitchOption<T extends Enum> {
  final T value;
  final String label;
  final IconData icon;
  final Color color;

  const SlidableSwitchOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Generic slidable switch with drag support and color gradient
///
/// Type Parameter:
///   T: Enum type for switch options (must have exactly 2 values)
///
/// Features:
///   - Click to switch
///   - Drag chip to switch
///   - Color gradient animation during drag
///   - Smooth bidirectional animations
///
/// Example:
/// ```dart
/// enum Theme { light, dark }
///
/// SlidableSwitch<Theme>(
///   options: [
///     SlidableSwitchOption(
///       value: Theme.light,
///       label: 'Light',
///       icon: Icons.light_mode,
///       color: Colors.amber,
///     ),
///     SlidableSwitchOption(
///       value: Theme.dark,
///       label: 'Dark',
///       icon: Icons.dark_mode,
///       color: Colors.indigo,
///     ),
///   ],
///   initialValue: Theme.light,
///   onChanged: (theme) => print('Theme: $theme'),
/// )
/// ```
class SlidableSwitch<T extends Enum> extends StatefulWidget {
  /// The two switch options (left and right)
  final List<SlidableSwitchOption<T>> options;

  /// Initial selected option
  final T initialValue;

  /// Callback when option changes
  final ValueChanged<T> onChanged;

  /// Whether the switch is enabled
  final bool enabled;

  /// Height of the switch
  final double height;

  /// Background color of the track
  final Color? trackColor;

  /// Border radius of the switch
  final double borderRadius;

  /// Animation duration for programmatic switches
  final Duration animationDuration;

  const SlidableSwitch({
    super.key,
    required this.options,
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
    this.height = 64,
    this.trackColor,
    this.borderRadius = 32,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : assert(options.length == 2, 'SlidableSwitch requires exactly 2 options');

  @override
  State<SlidableSwitch<T>> createState() => _SlidableSwitchState<T>();
}
```

**Key Implementation Details**:
- Use `AnimationController` for smooth animations
- Track drag position as normalized value (0.0 to 1.0)
- Use `Color.lerp()` for gradient interpolation
- `GestureDetector` with `onHorizontalDragStart/Update/End`
- `LayoutBuilder` for responsive chip sizing

---

### 2. ExpandableChip<T>

**File**: `lib/core/components/chips/expandable_chip.dart`

**API Design**:

```dart
/// Generic chip that expands to show content when selected
///
/// Type Parameter:
///   T: Type of the data item
///
/// Features:
///   - Smooth slide-in/out animation (250ms)
///   - Configurable base and expanded content
///   - Selection state management
///   - Customizable colors and styling
///
/// Example:
/// ```dart
/// class User {
///   final String id;
///   final String name;
///   final String avatar;
/// }
///
/// ExpandableChip<User>(
///   item: user,
///   isSelected: selectedUsers.contains(user.id),
///   baseContentBuilder: (context, user) => Row(
///     children: [
///       CircleAvatar(backgroundImage: NetworkImage(user.avatar)),
///       SizedBox(width: 8),
///       Text(user.name),
///     ],
///   ),
///   expandedContentBuilder: (context, user) => Row(
///     children: [
///       TextField(/* user input */),
///       IconButton(icon: Icon(Icons.check)),
///     ],
///   ),
///   onSelectionChanged: (selected) => setState(() {
///     if (selected) {
///       selectedUsers.add(user.id);
///     } else {
///       selectedUsers.remove(user.id);
///     }
///   }),
/// )
/// ```
class ExpandableChip<T> extends StatefulWidget {
  /// The data item
  final T item;

  /// Whether the chip is selected (expanded)
  final bool isSelected;

  /// Builder for the base chip content (always visible)
  final Widget Function(BuildContext context, T item) baseContentBuilder;

  /// Builder for the expanded content (slide-in when selected)
  final Widget Function(BuildContext context, T item) expandedContentBuilder;

  /// Callback when selection state changes
  final ValueChanged<bool> onSelectionChanged;

  /// Colors for selected/unselected states
  final Color? selectedBackgroundColor;
  final Color? unselectedBackgroundColor;
  final Color? selectedBorderColor;
  final Color? unselectedBorderColor;

  /// Border radius
  final double borderRadius;

  /// Animation duration
  final Duration animationDuration;

  /// Whether to show divider between base and expanded content
  final bool showDivider;

  /// Divider color
  final Color? dividerColor;

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
    this.borderRadius = 20,
    this.animationDuration = const Duration(milliseconds: 250),
    this.showDivider = true,
    this.dividerColor,
  });

  @override
  State<ExpandableChip<T>> createState() => _ExpandableChipState<T>();
}
```

**Key Implementation Details**:
- Use `ClipRect` + `AnimatedAlign` with `widthFactor` for smooth slide animation
- `Row` with `mainAxisSize: MainAxisSize.min` for dynamic sizing
- `IntrinsicWidth` for content-based width calculation
- Configurable colors via parameters with sensible defaults
- Optional divider between base and expanded sections

---

### 3. InlineToggle

**File**: `lib/core/components/text/inline_toggle.dart`

**API Design**:

```dart
/// Configuration for toggle text styling
class InlineToggleStyle {
  final double fontSize;
  final FontWeight fontWeight;
  final Color activeColor;
  final Color inactiveColor;
  final Color? activeBackgroundColor;
  final Color? inactiveBackgroundColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double decorationThickness;

  const InlineToggleStyle({
    this.fontSize = 13,
    this.fontWeight = FontWeight.bold,
    required this.activeColor,
    required this.inactiveColor,
    this.activeBackgroundColor,
    this.inactiveBackgroundColor,
    this.borderRadius = 4,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.decorationThickness = 2,
  });
}

/// Inline toggleable text with animated state changes
///
/// Features:
///   - Strikethrough animation when inactive
///   - Color and background color changes
///   - Smooth animations (200ms)
///   - Clickable only on toggle word
///
/// Example:
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
class InlineToggle extends StatelessWidget {
  /// Whether the toggle is active
  final bool isActive;

  /// The toggleable word (clickable)
  final String toggleText;

  /// The remaining text (not clickable)
  final String remainingText;

  /// Style configuration
  final InlineToggleStyle style;

  /// Callback when toggle is tapped
  final VoidCallback onToggle;

  /// Animation duration
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
                decoration: isActive
                    ? TextDecoration.none
                    : TextDecoration.lineThrough,
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
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
```

**Key Implementation Details**:
- Simple stateless widget (state managed externally)
- `AnimatedContainer` + `AnimatedDefaultTextStyle` for smooth transitions
- `Wrap` for flexible text layout
- Separate styling configuration via `InlineToggleStyle` class

---

## Migration Strategy

### Phase 1: Create Core Components ✅

**Duration**: 3 hours

**Steps**:
1. Create directory structure:
   ```
   lib/core/components/
   ├── switches/
   │   └── slidable_switch.dart
   ├── chips/
   │   └── expandable_chip.dart
   └── text/
       └── inline_toggle.dart
   ```

2. Implement generic components following API specs above

3. Add comprehensive dartdoc comments

4. Create example usage in comments

---

### Phase 2: Refactor Domain Components 🔜

**Duration**: 2 hours

**Steps**:

#### 2.1 ExpenseTypeSwitch

**Before** (130 lines):
```dart
class ExpenseTypeSwitch extends StatefulWidget {
  // 130 lines with all logic embedded
}
```

**After** (~40 lines):
```dart
class ExpenseTypeSwitch extends StatelessWidget {
  final ExpenseType initialType;
  final ValueChanged<ExpenseType> onTypeChanged;
  final bool enabled;

  const ExpenseTypeSwitch({
    super.key,
    required this.initialType,
    required this.onTypeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SlidableSwitch<ExpenseType>(
      options: [
        SlidableSwitchOption(
          value: ExpenseType.personal,
          label: ExpenseType.personal.label,
          icon: ExpenseType.personal.icon,
          color: ExpenseType.personal.color,
        ),
        SlidableSwitchOption(
          value: ExpenseType.group,
          label: ExpenseType.group.label,
          icon: ExpenseType.group.icon,
          color: ExpenseType.group.color,
        ),
      ],
      initialValue: initialType,
      onChanged: onTypeChanged,
      enabled: enabled,
    );
  }
}
```

**Benefits**:
- ✅ 69% reduction in code (130 → 40 lines)
- ✅ All animation logic reusable
- ✅ Generic switch available for other enums

---

#### 2.2 UserSplitChip

**Before** (298 lines):
```dart
class UserSplitChip extends StatefulWidget {
  // 298 lines with animation, validation, etc.
}
```

**After** (~120 lines):
```dart
class UserSplitChip extends StatelessWidget {
  final GroupMember member;
  final bool isSelected;
  final double amount;
  // ... other domain-specific fields

  @override
  Widget build(BuildContext context) {
    return ExpandableChip<GroupMember>(
      item: member,
      isSelected: isSelected,
      baseContentBuilder: (context, member) => _buildBaseContent(member),
      expandedContentBuilder: (context, member) => _buildExpandedContent(member),
      onSelectionChanged: onSelectionChanged,
      selectedBackgroundColor: Colors.blue.shade50,
      selectedBorderColor: Colors.blue.shade300,
    );
  }

  Widget _buildBaseContent(GroupMember member) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(/* ... */),
        SizedBox(width: 8),
        Text(member.nickname ?? member.email ?? 'Unknown'),
      ],
    );
  }

  Widget _buildExpandedContent(GroupMember member) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Amount TextField
        // Action buttons
      ],
    );
  }
}
```

**Benefits**:
- ✅ 60% reduction in code (298 → 120 lines)
- ✅ Animation logic extracted
- ✅ Generic expandable chip for any data type

---

#### 2.3 EquallySplitToggle

**Before** (64 lines):
```dart
class EquallySplitToggle extends StatelessWidget {
  // 64 lines with embedded styling
}
```

**After** (~20 lines):
```dart
class EquallySplitToggle extends StatelessWidget {
  final bool isEqual;
  final VoidCallback onToggle;

  const EquallySplitToggle({
    super.key,
    required this.isEqual,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InlineToggle(
      isActive: isEqual,
      toggleText: 'Equamente',
      remainingText: ' diviso tra:',
      style: InlineToggleStyle(
        activeColor: Colors.blue.shade700,
        inactiveColor: Colors.grey.shade500,
        activeBackgroundColor: Colors.blue.shade50,
      ),
      onToggle: onToggle,
    );
  }
}
```

**Benefits**:
- ✅ 69% reduction in code (64 → 20 lines)
- ✅ Styling logic extracted
- ✅ Generic inline toggle for any context

---

### Phase 3: Update Documentation 📝

**Duration**: 1 hour

**Files to Update**:
1. `COMPONENT_LIBRARY_ARCHITECTURE.md` - Add new components section
2. `REUSABLE_COMPONENTS_AGENT_GUIDE.md` - Add usage examples
3. Create `EXPENSE_UI_COMPONENTS_GUIDE.md` - Detailed extraction case study

---

## Metrics & Benefits

### Code Reduction

| Component | Before | After | Reduction | Extracted Lines |
|-----------|--------|-------|-----------|-----------------|
| ExpenseTypeSwitch | 280 lines | ~40 lines | **86%** | 240 → core |
| UserSplitChip | 298 lines | ~120 lines | **60%** | 178 → core |
| EquallySplitToggle | 64 lines | ~20 lines | **69%** | 44 → core |
| **Core Components** | 0 lines | ~600 lines | +600 | New reusable code |
| **NET TOTAL** | 642 lines | 780 lines | +21% | **3 reusable components** |

**Note**: While total lines increase, we gain:
- ✅ 3 fully generic, reusable components
- ✅ Type-safe APIs with comprehensive documentation
- ✅ Significantly simpler domain implementations
- ✅ DRY principle applied (animation logic not duplicated)

### Architectural Benefits

✅ **Single Responsibility**: Each component does one thing well
✅ **Open/Closed**: Extend via configuration, not modification
✅ **Dependency Inversion**: Domain depends on abstractions
✅ **Composition**: Build complex UIs from simple parts
✅ **Reusability**: Use components in ANY feature
✅ **Testability**: Small, focused components = easy testing

### Reusability Potential

**SlidableSwitch<T>** can be used for:
- Theme switcher (Light/Dark)
- Language selector (EN/IT)
- View mode (List/Grid)
- Payment method (Card/Cash)
- User role (Admin/User)

**ExpandableChip<T>** can be used for:
- User selection with details
- Product filters with options
- Tag selection with counts
- Contact selection with actions
- Category selection with description

**InlineToggle** can be used for:
- Feature flags in settings
- Filter toggles in lists
- Sort direction indicators
- Status toggles in forms
- Permission indicators

---

## Testing Strategy

### Unit Tests

```dart
// test/core/components/switches/slidable_switch_test.dart
group('SlidableSwitch', () {
  test('initializes with correct value', () {
    final switch = SlidableSwitch<TestEnum>(
      options: testOptions,
      initialValue: TestEnum.option1,
      onChanged: (_) {},
    );
    expect(switch.initialValue, TestEnum.option1);
  });

  testWidgets('switches on tap', (tester) async {
    TestEnum? result;
    await tester.pumpWidget(
      MaterialApp(
        home: SlidableSwitch<TestEnum>(
          options: testOptions,
          initialValue: TestEnum.option1,
          onChanged: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.text('Option 2'));
    await tester.pumpAndSettle();

    expect(result, TestEnum.option2);
  });

  testWidgets('animates color on drag', (tester) async {
    // Test drag gesture and color interpolation
  });
});
```

### Widget Tests

```dart
// test/core/components/chips/expandable_chip_test.dart
testWidgets('ExpandableChip expands on selection', (tester) async {
  bool isSelected = false;

  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          return ExpandableChip<String>(
            item: 'Test',
            isSelected: isSelected,
            baseContentBuilder: (_, item) => Text('Base: $item'),
            expandedContentBuilder: (_, item) => Text('Expanded: $item'),
            onSelectionChanged: (selected) {
              setState(() => isSelected = selected);
            },
          );
        },
      ),
    ),
  );

  // Initially collapsed
  expect(find.text('Expanded: Test'), findsNothing);

  // Tap to expand
  await tester.tap(find.text('Base: Test'));
  await tester.pumpAndSettle();

  // Now expanded
  expect(find.text('Expanded: Test'), findsOneWidget);
});
```

---

## Risk Assessment

### Low Risk ✅

- Creating new generic components (additive)
- Documentation updates
- Example code additions

### Medium Risk ⚠️

- Refactoring domain components (behavior must remain identical)
- Animation timing changes (must feel the same)
- Color/styling changes (must look the same)

### High Risk 🔴

- Breaking public APIs (expense form still uses these)
- Performance regressions (animation performance)
- Layout bugs (responsive behavior)

### Mitigation Strategies

1. **Behavior Preservation**: Test extensively before/after refactoring
2. **Visual Regression Testing**: Screenshot comparison
3. **Animation Testing**: Frame-by-frame verification
4. **Incremental Migration**: One component at a time
5. **Rollback Plan**: Keep old implementations until verified

---

## Implementation Timeline

| Phase | Task | Duration | Status |
|-------|------|----------|--------|
| **Phase 1** | Create SlidableSwitch<T> | 1.5h | 📅 |
| | Create ExpandableChip<T> | 1h | 📅 |
| | Create InlineToggle | 0.5h | 📅 |
| **Phase 2** | Refactor ExpenseTypeSwitch | 0.5h | 📅 |
| | Refactor UserSplitChip | 1h | 📅 |
| | Refactor EquallySplitToggle | 0.5h | 📅 |
| **Phase 3** | Update documentation | 1h | 📅 |
| | Write tests | 1h | 📅 |
| **TOTAL** | | **7 hours** | **0% DONE** |

---

## Success Criteria

### Functional
- ✅ All existing expense split features work identically
- ✅ No visual regressions
- ✅ No animation performance issues
- ✅ No layout bugs

### Architectural
- ✅ 3 fully generic, type-safe components created
- ✅ Components follow SOLID principles
- ✅ Comprehensive API documentation
- ✅ Usage examples in documentation

### Quality
- ✅ 90%+ test coverage on new components
- ✅ Zero breaking changes to public APIs
- ✅ Clean code review approval
- ✅ Documentation review approval

---

## Next Steps

1. 🔜 **Implement Phase 1**: Create core generic components
2. 📅 **Implement Phase 2**: Refactor domain components
3. 📅 **Implement Phase 3**: Update documentation
4. 📅 **Testing**: Comprehensive testing of all components
5. 📅 **Review**: Code and documentation review

---

## Appendix: File Structure

### Before
```
lib/widgets/expense_split/
├── expense_type_switch.dart (280 lines)
├── user_split_chip.dart (298 lines)
├── equally_split_toggle.dart (64 lines)
├── group_split_card.dart
└── user_selection_chip.dart
```

### After
```
lib/
├── core/components/
│   ├── switches/
│   │   └── slidable_switch.dart (NEW - 250 lines)
│   ├── chips/
│   │   └── expandable_chip.dart (NEW - 200 lines)
│   └── text/
│       └── inline_toggle.dart (NEW - 150 lines)
└── widgets/expense_split/
    ├── expense_type_switch.dart (REFACTORED - 40 lines)
    ├── user_split_chip.dart (REFACTORED - 120 lines)
    ├── equally_split_toggle.dart (REFACTORED - 20 lines)
    ├── group_split_card.dart (unchanged)
    └── user_selection_chip.dart (unchanged)
```

---

**Document Version**: 1.0
**Last Updated**: 2026-01-15
**Status**: Planning Complete - Ready for Implementation
