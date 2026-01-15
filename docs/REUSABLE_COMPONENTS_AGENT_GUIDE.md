# 🤖 Reusable Components - Claude Agent Guide

> **Purpose**: Enable AI agents to use and extend reusable component library
> **Target**: Claude Code agents working on any feature
> **Scope**: Generic UI components library

---

## Quick Start for Agents

### When to Use These Components

```
User requests feature with:
  ├─ List of items → Use FilterableListView<T, F>
  ├─ Category filtering → Use CategoryScrollBar<T, C>
  ├─ Drag & drop reordering → Use ReorderableListViewBase<T>
  └─ Highlight animation → Use HighlightAnimationMixin or HighlightContainer
```

---

## Component Decision Tree

```
User needs...

├─ A switch between 2 enum options
│  └─ Use SlidableSwitch<T extends Enum>
│
├─ A chip that expands to show more content
│  └─ Use ExpandableChip<T>
│
├─ Inline toggleable text in a sentence
│  └─ Use InlineToggle
│
├─ A list view
│  ↓
│  Does it need filtering?
│    ├─ Yes → Is it a simple enum-based filter?
│    │         ├─ Yes → Use CategoryScrollBar<T, C>
│    │         └─ No → Use FilterableListView<T, F> with custom filter
│    └─ No → Does it need reordering?
│              ├─ Yes → Use ReorderableListViewBase<T>
│              └─ No → Use standard ListView.builder
│
└─ Highlight animation on item creation/update
   └─ Use HighlightContainer or HighlightAnimationMixin
```

---

## Component Library Reference

### 1. SlidableSwitch<T extends Enum>

**When to use**:
- ✅ Switch between exactly 2 enum options
- ✅ Need smooth drag-and-drop interaction
- ✅ Want animated color gradient during transition
- ✅ Clean, modern pill-shaped design

**How to implement**:

```dart
// STEP 1: Define enum with properties
enum Theme {
  light,
  dark;

  String get label {
    switch (this) {
      case Theme.light: return 'Light';
      case Theme.dark: return 'Dark';
    }
  }

  IconData get icon {
    switch (this) {
      case Theme.light: return Icons.light_mode;
      case Theme.dark: return Icons.dark_mode;
    }
  }

  Color get color {
    switch (this) {
      case Theme.light: return Colors.amber;
      case Theme.dark: return Colors.indigo;
    }
  }
}

// STEP 2: Use SlidableSwitch
class ThemeSwitch extends StatelessWidget {
  final Theme selectedTheme;
  final ValueChanged<Theme> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return SlidableSwitch<Theme>(
      options: [
        SlidableSwitchOption(
          value: Theme.light,
          label: Theme.light.label,
          icon: Theme.light.icon,
          color: Theme.light.color,
        ),
        SlidableSwitchOption(
          value: Theme.dark,
          label: Theme.dark.label,
          icon: Theme.dark.icon,
          color: Theme.dark.color,
        ),
      ],
      initialValue: selectedTheme,
      onChanged: onThemeChanged,
    );
  }
}
```

**Agent Checklist**:
- [ ] Created enum with exactly 2 values
- [ ] Implemented `label`, `icon`, and `color` getters
- [ ] Created SlidableSwitchOption for each enum value
- [ ] Handled `onChanged` callback

---

### 2. ExpandableChip<T>

**When to use**:
- ✅ Need chip that reveals extra content when selected
- ✅ Want smooth slide-in/out animations
- ✅ Dynamic content that adapts to size
- ✅ Interactive expanded section (inputs, buttons, etc.)

**How to implement**:

```dart
// STEP 1: Define data model
class User {
  final String id;
  final String name;
  final String avatarUrl;
}

// STEP 2: Use ExpandableChip with builders
class UserAmountChip extends StatefulWidget {
  final User user;
  final bool isSelected;
  final double amount;
  final ValueChanged<bool> onSelectionChanged;
  final ValueChanged<double> onAmountChanged;

  @override
  State<UserAmountChip> createState() => _UserAmountChipState();
}

class _UserAmountChipState extends State<UserAmountChip> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.amount.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpandableChip<User>(
      item: widget.user,
      isSelected: widget.isSelected,
      baseContentBuilder: (context, user) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
          SizedBox(width: 8),
          Text(user.name),
        ],
      ),
      expandedContentBuilder: (context, user) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicWidth(
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                widget.onAmountChanged(amount);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () => print('Confirmed'),
          ),
        ],
      ),
      onSelectionChanged: widget.onSelectionChanged,
    );
  }
}
```

