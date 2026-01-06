# 🧩 Reusable Components Library - Developer Guide

> **Audience**: Flutter Developers
> **Purpose**: Documentation for reusable UI components extracted from Documents feature
> **Level**: Practical implementation guide

---

## Overview

Durante lo sviluppo della feature Documents, abbiamo identificato e estratto **componenti riutilizzabili** che possono essere usati in tutta l'applicazione. Questi componenti seguono principi SOLID e sono progettati per essere generici, testabili e performanti.

### Benefits
✅ **Riduzione duplicazione codice**: -67% code duplication
✅ **Consistency UI**: Stessa UX in tutta l'app
✅ **Faster development**: Drop-in components per nuove feature
✅ **Testability**: Componenti piccoli e isolati

---

## Component Library Structure

```
lib/
├── core/
│   └── components/
│       ├── lists/
│       │   ├── base/
│       │   │   ├── filterable_list_view.dart
│       │   │   └── reorderable_list_view_base.dart
│       │   └── mixins/
│       │       └── highlight_animation_mixin.dart
│       ├── filters/
│       │   └── bars/
│       │       └── category_scroll_bar.dart
│       └── animations/
│           └── highlight_container.dart
│
└── features/documents/presentation/components/
    ├── granular_task_item.dart        # Task-specific implementation
    └── task_creation_row.dart         # Feature-specific component
```

---

## Core Components

### 1. FilterableListView<T, F>

**Purpose**: Base class for any list with filtering and sorting

**Type Parameters**:
- `T`: Item type (Task, Product, User, etc.)
- `F`: Filter configuration type

**Location**: `lib/core/components/lists/base/filterable_list_view.dart`

#### Usage Example

```dart
// 1. Define your filter config
class ProductFilterConfig {
  final Set<ProductCategory>? categories;
  final PriceRange? priceRange;
  final bool onlyInStock;

  bool get hasFilters =>
    categories?.isNotEmpty ?? false ||
    priceRange != null ||
    onlyInStock;
}

// 2. Extend FilterableListView
class ProductListView extends FilterableListView<Product, ProductFilterConfig> {
  ProductListView({
    required List<Product> items,
    ProductFilterConfig? filterConfig,
  }) : super(
    items: items,
    filterConfig: filterConfig,
  );

  @override
  List<Product> filterItems(List<Product> items, ProductFilterConfig? config) {
    if (config == null || !config.hasFilters) return items;

    return items.where((product) {
      // Category filter
      if (config.categories?.isNotEmpty ?? false) {
        if (!config.categories!.contains(product.category)) {
          return false;
        }
      }

      // Price range filter
      if (config.priceRange != null) {
        if (product.price < config.priceRange!.min ||
            product.price > config.priceRange!.max) {
          return false;
        }
      }

      // Stock filter
      if (config.onlyInStock && product.stock == 0) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  List<Product> sortItems(List<Product> items, ProductFilterConfig? config) {
    // Implement your sorting logic
    return items..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Widget buildItem(BuildContext context, Product item, int index) {
    return ProductCard(product: item);
  }

  @override
  bool hasActiveFilters() => filterConfig?.hasFilters ?? false;

  @override
  ProductFilterConfig getDefaultFilter() => ProductFilterConfig();

  @override
  Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Nessun prodotto trovato'),
        ],
      ),
    );
  }
}

// 3. Use in your widget
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProductListView(
      items: products,
      filterConfig: ProductFilterConfig(
        categories: {ProductCategory.electronics},
        onlyInStock: true,
      ),
    );
  }
}
```

#### API Reference

```dart
abstract class FilterableListView<T, F> extends StatelessWidget {
  final List<T> items;                    // All items
  final F? filterConfig;                  // Current filter config

  // Required overrides
  List<T> filterItems(List<T> items, F? config);
  List<T> sortItems(List<T> items, F? config);
  Widget buildItem(BuildContext context, T item, int index);
  bool hasActiveFilters();
  F getDefaultFilter();

  // Optional overrides
  Widget buildEmptyState(BuildContext context);
  Widget buildLoadingState(BuildContext context);
  Widget buildErrorState(BuildContext context, String error);
  IconData getEmptyStateIcon();
  String getEmptyStateTitle();
  String? getEmptyStateSubtitle();
}
```

---

### 2. CategoryScrollBar<T, C>

**Purpose**: Horizontal scrolling filter bar for any enum-based category

**Type Parameters**:
- `T`: Item type
- `C`: Category enum type

**Location**: `lib/core/components/filters/bars/category_scroll_bar.dart`

#### Usage Example

