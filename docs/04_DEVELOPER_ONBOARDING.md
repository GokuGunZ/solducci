# Solducci - Developer Onboarding Guide

> **Audience**: New developers joining the team
> **Level**: Practical, step-by-step guide

---

## Welcome to Solducci!

This guide will help you get up and running with the Solducci codebase. By the end, you'll have:
- ✅ Development environment set up
- ✅ App running locally
- ✅ Understanding of project structure
- ✅ Knowledge of development workflow
- ✅ Made your first contribution

**Estimated time**: 2-3 hours

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Understanding the Codebase](#understanding-the-codebase)
4. [Development Workflow](#development-workflow)
5. [Common Tasks](#common-tasks)
6. [Debugging Tips](#debugging-tips)
7. [Code Style Guide](#code-style-guide)
8. [Making Your First Contribution](#making-your-first-contribution)

---

## Prerequisites

### Required Tools

#### 1. Flutter SDK
```bash
# Install Flutter (visit https://flutter.dev/docs/get-started/install)
# Verify installation
flutter --version

# Expected: Flutter 3.x or higher
```

#### 2. Dart SDK
```bash
# Comes with Flutter, verify:
dart --version

# Expected: Dart 3.8.1 or higher
```

#### 3. IDE (Choose one)

**Option A: VS Code (Recommended)**
```bash
# Install VS Code: https://code.visualstudio.com/

# Required extensions:
- Flutter (by Dart Code)
- Dart (by Dart Code)
- Flutter Widget Snippets

# Optional but helpful:
- Error Lens
- Bracket Pair Colorizer
- GitLens
```

**Option B: Android Studio**
```bash
# Install Android Studio: https://developer.android.com/studio

# Install plugins:
- Flutter plugin
- Dart plugin
```

#### 4. Platform-Specific Tools

**For iOS development (macOS only)**
```bash
# Install Xcode from App Store
# Install CocoaPods
sudo gem install cocoapods
```

**For Android development**
```bash
# Android Studio includes Android SDK
# Verify setup:
flutter doctor

# Accept Android licenses:
flutter doctor --android-licenses
```

#### 5. Git
```bash
# Verify installation
git --version

# Configure (if not done)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## Initial Setup

### Step 1: Clone Repository

```bash
# Clone the repository
git clone <repository-url>
cd solducci

# Check current branch
git branch
# Should show: * Feature-Bubble_views (or main)

# If on Feature-Bubble_views, switch to main for stable version
git checkout main
```

### Step 2: Install Dependencies

```bash
# Get Flutter packages
flutter pub get

# This will download all dependencies from pubspec.yaml
# Expected output: "Got dependencies!"
```

### Step 3: Set Up Supabase Backend

#### Create Supabase Project
1. Go to [https://supabase.com](https://supabase.com)
2. Sign up / Log in
3. Click "New Project"
4. Fill in:
   - **Name**: `solducci-dev` (or your preference)
   - **Database Password**: (save this securely!)
   - **Region**: Choose closest to you
5. Wait for project to be created (~2 minutes)

#### Get Supabase Credentials
1. In Supabase dashboard, go to **Settings** → **API**
2. Copy:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

#### Configure Environment Variables

**Option A: Development (.env file)**
```bash
# Create assets/dev directory (if not exists)
mkdir -p assets/dev

# Create .env file
touch assets/dev/.env

# Open .env file and add:
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

**Option B: Production (dart-define)**
```bash
# For production builds, use:
flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>
```

### Step 4: Run Database Migrations

1. In Supabase dashboard, go to **SQL Editor**
2. Open each file in `supabase/migrations/` in order
3. Copy contents and execute in SQL Editor
4. Start with: `001_multi_user_setup_v3.sql`
5. Run all migration files sequentially

**Key migrations**:
- `001_multi_user_setup_v3.sql` - Main schema
- `002_add_expense_splits.sql` - Split tracking
- `003_add_group_invites.sql` - Invitation system
- (Run all others in numeric order)

#### Verify Database Setup
In Supabase SQL Editor, run:
```sql
-- Check tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';

-- Expected tables:
-- profiles, groups, group_members, group_invites, expenses, expense_splits
```

### Step 5: Verify Setup

```bash
# Run Flutter doctor to check setup
flutter doctor

# Should see all checkmarks (✓)
# Some optional warnings are OK
```

### Step 6: Run the App

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or for Chrome (web):
flutter run -d chrome

# Or for iOS simulator:
flutter run -d "iPhone 14 Pro"

# Or for Android emulator:
flutter run -d emulator-5554
```

**Expected result**:
- App launches
- Shows splash screen
- Redirects to login page
- You can create an account

### Step 7: Create Test Account

1. On login page, tap "Sign Up"
2. Enter email: `test@example.com`
3. Enter password: `test123`
4. Confirm password: `test123`
5. Tap "Sign Up"
6. Should redirect to home page

**Congratulations!** You're now running Solducci locally.

---

## Understanding the Codebase

### Project Structure

```
solducci/
├── lib/                          # Main application code
│   ├── main.dart                 # App entry point
│   │
│   ├── models/                   # Data models
│   │   ├── expense.dart          # Expense model
│   │   ├── group.dart            # Group models
│   │   ├── split_type.dart       # Split type enum
│   │   ├── dashboard_data.dart   # Analytics models
│   │   └── ...
│   │
│   ├── service/                  # Business logic (singletons)
│   │   ├── auth_service.dart     # Authentication
│   │   ├── expense_service.dart  # Expense CRUD
│   │   ├── group_service.dart    # Group management
│   │   ├── context_manager.dart  # Context switching
│   │   └── profile_service.dart  # User profiles
│   │
│   ├── views/                    # UI screens
│   │   ├── new_homepage.dart     # Main home screen
│   │   ├── login_page.dart       # Login screen
│   │   ├── dashboard_hub.dart    # Analytics hub
│   │   ├── profile_page.dart     # Profile screen
│   │   ├── groups/               # Group-related screens
│   │   └── placeholders/         # Future features
│   │
│   ├── widgets/                  # Reusable components
│   │   ├── expense_list_item.dart
│   │   ├── context_switcher.dart
│   │   ├── custom_split_editor.dart
│   │   └── ...
│   │
│   ├── routes/                   # Navigation
│   │   └── app_router.dart       # GoRouter config
│   │
│   ├── utils/                    # Utilities
│   │   └── category_helpers.dart
│   │
│   └── ui_elements/              # UI assets
│       └── solducci_logo.dart
│
├── supabase/                     # Backend
│   └── migrations/               # SQL migrations
│
├── android/                      # Android platform files
├── ios/                          # iOS platform files
├── web/                          # Web platform files
│
├── docs/                         # Documentation
│   ├── 01_PRODUCT_OVERVIEW.md
│   ├── 02_TECHNICAL_ARCHITECTURE.md
│   ├── 03_FEATURE_GUIDE.md
│   └── 04_DEVELOPER_ONBOARDING.md (you are here!)
│
├── pubspec.yaml                  # Dependencies
└── README.md                     # Project README
```

### Key Files Explained

#### [main.dart](../lib/main.dart) - App Entry Point
```dart
// Responsibilities:
// 1. Initialize Supabase client
// 2. Set up error handling
// 3. Listen to auth state changes
// 4. Configure app theme
// 5. Initialize routing
```

**What happens on startup:**
1. `main()` function runs
2. Supabase initialized with URL and key from .env
3. `MyApp` widget created
4. GoRouter configured
5. Auth state listener activated
6. User redirected based on auth status

#### [context_manager.dart](../lib/service/context_manager.dart) - Core State
```dart
// Singleton that manages:
// - Current context (Personal or Group)
// - User's groups list
// - Notifications when context changes

// Usage:
final contextManager = ContextManager();
contextManager.switchToPersonal();
contextManager.switchToGroup(group);
```

**Why it exists**:
- Single source of truth for app-wide context
- All widgets know which expenses to show
- Clean separation between personal and group data

#### [expense_service.dart](../lib/service/expense_service.dart) - Data Operations
```dart
// Handles all expense-related operations:
// - CRUD: create, read, update, delete
// - Stream expenses (context-aware)
// - Calculate balances
// - Manage splits

// Usage:
final expenseService = ExpenseService();
Stream<List<Expense>> expenses = expenseService.getExpensesStream();
await expenseService.addExpense(expense);
```

**Important**: All data access goes through services, never directly from widgets.

#### [app_router.dart](../lib/routes/app_router.dart) - Navigation
```dart
// GoRouter configuration:
// - Route definitions
// - Auth-based redirects
// - Bottom navigation shell
// - Deep linking support

// Navigation examples:
context.go('/dashboard/monthly');
context.push('/groups/$groupId');
```

### Architecture Overview

```
UI Layer (Views & Widgets)
        ↕
State Management (ContextManager + Streams)
        ↕
Business Logic (Services)
        ↕
Data Layer (Supabase Client)
        ↕
Backend (Supabase/PostgreSQL)
```

### Data Flow Example

**Scenario**: User creates a group expense

```
1. User fills ExpenseForm widget
2. User taps "Save"
3. Form validates data
4. Calls ExpenseService.addExpense(expense)
5. Service reads ContextManager.currentContext
6. Service adds groupId and split data
7. Service calls Supabase insert
8. PostgreSQL executes INSERT
9. Supabase Realtime broadcasts change
10. ExpenseService stream receives update
11. StreamBuilder in UI rebuilds
12. New expense appears in list
```

**Key insight**: Real-time updates happen automatically via streams.

---

## Development Workflow

### Branch Strategy

```
main (stable, production-ready)
  ↓
feature branches (feature/feature-name)
  ↓
Pull requests → Code review → Merge to main
```

### Creating a Feature Branch

```bash
# Make sure you're on latest main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/your-feature-name

# Example:
git checkout -b feature/add-receipt-photos
```

### Daily Development Flow

```bash
# 1. Start day: Pull latest changes
git checkout main
git pull origin main
git checkout feature/your-feature

# 2. Rebase on main (if needed)
git rebase main

# 3. Make changes
# ... edit files ...

# 4. Test changes
flutter run
# ... verify functionality ...

# 5. Commit changes
git add .
git commit -m "Add: Receipt photo upload feature"

# 6. Push to remote
git push origin feature/your-feature

# 7. Create pull request (on GitHub/GitLab)
```

### Commit Message Format

```
Type: Brief description

Detailed explanation (optional)

Examples:
- Add: Create receipt upload widget
- Fix: Resolve expense deletion bug
- Update: Improve balance calculation logic
- Refactor: Simplify context manager code
- Docs: Update API documentation
- Test: Add unit tests for expense service
```

---

## Common Tasks

### Task 1: Add a New Model

**Example**: Add a `Budget` model

```dart
// 1. Create file: lib/models/budget.dart
class Budget {
  final String id;
  final String userId;
  final String category;
  final double limit;
  final DateTime month;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.limit,
    required this.month,
  });

  // From JSON (database → app)
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['user_id'],
      category: json['category'],
      limit: json['limit'].toDouble(),
      month: DateTime.parse(json['month']),
    );
  }

  // To JSON (app → database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'limit': limit,
      'month': month.toIso8601String(),
    };
  }
}
```

### Task 2: Add a New Service

**Example**: Add a `BudgetService`

```dart
// 1. Create file: lib/service/budget_service.dart
class BudgetService {
  // Singleton pattern
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Get budgets stream
  Stream<List<Budget>> getBudgetsStream() {
    final userId = _authService.currentUserId;

    return _client
      .from('budgets')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId!)
      .order('month', ascending: false)
      .map((data) => data.map((json) => Budget.fromJson(json)).toList());
  }

  // Create budget
  Future<void> createBudget(Budget budget) async {
    await _client.from('budgets').insert(budget.toJson());
  }

  // Update budget
  Future<void> updateBudget(Budget budget) async {
    await _client
      .from('budgets')
      .update(budget.toJson())
      .eq('id', budget.id);
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    await _client.from('budgets').delete().eq('id', budgetId);
  }
}
```

### Task 3: Add a New Screen

**Example**: Add a `BudgetListPage`

```dart
// 1. Create file: lib/views/budget_list_page.dart
import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../service/budget_service.dart';

