# 🎨 UI Showcase - Component Gallery Guide

> **Purpose**: Documentation for the UI Showcase feature in Profile section
> **Audience**: Developers, Designers, Claude Agents
> **Location**: Profile Page → UI Showcase (visible only for test@te.st)

---

## Overview

La **UI Showcase** è una galleria interattiva di tutti i componenti UI dell'app, accessibile dalla sezione Profilo. È uno strumento di sviluppo che permette di:

✅ **Visualizzare componenti isolati** senza contesto applicativo
✅ **Testare varianti** e stati diversi dei componenti
✅ **Documentare design system** con esempi live
✅ **Debug UI issues** in isolamento
✅ **Onboard developers** mostrando componenti disponibili

---

## Access & Visibility

### How to Access

1. Login with test account: `test@te.st`
2. Navigate to Profile tab
3. Scroll to "Info & Supporto" section
4. Tap on "UI Showcase" card

### Visibility Logic

```dart
// lib/views/profile_page.dart (line 331)
if (user?.email == 'test@te.st')
  _buildListTile(
    context: context,
    icon: Icons.dashboard_customize,
    title: 'UI Showcase',
    subtitle: 'Galleria componenti e design system',
    color: Colors.purple,
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UIShowcaseMenu(),
        ),
      );
    },
  ),
```

**Note**: Solo visibile per account test per evitare confusione utenti finali

---

## Architecture

### File Structure

```
lib/views/showcase/
  ├── ui_showcase_menu.dart           # Main menu with component list
  ├── component_showcases/
  │   ├── task_item_showcase.dart     # Task component variations
  │   ├── filter_bar_showcase.dart    # Filter/sort bar demos
  │   ├── animation_showcase.dart     # Animation demos
  │   └── (other showcases...)
  └── widgets/
      ├── showcase_scaffold.dart      # Common layout
      ├── variant_selector.dart       # Toggle between variants
      └── code_preview.dart           # Show code snippets
```

### Navigation Flow

```
ProfilePage
    ↓
UIShowcaseMenu (list of component categories)
    ↓
Category Page (e.g., TaskItemShowcase)
    ↓
Component Variants (different states/configs)
```

---

## Current Components in Showcase

### 1. Task Components
**File**: `lib/views/showcase/component_showcases/task_item_showcase.dart`

**Showcases**:
- **GranularTaskItem**: Single task card with all variations
  - Priority variants (High, Medium, Low)
  - Status variants (To Do, In Progress, Done)
  - Size variants (Small, Medium, Large)
  - With/without tags
  - With/without description
- **TaskCreationRow**: Inline task creation
  - Collapsed state
  - Expanded state
  - Filled form state
  - Validation errors

### 2. Filter & Sort Components
**File**: `lib/views/showcase/component_showcases/filter_bar_showcase.dart`

**Showcases**:
- **CompactFilterSortBar**: Filter/sort UI
  - No filters active
  - Single filter active
  - Multiple filters active
  - All filters active
- **CategoryScrollBar**: Horizontal category filter
  - All categories
  - Selected category
  - With counts
  - Without counts

### 3. Animation Components
**File**: `lib/views/showcase/component_showcases/animation_showcase.dart`

**Showcases**:
- **HighlightContainer**: Highlight animation
  - Auto-start
  - Manual trigger
  - Different colors
  - Different durations
- **Drag Handle Indicator**: iOS-style drag handle
  - Different sizes
  - Different opacities
  - Animated states

### 4. List Components
**File**: `lib/views/showcase/component_showcases/list_showcase.dart`

**Showcases**:
- **FilterableListView**: Filtered list
  - Empty state
  - Loading state
  - Error state
  - With items
  - Filtered items
- **ReorderableListView**: Drag & drop list
  - Static (no reorder)
  - Smooth animation
  - Immediate animation

---

## Adding New Component to Showcase

### Step-by-Step Guide

#### 1. Create Showcase File

```dart
// lib/views/showcase/component_showcases/your_component_showcase.dart

import 'package:flutter/material.dart';
import 'package:solducci/views/showcase/widgets/showcase_scaffold.dart';

class YourComponentShowcase extends StatefulWidget {
  const YourComponentShowcase({super.key});

  @override
  State<YourComponentShowcase> createState() => _YourComponentShowcaseState();
}

class _YourComponentShowcaseState extends State<YourComponentShowcase> {
  // State for variant selection
  String _selectedVariant = 'default';

  @override
  Widget build(BuildContext context) {
    return ShowcaseScaffold(
      title: 'Your Component Name',
      description: 'Brief description of the component',
      variants: _buildVariants(),
      currentVariant: _selectedVariant,
      onVariantChanged: (variant) {
        setState(() => _selectedVariant = variant);
      },
    );
  }

  Map<String, Widget> _buildVariants() {
    return {
      'default': _buildDefaultVariant(),
      'variant1': _buildVariant1(),
      'variant2': _buildVariant2(),
    };
  }

  Widget _buildDefaultVariant() {
    return Center(
      child: YourComponent(
        // Default configuration
      ),
    );
  }

  Widget _buildVariant1() {
    return Center(
      child: YourComponent(
        // Variant 1 configuration
      ),
    );
  }

  Widget _buildVariant2() {
    return Center(
      child: YourComponent(
        // Variant 2 configuration
      ),
    );
  }
}
```