```dart
// 1. Define your enum
enum ProductCategory {
  electronics,
  clothing,
  food,
  books;

  String get label {
    switch (this) {
      case electronics: return 'Electronics';
      case clothing: return 'Abbigliamento';
      case food: return 'Alimentari';
      case books: return 'Libri';
    }
  }

  Color get color {
    switch (this) {
      case electronics: return Colors.blue;
      case clothing: return Colors.pink;
      case food: return Colors.green;
      case books: return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case electronics: return Icons.phone_android;
      case clothing: return Icons.checkroom;
      case food: return Icons.restaurant;
      case books: return Icons.book;
    }
  }
}

// 2. Use CategoryScrollBar
class ProductFilterBar extends StatelessWidget {
  final List<Product> products;
  final ProductCategory? selectedCategory;
  final Function(ProductCategory?, List<Product>) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return CategoryScrollBar<Product, ProductCategory>(
      items: products,
      getCategoryValue: (product) => product.category,
      categoryValues: ProductCategory.values,
      categoryLabel: (cat) => cat.label,
      categoryColor: (cat) => cat.color,
      categoryIcon: (cat) => cat.icon,
      selectedCategory: selectedCategory,
      showCount: true,                    // Show (5) next to category
      allLabel: 'Tutti',
      allIcon: Icons.apps,
      onCategorySelected: onCategorySelected,
    );
  }
}

// 3. Use in page
class ProductsPage extends StatefulWidget {
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  ProductCategory? _selectedCategory;
  List<Product> _filteredProducts = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductFilterBar(
          products: allProducts,
          selectedCategory: _selectedCategory,
          onCategorySelected: (category, filtered) {
            setState(() {
              _selectedCategory = category;
              _filteredProducts = filtered;
            });
          },
        ),
        Expanded(
          child: ProductListView(items: _filteredProducts),
        ),
      ],
    );
  }
}
```

#### API Reference

```dart
class CategoryScrollBar<T, C extends Enum> extends StatefulWidget {
  final List<T> items;                                    // All items
  final C? Function(T item) getCategoryValue;             // Extract category from item
  final List<C> categoryValues;                           // All enum values
  final String Function(C category) categoryLabel;        // Category display name
  final Color? Function(C category)? categoryColor;       // Optional category color
  final IconData? Function(C category)? categoryIcon;     // Optional category icon
  final void Function(C? category, List<T> filteredItems) onCategorySelected;
  final C? selectedCategory;                              // Currently selected
  final String allLabel;                                  // "All" chip label
  final IconData allIcon;                                 // "All" chip icon
  final bool showCount;                                   // Show (N) badge
}
```

**Features**:
- ✅ Auto-calculates item count per category
- ✅ Highlights selected category
- ✅ Smooth horizontal scrolling
- ✅ Generic for ANY enum type
- ✅ Customizable colors and icons

---

### 3. HighlightAnimationMixin

**Purpose**: Reusable highlight animation for list items

**Location**: `lib/core/components/lists/mixins/highlight_animation_mixin.dart`

#### Usage Example

**Option A: Mixin (for StatefulWidget)**

```dart
class ProductItem extends StatefulWidget {
  final Product product;

  @override
  State<ProductItem> createState() => _ProductItemState();
}

class _ProductItemState extends State<ProductItem>
    with SingleTickerProviderStateMixin, HighlightAnimationMixin {

  @override
  void initState() {
    super.initState();
    initHighlightAnimation(this); // Initialize animation
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: highlightAnimation!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: highlightColor, // From mixin
            borderRadius: BorderRadius.circular(8),
          ),
          child: ProductCard(product: widget.product),
        );
      },
    );
  }

  @override
  void didUpdateWidget(ProductItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger highlight when product changes
    if (oldWidget.product.id != widget.product.id) {
      triggerHighlight();
    }
  }

  @override
  void dispose() {
    disposeHighlightAnimation();
    super.dispose();
  }
}
```

**Option B: HighlightContainer (for StatelessWidget)**

```dart
class ProductItem extends StatelessWidget {
  final Product product;
  final bool autoStart;

  @override
  Widget build(BuildContext context) {
    return HighlightContainer(
      autoStart: autoStart,  // Start animation immediately
      duration: Duration(milliseconds: 500),
      highlightColor: Colors.amber.withOpacity(0.3),
      child: ProductCard(product: product),
    );
  }
}
```

#### API Reference

**Mixin**:
```dart
mixin HighlightAnimationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin {
  AnimationController? highlightAnimation;
  Animation<Color?>? colorAnimation;

  void initHighlightAnimation(TickerProvider vsync);
  void triggerHighlight();
  void disposeHighlightAnimation();

  Color get highlightColor; // Current animated color
}
```

**Container**:
```dart
class HighlightContainer extends StatefulWidget {
  final Widget child;
  final bool autoStart;
  final Duration duration;
  final Color highlightColor;
  final Color? baseColor;
}
```