**Agent Checklist**:
- [ ] Defined data model class
- [ ] Implemented `baseContentBuilder` (always visible)
- [ ] Implemented `expandedContentBuilder` (slides in)
- [ ] Handled `onSelectionChanged` callback
- [ ] Managed stateful content (if needed)

---

### 3. InlineToggle

**When to use**:
- ✅ Toggle a word within a sentence
- ✅ Need strikethrough animation when inactive
- ✅ Want background highlight on active state
- ✅ Clean, inline interaction without separate switch

**How to implement**:

```dart
// Simple example
class AutoSaveToggle extends StatefulWidget {
  @override
  State<AutoSaveToggle> createState() => _AutoSaveToggleState();
}

class _AutoSaveToggleState extends State<AutoSaveToggle> {
  bool autoSave = true;

  @override
  Widget build(BuildContext context) {
    return InlineToggle(
      isActive: autoSave,
      toggleText: 'Auto-save',
      remainingText: ' enabled for this document',
      style: InlineToggleStyle(
        activeColor: Colors.green.shade700,
        inactiveColor: Colors.grey.shade500,
        activeBackgroundColor: Colors.green.shade50,
      ),
      onToggle: () => setState(() => autoSave = !autoSave),
    );
  }
}

// Advanced example with custom styling
InlineToggle(
  isActive: notificationsEnabled,
  toggleText: 'Notifications',
  remainingText: ' will be sent to your email',
  style: InlineToggleStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    activeColor: Colors.blue.shade800,
    inactiveColor: Colors.grey.shade400,
    activeBackgroundColor: Colors.blue.shade100,
    borderRadius: 6,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  ),
  animationDuration: Duration(milliseconds: 250),
  onToggle: () {
    setState(() => notificationsEnabled = !notificationsEnabled);
  },
)
```

**Agent Checklist**:
- [ ] Defined toggle state variable
- [ ] Split sentence into toggleable and remaining text
- [ ] Configured InlineToggleStyle with colors
- [ ] Implemented onToggle callback

---

### 4. FilterableListView<T, F>

**When to use**:
- ✅ List with multiple filter criteria
- ✅ List with sorting options
- ✅ List with empty/loading/error states
- ✅ Complex filtering logic

**How to implement**:

```dart
// STEP 1: Define filter config
class YourFilterConfig {
  final Set<YourEnum>? selectedValues;
  final DateRange? dateRange;

  bool get hasFilters => selectedValues?.isNotEmpty ?? false;
}

// STEP 2: Extend FilterableListView
class YourListView extends FilterableListView<YourItem, YourFilterConfig> {
  YourListView({
    required List<YourItem> items,
    YourFilterConfig? filterConfig,
  }) : super(items: items, filterConfig: filterConfig);

  // REQUIRED: Implement filtering logic
  @override
  List<YourItem> filterItems(List<YourItem> items, YourFilterConfig? config) {
    if (config == null || !config.hasFilters) return items;

    return items.where((item) {
      // YOUR FILTER LOGIC HERE
      if (config.selectedValues?.isNotEmpty ?? false) {
        if (!config.selectedValues!.contains(item.value)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // REQUIRED: Implement sorting logic
  @override
  List<YourItem> sortItems(List<YourItem> items, YourFilterConfig? config) {
    return items..sort((a, b) => a.name.compareTo(b.name));
  }

  // REQUIRED: Render individual item
  @override
  Widget buildItem(BuildContext context, YourItem item, int index) {
    return YourItemCard(item: item);
  }

  // REQUIRED: Check if filters active
  @override
  bool hasActiveFilters() => filterConfig?.hasFilters ?? false;

  // REQUIRED: Default filter
  @override
  YourFilterConfig getDefaultFilter() => YourFilterConfig();

  // OPTIONAL: Custom empty state
  @override
  Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey),
          Text('No items found'),
        ],
      ),
    );
  }
}
```

**Agent Checklist**:
- [ ] Created filter config class
- [ ] Implemented `filterItems()`
- [ ] Implemented `sortItems()`
- [ ] Implemented `buildItem()`
- [ ] Implemented `hasActiveFilters()`
- [ ] Implemented `getDefaultFilter()`
- [ ] (Optional) Customized empty state

---

### 2. CategoryScrollBar<T, C>

**When to use**:
- ✅ Horizontal scrolling category filter
- ✅ Enum-based categories
- ✅ Quick filtering without dropdowns
- ✅ Visual category selection