class BudgetListPage extends StatelessWidget {
  final BudgetService _budgetService = BudgetService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budgets'),
      ),
      body: StreamBuilder<List<Budget>>(
        stream: _budgetService.getBudgetsStream(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No budgets yet'));
          }

          // Data state
          final budgets = snapshot.data!;
          return ListView.builder(
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return ListTile(
                title: Text(budget.category),
                subtitle: Text('Limit: €${budget.limit}'),
                trailing: Text(budget.month.toString()),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create budget page
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### Task 4: Add a Route

```dart
// Edit: lib/routes/app_router.dart

// Add to routes list:
GoRoute(
  path: '/budgets',
  builder: (context, state) => BudgetListPage(),
),
```

### Task 5: Add Database Migration

```bash
# 1. Create migration file
touch supabase/migrations/010_add_budgets_table.sql

# 2. Write SQL
```

```sql
-- supabase/migrations/010_add_budgets_table.sql

-- Create budgets table
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  limit NUMERIC(10,2) NOT NULL,
  month TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(user_id, category, month)
);

-- Add RLS policies
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Users can view their own budgets
CREATE POLICY "Users can view own budgets"
  ON budgets FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can create their own budgets
CREATE POLICY "Users can create own budgets"
  ON budgets FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Users can update their own budgets
CREATE POLICY "Users can update own budgets"
  ON budgets FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Users can delete their own budgets
CREATE POLICY "Users can delete own budgets"
  ON budgets FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Create index
CREATE INDEX idx_budgets_user_id ON budgets(user_id);
CREATE INDEX idx_budgets_month ON budgets(month);
```

```bash
# 3. Run migration in Supabase SQL Editor
# Copy contents and execute
```

### Task 6: Run Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/budget_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Task 7: Debug the App

```bash
# Run in debug mode with verbose logging
flutter run --verbose

# Hot reload (press 'r' in terminal)
# Hot restart (press 'R' in terminal)

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Then click the link in terminal
```

---

## Debugging Tips

### Common Issues & Solutions

#### Issue 1: "Bad state: No element"
```
Error: Bad state: No element
```

**Cause**: Trying to access `.first` or `.single` on empty list/stream

**Solution**:
```dart
// Instead of:
final item = list.first;

// Use:
final item = list.isEmpty ? null : list.first;
// Or:
final item = list.firstOrNull; // Dart 3.0+
```

#### Issue 2: "RangeError: Index out of range"
```
RangeError (index): Invalid value: Not in inclusive range 0..2: 3
```

**Cause**: Accessing list index that doesn't exist

**Solution**:
```dart
// Check bounds:
if (index >= 0 && index < list.length) {
  final item = list[index];
}
```

#### Issue 3: Supabase "Row Level Security" Error
```
Error: new row violates row-level security policy
```

**Cause**: RLS policy blocking insert/update

**Solution**:
1. Check RLS policies in Supabase dashboard
2. Verify `user_id = auth.uid()` in policy
3. Ensure JWT token is valid
4. Check if user is authenticated

```dart
// Debug auth state:
print('Current user: ${Supabase.instance.client.auth.currentUser?.id}');
```

#### Issue 4: Stream Not Updating
```
UI not refreshing when data changes
```

**Cause**: Not using StreamBuilder or not listening to stream

**Solution**:
```dart
// Always use StreamBuilder for real-time data:
StreamBuilder<List<Expense>>(
  stream: expenseService.getExpensesStream(),
  builder: (context, snapshot) {
    // UI updates automatically when stream emits
  },
)
```

#### Issue 5: Context Manager Not Notifying
```
Context switched but UI not updating
```

**Cause**: Widget not listening to ChangeNotifier

**Solution**:
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ContextManager _contextManager = ContextManager();

  @override
  void initState() {
    super.initState();
    // Add listener
    _contextManager.addListener(_onContextChanged);
  }

  void _onContextChanged() {
    setState(() {}); // Rebuild when context changes
  }

  @override
  void dispose() {
    // Remove listener to prevent memory leaks
    _contextManager.removeListener(_onContextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Widget rebuilds on context change
  }
}
```

### Debugging Tools

#### 1. Flutter DevTools
```bash
# Open DevTools
flutter run
# Press 'p' to open DevTools in browser
```

**Features**:
- Widget Inspector (UI tree)
- Network tab (API calls)
- Performance profiler
- Memory profiler
- Logging

#### 2. Print Debugging
```dart
import 'package:flutter/foundation.dart';

// Debug logging (only in debug mode)
if (kDebugMode) {
  print('🔧 Value: $value');
  print('📊 List length: ${list.length}');
  print('✅ Operation successful');
  print('❌ Error: $error');
}
```

#### 3. Dart Observatory
```bash
# Run with observatory enabled
flutter run --observatory-port=8888

# Open in browser:
http://localhost:8888
```

#### 4. VS Code Debugging
```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart"
    }
  ]
}
```

**Usage**:
1. Set breakpoints (click left of line numbers)
2. Press F5 to start debugging
3. Step through code with F10 (step over) / F11 (step into)

---

## Code Style Guide

### Dart Naming Conventions

```dart
// Classes: PascalCase
class ExpenseService {}