#### 2. Add to UIShowcaseMenu

```dart
// lib/views/showcase/ui_showcase_menu.dart

class UIShowcaseMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('UI Showcase')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // ... existing categories

          // NEW: Your component category
          _buildCategoryCard(
            context: context,
            icon: Icons.your_icon,
            title: 'Your Component',
            description: 'Brief description',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => YourComponentShowcase(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
```

#### 3. Document Variants

```dart
// In your showcase file, add comments
Widget _buildVariant1() {
  return Center(
    child: Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'Variant 1: High Priority',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'This variant shows the component with high priority styling.',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),

          // Component
          YourComponent(
            priority: Priority.high,
          ),

          SizedBox(height: 24),

          // Code snippet (optional)
          CodePreview(
            code: '''
YourComponent(
  priority: Priority.high,
)
            ''',
          ),
        ],
      ),
    ),
  );
}
```

---

## Showcase Best Practices

### 1. **Cover All States**

```dart
Map<String, Widget> _buildVariants() {
  return {
    'default': _buildDefaultState(),
    'loading': _buildLoadingState(),
    'error': _buildErrorState(),
    'empty': _buildEmptyState(),
    'with_data': _buildWithDataState(),
    'disabled': _buildDisabledState(),
  };
}
```

### 2. **Show Edge Cases**

```dart
Map<String, Widget> _buildVariants() {
  return {
    'normal': _buildNormalCase(),
    'very_long_text': _buildLongTextCase(),
    'very_short_text': _buildShortTextCase(),
    'many_items': _buildManyItemsCase(),
    'single_item': _buildSingleItemCase(),
    'special_characters': _buildSpecialCharsCase(),
  };
}
```

### 3. **Add Descriptions**

```dart
Widget _buildVariant() {
  return Container(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with description
        _buildVariantHeader(
          title: 'Variant Name',
          description: 'Detailed description of what this variant shows',
        ),

        SizedBox(height: 24),

        // Component
        YourComponent(),

        SizedBox(height: 24),

        // Usage notes
        _buildUsageNotes([
          'Use this variant when...',
          'Avoid this variant if...',
          'Note: This variant requires...',
        ]),
      ],
    ),
  );
}
```

### 4. **Make it Interactive**

```dart
class _YourComponentShowcaseState extends State<YourComponentShowcase> {
  bool _isEnabled = true;
  String _text = 'Sample text';
  Priority _priority = Priority.medium;

  Widget _buildInteractiveDemo() {
    return Column(
      children: [
        // Controls
        SwitchListTile(
          title: Text('Enabled'),
          value: _isEnabled,
          onChanged: (value) => setState(() => _isEnabled = value),
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Text'),
          onChanged: (value) => setState(() => _text = value),
        ),
        DropdownButton<Priority>(
          value: _priority,
          items: Priority.values.map((p) {
            return DropdownMenuItem(value: p, child: Text(p.name));
          }).toList(),
          onChanged: (value) => setState(() => _priority = value!),
        ),

        SizedBox(height: 32),

        // Component with live values
        YourComponent(
          enabled: _isEnabled,
          text: _text,
          priority: _priority,
        ),
      ],
    );
  }
}
```

---

## Showcase Helper Widgets

### ShowcaseScaffold

**Purpose**: Common layout for all showcase pages

```dart
ShowcaseScaffold(
  title: 'Component Name',
  description: 'Component description',
  variants: {
    'variant1': Widget1(),
    'variant2': Widget2(),
  },
  currentVariant: _selectedVariant,
  onVariantChanged: (variant) {
    setState(() => _selectedVariant = variant);
  },
)
```

### VariantSelector

**Purpose**: Dropdown to switch between variants

```dart
VariantSelector(
  variants: ['Default', 'Variant 1', 'Variant 2'],
  selectedVariant: _selectedVariant,
  onChanged: (variant) {
    setState(() => _selectedVariant = variant);
  },
)
```

### CodePreview

**Purpose**: Show code snippet with syntax highlighting

```dart
CodePreview(
  code: '''
YourComponent(
  property1: value1,
  property2: value2,
)
  ''',
  language: 'dart',
)
```

### UsageNotes

**Purpose**: Show usage guidelines

```dart
UsageNotes(
  notes: [
    '✅ Use when user needs to...',
    '❌ Avoid when...',
    '⚠️ Important: ...',
  ],
)
```

---

## Example: Complete Showcase