**How to implement**:

```dart
// STEP 1: Define enum with properties
enum YourCategory {
  category1,
  category2,
  category3;

  String get label {
    switch (this) {
      case category1: return 'Category 1';
      case category2: return 'Category 2';
      case category3: return 'Category 3';
    }
  }

  Color get color {
    switch (this) {
      case category1: return Colors.blue;
      case category2: return Colors.green;
      case category3: return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case category1: return Icons.home;
      case category2: return Icons.work;
      case category3: return Icons.school;
    }
  }
}

// STEP 2: Add category to your item model
class YourItem {
  final String id;
  final String name;
  final YourCategory category; // Add this

  YourItem({required this.id, required this.name, required this.category});
}

// STEP 3: Use CategoryScrollBar
class YourPage extends StatefulWidget {
  @override
  State<YourPage> createState() => _YourPageState();
}

class _YourPageState extends State<YourPage> {
  YourCategory? _selectedCategory;
  List<YourItem> _filteredItems = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CategoryScrollBar<YourItem, YourCategory>(
          items: allItems,
          getCategoryValue: (item) => item.category,
          categoryValues: YourCategory.values,
          categoryLabel: (cat) => cat.label,
          categoryColor: (cat) => cat.color,
          categoryIcon: (cat) => cat.icon,
          selectedCategory: _selectedCategory,
          showCount: true,
          allLabel: 'All',
          allIcon: Icons.apps,
          onCategorySelected: (category, filtered) {
            setState(() {
              _selectedCategory = category;
              _filteredItems = filtered;
            });
          },
        ),
        Expanded(
          child: YourListView(items: _filteredItems),
        ),
      ],
    );
  }
}
```

**Agent Checklist**:
- [ ] Created enum with `label`, `color`, `icon` getters
- [ ] Added category field to item model
- [ ] Implemented `getCategoryValue` function
- [ ] Handled `onCategorySelected` callback
- [ ] Updated state with filtered items

---

### 3. HighlightAnimationMixin / HighlightContainer

**When to use**:
- ✅ Item just created/added
- ✅ Item reordered with drag & drop
- ✅ Item updated/modified
- ✅ Visual feedback needed

**How to implement**:

**Option A: StatelessWidget (easier)**

```dart
class YourItemWidget extends StatelessWidget {
  final YourItem item;
  final bool highlightOnCreate;

  @override
  Widget build(BuildContext context) {
    return HighlightContainer(
      autoStart: highlightOnCreate,
      duration: Duration(milliseconds: 500),
      highlightColor: Colors.yellow.withOpacity(0.3),
      child: YourItemCard(item: item),
    );
  }
}
```

**Option B: StatefulWidget (more control)**

```dart
class YourItemWidget extends StatefulWidget {
  final YourItem item;

  @override
  State<YourItemWidget> createState() => _YourItemWidgetState();
}

class _YourItemWidgetState extends State<YourItemWidget>
    with SingleTickerProviderStateMixin, HighlightAnimationMixin {

  @override
  void initState() {
    super.initState();
    initHighlightAnimation(this);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: highlightAnimation!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: highlightColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: YourItemCard(item: widget.item),
        );
      },
    );
  }

  @override
  void didUpdateWidget(YourItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      triggerHighlight(); // Trigger on change
    }
  }

  @override
  void dispose() {
    disposeHighlightAnimation();
    super.dispose();
  }
}
```

**Agent Checklist**:
- [ ] Chose StatelessWidget (container) or StatefulWidget (mixin)
- [ ] Set `autoStart` or trigger manually
- [ ] Configured duration and color
- [ ] Wrapped actual content widget

---

### 4. ReorderableListViewBase<T>

**When to use**:
- ✅ User needs to reorder items manually
- ✅ Drag & drop functionality
- ✅ Custom order persistence

**How to implement**:

```dart
// STEP 1: Extend ReorderableListViewBase
class YourReorderableList extends ReorderableListViewBase<YourItem> {
  final Function(List<YourItem>)? onReorderComplete;

  YourReorderableList({
    required List<YourItem> items,
    this.onReorderComplete,
  }) : super(
    items: items,
    config: ReorderableListConfig.smoothImmediate,
  );

  @override
  String getItemId(YourItem item) => item.id;

  @override
  Widget buildItem(BuildContext context, YourItem item, int index) {
    return HighlightContainer(
      key: Key(item.id),
      autoStart: false,
      child: YourItemCard(
        item: item,
        reorderHandle: ReorderableDragStartListener(
          index: index,
          child: Icon(Icons.drag_handle),
        ),
      ),
    );
  }

  @override
  void onReorderComplete(List<YourItem> reorderedItems) {
    onReorderComplete?.call(reorderedItems);
  }
}

// STEP 2: Use in page
class YourPage extends StatefulWidget {
  @override
  State<YourPage> createState() => _YourPageState();
}

class _YourPageState extends State<YourPage> {
  List<YourItem> items = [...];

  @override
  Widget build(BuildContext context) {
    return YourReorderableList(
      items: items,
      onReorderComplete: (reordered) {
        setState(() => items = reordered);
        _saveOrderToBackend(reordered); // Persist
      },
    );
  }

  Future<void> _saveOrderToBackend(List<YourItem> items) async {
    // Save new order to database
    for (int i = 0; i < items.length; i++) {
      await yourService.updateItemOrder(items[i].id, i);
    }
  }
}
```

**Agent Checklist**:
- [ ] Implemented `getItemId()`
- [ ] Implemented `buildItem()` with drag handle
- [ ] Implemented `onReorderComplete()`
- [ ] Updated local state with reordered list
- [ ] Persisted new order to backend

---

## Common Patterns

### Pattern 1: Combining Multiple Components

```dart
class YourComplexPage extends StatefulWidget {
  @override
  State<YourComplexPage> createState() => _YourComplexPageState();
}

class _YourComplexPageState extends State<YourComplexPage> {
  YourCategory? _selectedCategory;
  YourFilterConfig _filterConfig = YourFilterConfig();
  List<YourItem> _items = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // COMPONENT 1: Quick category filter
        CategoryScrollBar<YourItem, YourCategory>(
          items: _items,
          getCategoryValue: (item) => item.category,
          categoryValues: YourCategory.values,
          categoryLabel: (cat) => cat.label,
          selectedCategory: _selectedCategory,
          onCategorySelected: (category, filtered) {
            setState(() {
              _selectedCategory = category;
              _filterConfig = _filterConfig.copyWith(
                categories: category != null ? {category} : null,
              );
            });
          },
        ),

        // Additional filter UI
        YourAdvancedFiltersWidget(
          config: _filterConfig,
          onChanged: (config) => setState(() => _filterConfig = config),
        ),

        // COMPONENT 2: Filterable + reorderable list
        Expanded(
          child: YourReorderableFilterableList(
            items: _items,
            filterConfig: _filterConfig,
            onReorderComplete: (reordered) {
              setState(() => _items = reordered);
              _saveOrder(reordered);
            },
          ),
        ),
      ],
    );
  }
}
```

### Pattern 2: BLoC Integration

```dart
// If using BLoC for state management
class YourPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<YourBloc, YourState>(
      builder: (context, state) {
        if (state is YourLoading) {
          return CircularProgressIndicator();
        }

        if (state is YourLoaded) {
          return Column(
            children: [
              CategoryScrollBar<YourItem, YourCategory>(
                items: state.items,
                getCategoryValue: (item) => item.category,
                categoryValues: YourCategory.values,
                categoryLabel: (cat) => cat.label,
                selectedCategory: state.selectedCategory,
                onCategorySelected: (category, filtered) {
                  // Dispatch event to BLoC
                  context.read<YourBloc>().add(
                    CategoryFilterChanged(category),
                  );
                },
              ),
              Expanded(
                child: YourListView(
                  items: state.filteredItems,
                  filterConfig: state.filterConfig,
                ),
              ),
            ],
          );
        }

        return SizedBox.shrink();
      },
    );
  }
}
```

---

## Testing Components

### Test Template

```dart
// test/your_feature/your_list_view_test.dart
group('YourListView', () {
  testWidgets('filters items correctly', (tester) async {
    final items = [
      YourItem(id: '1', name: 'Item 1', category: YourCategory.category1),
      YourItem(id: '2', name: 'Item 2', category: YourCategory.category2),
    ];

    final config = YourFilterConfig(
      selectedCategories: {YourCategory.category1},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YourListView(
            items: items,
            filterConfig: config,
          ),
        ),
      ),
    );

    // Should only show items from category1
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsNothing);
  });
});
```

---

## Agent Workflow

### When User Requests List Feature