// Functions & variables: camelCase
void calculateBalance() {}
final double totalAmount = 100.0;

// Private members: _camelCase
class MyClass {
  String _privateVariable;
  void _privateMethod() {}
}

// Constants: lowerCamelCase
const double maxAmount = 10000.0;

// Enums: PascalCase, values: camelCase
enum SplitType {
  equal,
  custom,
  lend,
  offer
}
```

### File Organization

```dart
// 1. Imports (sorted)
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense.dart';
import '../service/auth_service.dart';

// 2. Class definition
class MyWidget extends StatelessWidget {
  // 3. Constants
  static const double padding = 16.0;

  // 4. Final fields
  final String title;

  // 5. Constructor
  const MyWidget({Key? key, required this.title}) : super(key: key);

  // 6. Overrides
  @override
  Widget build(BuildContext context) {
    return Container();
  }

  // 7. Public methods
  void publicMethod() {}

  // 8. Private methods
  void _privateMethod() {}
}
```

### Widget Composition

```dart
// Extract complex widgets to methods or separate classes

// ❌ Bad: Everything in one build method
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // 100 lines of nested widgets...
      ],
    ),
  );
}

// ✅ Good: Extract to methods
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _buildHeader(),
        _buildContent(),
        _buildFooter(),
      ],
    ),
  );
}