**When to use**:
- ✅ Item appena creato/aggiunto
- ✅ Item riordinato con drag & drop
- ✅ Item modificato
- ✅ Visual feedback importante

---

### 4. ReorderableListViewBase<T>

**Purpose**: Base class for drag & drop reorderable lists

**Location**: `lib/core/components/lists/base/reorderable_list_view_base.dart`

#### Usage Example

```dart
class ProductReorderableList extends ReorderableListViewBase<Product> {
  final Function(List<Product>)? onReorder;

  ProductReorderableList({
    required List<Product> items,
    this.onReorder,
  }) : super(
    items: items,
    config: ReorderableListConfig.smoothImmediate,
  );

  @override
  String getItemId(Product item) => item.id;

  @override
  Widget buildItem(BuildContext context, Product item, int index) {
    return HighlightContainer(
      key: Key(item.id),
      autoStart: false,
      child: ProductCard(
        product: item,
        reorderHandle: ReorderableDragStartListener(
          index: index,
          child: Icon(Icons.drag_handle),
        ),
      ),
    );
  }

  @override
  void onReorderComplete(List<Product> reorderedItems) {
    onReorder?.call(reorderedItems);
  }
}

// Usage
class ProductsPage extends StatefulWidget {
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product> products = [...];

  @override
  Widget build(BuildContext context) {
    return ProductReorderableList(
      items: products,
      onReorder: (reordered) {
        setState(() => products = reordered);
        _saveOrder(reordered); // Persist to backend
      },
    );
  }
}
```

#### API Reference

```dart
abstract class ReorderableListViewBase<T> extends StatelessWidget {
  final List<T> items;
  final ReorderableListConfig config;

  // Required overrides
  String getItemId(T item);
  Widget buildItem(BuildContext context, T item, int index);
  void onReorderComplete(List<T> reorderedItems);
}

enum ReorderableListConfig {
  smoothImmediate,    // Smooth animation, immediate response
  smooth,             // Smooth animation
  static,             // No animation
  disabled,           // Reordering disabled
}
```

---

## Component Composition Examples

### Example 1: Product Catalog

```dart
class ProductCatalogPage extends StatefulWidget {
  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  ProductCategory? _selectedCategory;
  ProductFilterConfig _filterConfig = ProductFilterConfig();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Catalogo Prodotti')),
      body: Column(
        children: [
          // COMPONENT 1: Category filter bar
          CategoryScrollBar<Product, ProductCategory>(
            items: products,
            getCategoryValue: (p) => p.category,
            categoryValues: ProductCategory.values,
            categoryLabel: (c) => c.label,
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

          // Additional filters
          ProductAdvancedFilters(
            config: _filterConfig,
            onChanged: (config) => setState(() => _filterConfig = config),
          ),

          // COMPONENT 2: Filterable list
          Expanded(
            child: ProductListView(
              items: products,
              filterConfig: _filterConfig,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Example 2: Team Members Kanban

```dart
class TeamKanbanBoard extends StatelessWidget {
  final List<TeamMember> members;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Column 1: Available
        Expanded(
          child: _buildColumn(
            'Available',
            members.where((m) => m.status == MemberStatus.available).toList(),
          ),
        ),

        // Column 2: Busy
        Expanded(
          child: _buildColumn(
            'Busy',
            members.where((m) => m.status == MemberStatus.busy).toList(),
          ),
        ),

        // Column 3: Offline
        Expanded(
          child: _buildColumn(
            'Offline',
            members.where((m) => m.status == MemberStatus.offline).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(String title, List<TeamMember> members) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          // COMPONENT: Reorderable list per column
          child: MemberReorderableList(
            items: members,
            onReorder: (reordered) => _updateMemberOrder(reordered),
          ),
        ),
      ],
    );
  }
}
```

---

## Performance Best Practices

### 1. Use const Constructors

```dart
// ❌ BAD
return CategoryScrollBar(
  items: products,
  categoryValues: ProductCategory.values,
  categoryLabel: (c) => c.label,
  // ...
);

// ✅ GOOD (if possible)
return const CategoryScrollBar(
  categoryValues: ProductCategory.values,
  categoryLabel: _getCategoryLabel,
  // ...
);
```

### 2. Avoid Creating Functions in build()

```dart
// ❌ BAD
Widget build(BuildContext context) {
  return CategoryScrollBar(
    categoryLabel: (c) => c.label, // New function every rebuild!
  );
}

// ✅ GOOD
String _getCategoryLabel(ProductCategory cat) => cat.label;

Widget build(BuildContext context) {
  return CategoryScrollBar(
    categoryLabel: _getCategoryLabel, // Reused reference
  );
}
```

### 3. Memoize Expensive Operations

```dart
class _MyWidgetState extends State<MyWidget> {
  late List<Product> _filteredProducts;