```dart
// lib/views/showcase/component_showcases/button_showcase.dart

import 'package:flutter/material.dart';
import 'package:solducci/views/showcase/widgets/showcase_scaffold.dart';
import 'package:solducci/views/showcase/widgets/code_preview.dart';
import 'package:solducci/views/showcase/widgets/usage_notes.dart';

class ButtonShowcase extends StatefulWidget {
  const ButtonShowcase({super.key});

  @override
  State<ButtonShowcase> createState() => _ButtonShowcaseState();
}

class _ButtonShowcaseState extends State<ButtonShowcase> {
  String _selectedVariant = 'primary';

  @override
  Widget build(BuildContext context) {
    return ShowcaseScaffold(
      title: 'Button Component',
      description: 'Standard app buttons with different styles and states',
      variants: _buildVariants(),
      currentVariant: _selectedVariant,
      onVariantChanged: (variant) {
        setState(() => _selectedVariant = variant);
      },
    );
  }

  Map<String, Widget> _buildVariants() {
    return {
      'primary': _buildPrimaryButton(),
      'secondary': _buildSecondaryButton(),
      'text': _buildTextButton(),
      'disabled': _buildDisabledButton(),
      'loading': _buildLoadingButton(),
      'icon': _buildIconButton(),
    };
  }

  Widget _buildPrimaryButton() {
    return _buildVariantLayout(
      title: 'Primary Button',
      description: 'Main call-to-action button with filled background',
      component: FilledButton(
        onPressed: () {},
        child: Text('Primary Button'),
      ),
      code: '''
FilledButton(
  onPressed: () {},
  child: Text('Primary Button'),
)
      ''',
      usageNotes: [
        '✅ Use for main actions (Save, Continue, Submit)',
        '❌ Don\'t use more than one per screen',
        '⚠️ Always provide onPressed handler',
      ],
    );
  }

  Widget _buildSecondaryButton() {
    return _buildVariantLayout(
      title: 'Secondary Button',
      description: 'Secondary action with outlined style',
      component: OutlinedButton(
        onPressed: () {},
        child: Text('Secondary Button'),
      ),
      code: '''
OutlinedButton(
  onPressed: () {},
  child: Text('Secondary Button'),
)
      ''',
      usageNotes: [
        '✅ Use for secondary actions (Cancel, Back)',
        '✅ Can have multiple per screen',
      ],
    );
  }

  Widget _buildDisabledButton() {
    return _buildVariantLayout(
      title: 'Disabled Button',
      description: 'Button in disabled state (no action)',
      component: FilledButton(
        onPressed: null, // Disabled
        child: Text('Disabled Button'),
      ),
      code: '''
FilledButton(
  onPressed: null, // Set to null to disable
  child: Text('Disabled Button'),
)
      ''',
      usageNotes: [
        '✅ Use when action not available yet',
        '⚠️ Provide tooltip explaining why disabled',
      ],
    );
  }

  Widget _buildVariantLayout({
    required String title,
    required String description,
    required Widget component,
    required String code,
    required List<String> usageNotes,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Description
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          SizedBox(height: 32),

          // Component Preview
          Center(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: component,
            ),
          ),

          SizedBox(height: 32),

          // Code Preview
          Text(
            'Code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          CodePreview(code: code),

          SizedBox(height: 32),

          // Usage Notes
          Text(
            'Usage Guidelines',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          UsageNotes(notes: usageNotes),
        ],
      ),
    );
  }
}
```

---

## Agent Guide: Adding to Showcase

### When User Requests Showcase Addition

```
1. Identify component to showcase
   ├─ Existing component in lib/widgets/ or lib/features/
   └─ New component being created

2. Determine variants
   ├─ Different states (default, loading, error, empty)
   ├─ Different configurations (sizes, colors, styles)
   ├─ Edge cases (long text, empty text, special chars)
   └─ Interactive demos (if applicable)

3. Create showcase file
   ├─ lib/views/showcase/component_showcases/your_component_showcase.dart
   ├─ Implement _buildVariants() for each variant
   ├─ Add descriptions and usage notes
   └─ Add code snippets

4. Register in menu
   ├─ Add category card in UIShowcaseMenu
   ├─ Set appropriate icon and color
   └─ Link to new showcase page

5. Test
   ├─ Login as test@te.st
   ├─ Navigate to showcase
   ├─ Verify all variants render correctly
   └─ Check variant switching works
```

---

## Future Enhancements

### Planned Features
- [ ] Search/filter components
- [ ] Export component as image
- [ ] Dark mode toggle for showcase
- [ ] Accessibility checker
- [ ] Performance metrics display
- [ ] Responsive breakpoint tester

---

## Related Documentation

- [Reusable Components Dev Guide](./REUSABLE_COMPONENTS_DEV_GUIDE.md)
- [Senior Dev Architecture](./SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md)
- [Component Library Architecture](./COMPONENT_LIBRARY_ARCHITECTURE.md)

---

**Version**: 1.0
**Last Updated**: January 2025
**Access**: test@te.st only
**Location**: Profile → UI Showcase