Widget _buildHeader() {
  return Container(/* ... */);
}

// ✅ Better: Extract to separate widget
class HeaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(/* ... */);
  }
}
```

### Async/Await Best Practices

```dart
// ✅ Always use try-catch for async operations
Future<void> loadData() async {
  try {
    final data = await _service.fetchData();
    setState(() {
      _data = data;
    });
  } catch (e) {
    print('❌ Error loading data: $e');
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load data')),
    );
  }
}

// ✅ Use async/await instead of .then()
// Good:
final result = await someAsyncOperation();
processResult(result);

// Avoid:
someAsyncOperation().then((result) {
  processResult(result);
});
```

### State Management Guidelines

```dart
// ✅ Use StatelessWidget when possible
class DisplayWidget extends StatelessWidget {
  final String text;
  const DisplayWidget({required this.text});

  @override
  Widget build(BuildContext context) => Text(text);
}

// ✅ Use StatefulWidget only when needed
class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('$_counter');
  }
}
```

### Comments & Documentation

```dart
/// Service for managing expenses
///
/// Handles CRUD operations for expenses and provides
/// real-time streams of expense data.
class ExpenseService {
  /// Creates a new expense in the database
  ///
  /// Returns the created expense ID.
  /// Throws [SupabaseException] if creation fails.
  Future<int> createExpense(Expense expense) async {
    // Implementation
  }