  @override
  void initState() {
    super.initState();
    _filteredProducts = _filterProducts(widget.products);
  }

  @override
  void didUpdateWidget(MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.products != oldWidget.products ||
        widget.filterConfig != oldWidget.filterConfig) {
      _filteredProducts = _filterProducts(widget.products);
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    // Expensive operation - cache result
    return products.where((p) => /* complex filter */).toList();
  }
}
```

---

## Testing Components

### Unit Test Example

```dart
// test/components/category_scroll_bar_test.dart
group('CategoryScrollBar', () {
  testWidgets('renders all categories', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryScrollBar<Product, ProductCategory>(
            items: testProducts,
            getCategoryValue: (p) => p.category,
            categoryValues: ProductCategory.values,
            categoryLabel: (c) => c.label,
            onCategorySelected: (_, __) {},
          ),
        ),
      ),
    );

    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('Abbigliamento'), findsOneWidget);
    expect(find.text('Alimentari'), findsOneWidget);
  });

  testWidgets('filters items on tap', (tester) async {
    List<Product>? filteredResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryScrollBar<Product, ProductCategory>(
            items: testProducts,
            getCategoryValue: (p) => p.category,
            categoryValues: ProductCategory.values,
            categoryLabel: (c) => c.label,
            onCategorySelected: (cat, filtered) {
              filteredResult = filtered;
            },
          ),
        ),
      ),
    );

    // Tap Electronics category
    await tester.tap(find.text('Electronics'));
    await tester.pump();

    expect(filteredResult, isNotNull);
    expect(filteredResult!.every((p) => p.category == ProductCategory.electronics), true);
  });
});
```

---

## Migration Guide

### Migrating Existing Code to Use Components

**Before**:
```dart
class ProductsPage extends StatefulWidget {
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product> products = [];
  ProductCategory? selectedCategory;

  @override
  Widget build(BuildContext context) {
    // 300 lines of filtering, sorting, rendering logic...
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        // Complex item rendering...
      },
    );
  }
}
```

**After**:
```dart
class ProductsPage extends StatelessWidget {
  final List<Product> products;
  final ProductFilterConfig filterConfig;

  @override
  Widget build(BuildContext context) {
    return ProductListView(
      items: products,
      filterConfig: filterConfig,
    );
  }
}
```

**Reduction**: -70% code, +100% reusability

---

## Troubleshooting

### Issue: Component not rebuilding
**Cause**: Passing same instance
**Solution**: Use `copyWith()` or create new instance

```dart
// ❌ BAD
setState(() {
  filterConfig.categories.add(newCategory); // Mutating
});

// ✅ GOOD
setState(() {
  filterConfig = filterConfig.copyWith(
    categories: {...filterConfig.categories, newCategory},
  );
});
```

### Issue: Performance degradation with large lists
**Cause**: Not using `ListView.builder`
**Solution**: FilterableListView uses builder internally, but ensure your `buildItem` is efficient

```dart
@override
Widget buildItem(BuildContext context, Product product, int index) {
  // ❌ BAD: Expensive computation in build
  final relatedProducts = _findRelatedProducts(product); // SLOW!

  // ✅ GOOD: Precompute or cache
  return ProductCard(product: product);
}
```

---

## Future Components (Roadmap)

### Q1 2025
- [ ] `SearchableListView<T>` - List with built-in search
- [ ] `InfiniteScrollListView<T>` - Pagination support
- [ ] `DraggableCard` - Drag between columns (Kanban)

### Q2 2025
- [ ] `TimelineView<T>` - Vertical timeline component
- [ ] `ChartWidget` - Generic chart component
- [ ] `FormBuilder<T>` - Dynamic form generation

---

## Contributing

### Adding New Component

1. **Create component** in `lib/core/components/`
2. **Make it generic** (use type parameters)
3. **Write tests** (unit + widget)
4. **Document API** in this file
5. **Create example** in showcase app

### Component Checklist

- [ ] Generic (works with any type)
- [ ] Testable (no tight coupling)
- [ ] Performant (const, memoization)
- [ ] Documented (dartdoc + this guide)
- [ ] Accessible (semantic labels, contrast)
- [ ] Responsive (works on all screen sizes)

---

## Related Documentation

- [Claude Agent Components Guide](./REUSABLE_COMPONENTS_AGENT_GUIDE.md)
- [Senior Dev Architecture](./SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md)
- [Component Library Architecture](./COMPONENT_LIBRARY_ARCHITECTURE.md)

---

**Version**: 1.0
**Last Updated**: January 2025
**Maintained By**: Frontend Team