```
1. Identify requirements
   ├─ What type of items? (Product, User, Task, etc.)
   ├─ Filtering needed? (categories, dates, status, etc.)
   ├─ Sorting needed? (alphabetical, date, priority, etc.)
   ├─ Reordering needed? (drag & drop)
   └─ Highlight animation needed? (on create/update)

2. Choose components
   ├─ Base: FilterableListView<Item, FilterConfig>
   ├─ If enum filter: Add CategoryScrollBar<Item, Category>
   ├─ If reordering: Extend ReorderableListViewBase<Item>
   └─ If highlights: Use HighlightContainer or Mixin

3. Implement
   ├─ Create filter config class
   ├─ Implement filtering/sorting logic
   ├─ Create item widget
   ├─ Wire up state management
   └─ Add persistence (save to backend)

4. Test
   ├─ Unit test filtering logic
   ├─ Widget test UI rendering
   ├─ Integration test full flow
   └─ Manual test on device

5. Document
   ├─ Add dartdoc comments
   ├─ Update component guide (this file)
   └─ Create example in showcase app
```

---

## Troubleshooting

### Issue: Items not filtering
**Check**:
- [ ] `filterItems()` logic correct?
- [ ] `filterConfig` passed to widget?
- [ ] `hasActiveFilters()` returns true?
- [ ] UI using `filteredItems` not `items`?

**Debug**:
```dart
@override
List<YourItem> filterItems(List<YourItem> items, YourFilterConfig? config) {
  print('🔧 Filtering ${items.length} items with config: $config');

  final filtered = items.where((item) {
    // ... filter logic
    print('  Item ${item.id}: ${matches ? "✅" : "❌"}');
    return matches;
  }).toList();

  print('✅ Filtered result: ${filtered.length} items');
  return filtered;
}
```

### Issue: Reordering not persisting
**Check**:
- [ ] `onReorderComplete()` called?
- [ ] State updated with new order?
- [ ] Backend save successful?
- [ ] Item IDs unique?

**Debug**:
```dart
@override
void onReorderComplete(List<YourItem> reorderedItems) {
  print('🔧 Reorder complete: ${reorderedItems.map((i) => i.id).join(", ")}');

  onReorder?.call(reorderedItems);

  // Save to backend
  _saveOrder(reorderedItems).then((_) {
    print('✅ Order saved to backend');
  }).catchError((e) {
    print('❌ Failed to save order: $e');
  });
}
```

### Issue: Highlight animation not showing
**Check**:
- [ ] `autoStart` set to true?
- [ ] `triggerHighlight()` called?
- [ ] Animation initialized in `initState()`?
- [ ] Widget rebuilding?

**Debug**:
```dart
@override
void initState() {
  super.initState();
  print('🔧 Initializing highlight animation');
  initHighlightAnimation(this);
}

@override
void didUpdateWidget(YourWidget oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.item != widget.item) {
    print('🔧 Triggering highlight for ${widget.item.id}');
    triggerHighlight();
  }
}
```

---

## Quick Reference

### Component Selection Matrix

| Need | Component |
|------|-----------|
| Switch between 2 enums | `SlidableSwitch<T extends Enum>` |
| Chip with expandable content | `ExpandableChip<T>` |
| Inline toggleable text | `InlineToggle` |
| Simple list | `ListView.builder` |
| Filtered list | `FilterableListView<T, F>` |
| Category filter bar | `CategoryScrollBar<T, C>` |
| Reorderable list | `ReorderableListViewBase<T>` |
| Highlight animation | `HighlightContainer` or Mixin |
| Searchable list | Use `FilterableListView` + search filter |
| Infinite scroll | Use `FilterableListView` + pagination |

### File Locations

```
lib/core/components/
  ├── switches/
  │   └── slidable_switch.dart                 ✅ NEW
  ├── chips/
  │   └── expandable_chip.dart                 ✅ NEW
  ├── text/
  │   └── inline_toggle.dart                   ✅ NEW
  ├── lists/
  │   ├── base/
  │   │   ├── filterable_list_view.dart
  │   │   └── reorderable_list_view_base.dart
  │   └── mixins/
  │       └── highlight_animation_mixin.dart
  ├── filters/
  │   └── bars/
  │       └── category_scroll_bar.dart
  └── animations/
      └── highlight_container.dart
```

---

## Related Documentation

- [Dev Guide](./REUSABLE_COMPONENTS_DEV_GUIDE.md) - Human developer guide
- [Senior Dev Architecture](./SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md) - Architecture patterns
- [Component Library Architecture](./COMPONENT_LIBRARY_ARCHITECTURE.md) - Design decisions

---

**Agent Version**: 1.0
**Last Updated**: January 2025
**Status**: Active