  // Private helper method
  // No need for doc comments on private methods
  void _calculateSplits() {
    // ...
  }
}
```

---

## Making Your First Contribution

### Step-by-Step Guide

#### 1. Find an Issue
```bash
# Look for issues labeled:
- "good first issue"
- "beginner friendly"
- "documentation"
```

#### 2. Claim the Issue
```
Comment: "I'd like to work on this!"
Wait for assignment from maintainer
```

#### 3. Create Feature Branch
```bash
git checkout main
git pull origin main
git checkout -b feature/issue-123-add-feature
```

#### 4. Make Changes
```bash
# Edit files
# Test thoroughly
flutter run
# Verify functionality
```

#### 5. Write Tests (if applicable)
```dart
// test/services/expense_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/service/expense_service.dart';

void main() {
  group('ExpenseService', () {
    test('calculates balance correctly', () {
      // Test implementation
    });
  });
}
```

#### 6. Commit Changes
```bash
git add .
git commit -m "Add: Implement feature X for issue #123"
```

#### 7. Push and Create PR
```bash
git push origin feature/issue-123-add-feature

# Then on GitHub/GitLab:
# 1. Click "Create Pull Request"
# 2. Fill in description:
```

**PR Template**:
```markdown
## Description
Brief description of changes

## Related Issue
Closes #123

## Changes Made
- Added feature X
- Updated Y
- Fixed Z

## Testing
- [ ] Tested on iOS
- [ ] Tested on Android
- [ ] Tested on Web
- [ ] Added unit tests
- [ ] Verified no regressions

## Screenshots (if applicable)
[Add screenshots here]

## Checklist
- [ ] Code follows style guide
- [ ] Documentation updated
- [ ] Tests passing
- [ ] No console errors
```

#### 8. Address Review Feedback
```bash
# Make requested changes
git add .
git commit -m "Fix: Address PR review feedback"
git push origin feature/issue-123-add-feature
```

#### 9. Merge!
```
Once approved, maintainer will merge
Congratulations! 🎉
```

---

## Learning Resources

### Flutter Documentation
- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)

### Supabase Documentation
- [Supabase Docs](https://supabase.com/docs)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart)
- [RLS Policies](https://supabase.com/docs/guides/auth/row-level-security)

### Project-Specific Docs
- [Product Overview](./01_PRODUCT_OVERVIEW.md)
- [Technical Architecture](./02_TECHNICAL_ARCHITECTURE.md)
- [Feature Guide](./03_FEATURE_GUIDE.md)
- [API Documentation](./05_API_DATA_FLOW.md)

### Video Tutorials
- [Flutter Widget of the Week](https://www.youtube.com/playlist?list=PLjxrf2q8roU23XGwz3Km7sQZFTdB996iG)
- [Supabase Tutorial Series](https://www.youtube.com/c/Supabase)

---

## Getting Help

### Team Communication
- **Daily standups**: [Time/Platform]
- **Code reviews**: Create PR and request review
- **Questions**: Ask in team chat or create discussion

### Debugging Help
1. **Check error message** carefully
2. **Search existing issues** on GitHub
3. **Flutter DevTools** for runtime inspection
4. **Ask teammate** with context and error details
5. **Stack Overflow** for general Flutter questions

### When Stuck
```
1. Read error message
2. Check relevant documentation
3. Use debugger / print statements
4. Search for similar issues
5. Ask for help with:
   - What you're trying to do
   - What you expected
   - What actually happened
   - Steps to reproduce
   - Error messages / logs
```

---

## Next Steps

Now that you're onboarded:

1. ✅ **Explore the codebase**
   - Read through key files
   - Understand data flow
   - Trace a feature end-to-end

2. ✅ **Make a small change**
   - Fix a typo in UI
   - Add a debug log
   - Update documentation

3. ✅ **Pick your first issue**
   - Start with "good first issue"
   - Ask questions if unclear
   - Submit your first PR

4. ✅ **Learn the domain**
   - Read product documentation
   - Use the app as a user
   - Understand user workflows

5. ✅ **Contribute regularly**
   - Take on larger features
   - Help review PRs
   - Mentor new developers

---

**Welcome to the team!** 🎉

If you have any questions or need help, don't hesitate to ask. We're here to support you.

---

*For more information, see:*
- [Technical Architecture](./02_TECHNICAL_ARCHITECTURE.md)
- [Feature Guide](./03_FEATURE_GUIDE.md)
- [API Documentation](./05_API_DATA_FLOW.md)
