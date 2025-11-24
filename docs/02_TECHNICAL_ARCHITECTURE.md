# Solducci - Technical Architecture

> **Audience**: Software engineers, technical leads, architects
> **Level**: Deep technical, implementation-focused

---

## Table of Contents
1. [Technology Stack](#technology-stack)
2. [System Architecture](#system-architecture)
3. [Data Models](#data-models)
4. [State Management](#state-management)
5. [Database Schema](#database-schema)
6. [Authentication & Authorization](#authentication--authorization)
7. [Navigation System](#navigation-system)
8. [Real-time Synchronization](#real-time-synchronization)
9. [Multi-User Context System](#multi-user-context-system)
10. [Security & Privacy](#security--privacy)

---

## Technology Stack

### Core Framework
```yaml
Framework: Flutter 3.x
Language: Dart ^3.8.1
Target SDK: iOS, Android, Web, macOS, Windows, Linux
```

### Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `supabase_flutter` | ^2.10.0 | Backend services, auth, real-time DB |
| `go_router` | ^14.6.2 | Declarative navigation & routing |
| `http` | ^1.4.0 | HTTP client |
| `intl` | ^0.20.0 | Internationalization & formatting |
| `currency_text_input_formatter` | ^2.2.9 | Currency input handling |
| `flutter_dotenv` | ^5.2.1 | Environment variable management |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

### Backend Stack
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth (email/password)
- **Real-time**: Supabase Realtime (WebSocket-based)
- **Storage**: Supabase Storage (for future avatar/receipt features)
- **Hosting**: Supabase Cloud

---

## System Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    UI Layer (Views)                    │  │
│  │  • NewHomepage  • DashboardHub  • ProfilePage        │  │
│  │  • ExpenseList  • GroupPages    • Analytics Views     │  │
│  └───────────────────────────────────────────────────────┘  │
│                            ↕                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                 State Management                       │  │
│  │  • ContextManager (ChangeNotifier)                    │  │
│  │  • Stream Controllers                                  │  │
│  └───────────────────────────────────────────────────────┘  │
│                            ↕                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Business Logic (Services)                 │  │
│  │  • ExpenseService  • GroupService                     │  │
│  │  • AuthService     • ProfileService                   │  │
│  └───────────────────────────────────────────────────────┘  │
│                            ↕                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   Data Layer                           │  │
│  │  • Supabase Client (Singleton)                        │  │
│  │  • Real-time Subscriptions                            │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↕ (WebSocket + REST)
┌─────────────────────────────────────────────────────────────┐
│                      Supabase Backend                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  PostgreSQL Database + Row-Level Security (RLS)       │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Supabase Auth (JWT-based authentication)             │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Realtime Server (WebSocket for live updates)         │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Architecture Patterns

#### 1. **Service Layer Pattern**
All business logic is encapsulated in singleton services:
- `AuthService`: Authentication operations
- `ExpenseService`: Expense CRUD & calculations
- `GroupService`: Group & member management
- `ProfileService`: User profile operations

**Benefits**:
- Clear separation of concerns
- Testable business logic
- Centralized data access
- Single source of truth for operations

#### 2. **Repository Pattern** (via Supabase)
Services interact with Supabase client, which acts as a repository:
```dart
// Example: ExpenseService using Supabase client
final expenses = await Supabase.instance.client
  .from('expenses')
  .select()
  .eq('user_id', userId)
  .order('date', ascending: false);
```

#### 3. **Observer Pattern** (for State)
- `ChangeNotifier` for `ContextManager`
- `Stream<T>` for real-time data updates
- Widgets rebuild automatically on data changes

#### 4. **Singleton Pattern**
All services are singletons to ensure single source of truth:
```dart
class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();
}
```

---

## Data Models

### Core Models

#### 1. Expense Model
```dart
class Expense {
  final int id;
  final String description;
  final double amount;
  final DateTime date;
  final Tipologia type;  // Enum: affitto, cibo, utenze, etc.
  final MoneyFlow moneyFlow;  // Legacy: carlPaid, pitPaid

  // Multi-user fields
  final String? userId;      // Personal expense owner
  final String? groupId;     // Group expense identifier
  final String? paidBy;      // UUID of payer (group member)
  final SplitType? splitType;  // equal, custom, lend, offer
  final Map<String, double>? splitData;  // Custom split amounts

  // Computed properties
  bool get isPersonalExpense => groupId == null;
  bool get isGroupExpense => groupId != null;
}
```

#### 2. SplitType Enum
```dart
enum SplitType {
  equal,   // "Equamente tra tutti" - divided equally
  lend,    // "Presta" - payer advances, others owe
  offer,   // "Offri" - payer gifts, no reimbursement
  custom;  // "Importi custom" - custom amounts per person
}
```

#### 3. Group Models
```dart
class ExpenseGroup {
  final String id;        // UUID
  final String name;
  final String? description;
  final String createdBy; // UUID of creator
  final DateTime createdAt;
  final List<GroupMember> members;

  int get memberCount => members.length;
}

class GroupMember {
  final String id;         // UUID
  final String groupId;
  final String userId;
  final GroupRole role;    // admin or member
  final DateTime joinedAt;
  final String? nickname;
  final String? email;
  final String? avatarUrl;
}

enum GroupRole {
  admin,   // Can manage group, add/remove members
  member;  // Can view and add expenses
}
```

#### 4. Group Invitation Model
```dart
class GroupInvite {
  final String id;             // UUID
  final String groupId;
  final String invitedEmail;
  final String invitedBy;      // UUID
  final String status;         // pending, accepted, rejected, expired
  final DateTime expiresAt;
  final DateTime createdAt;
}
```

#### 5. Analytics Models
```dart
class MonthlyGroup {
  final String monthLabel;     // "Gennaio 2025"
  final DateTime month;
  final List<Expense> expenses;
  final double total;
}

class CategoryBreakdown {
  final Tipologia category;
  final double total;
  final int count;
  final double percentage;
}

class DebtBalance {
  final double carlOwes;       // Legacy naming
  final double pitOwes;
  final double netBalance;
  final String balanceLabel;
}
```

---

## State Management

### Context Management Architecture

The app uses a **hybrid state management approach**:
1. **ContextManager** (ChangeNotifier) for global context state
2. **Stream-based** for real-time data updates
3. **Local state** (StatefulWidget) for UI-specific state

### ContextManager (Core State)

```dart
class ContextManager with ChangeNotifier {
  // Singleton instance
  static final ContextManager _instance = ContextManager._internal();
  factory ContextManager() => _instance;

  // Current context state
  ExpenseContext _currentContext = ExpenseContext.personal();
  List<ExpenseGroup> _userGroups = [];

  // Getters
  ExpenseContext get currentContext => _currentContext;
  List<ExpenseGroup> get userGroups => _userGroups;
  bool get isPersonalContext => _currentContext.isPersonal;
  bool get isGroupContext => _currentContext.isGroup;

  // Methods
  void switchToPersonal() {
    _currentContext = ExpenseContext.personal();
    notifyListeners();  // Trigger UI rebuild
  }

  void switchToGroup(ExpenseGroup group) {
    _currentContext = ExpenseContext.group(group);
    notifyListeners();
  }

  Future<void> loadUserGroups() async {
    _userGroups = await GroupService().getUserGroups();
    notifyListeners();
  }
}
```

### ExpenseContext Model
```dart
class ExpenseContext {
  final bool isPersonal;
  final ExpenseGroup? group;

  ExpenseContext.personal() : isPersonal = true, group = null;
  ExpenseContext.group(this.group) : isPersonal = false;

  bool get isGroup => !isPersonal;
  String? get groupId => group?.id;
}
```

### State Flow Diagram

```
User Action (Switch Context)
        ↓
ContextManager.switchToGroup(group)
        ↓
_currentContext updated
        ↓
notifyListeners() called
        ↓
All listening widgets rebuild
        ↓
ExpenseService detects context change
        ↓
New Stream<Expense> filtered by context
        ↓
UI displays context-appropriate data
```

---

## Database Schema

### Tables Overview

```sql
-- User profiles
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT,
  nickname TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Expense groups
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Group memberships
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(group_id, user_id)
);

-- Group invitations
CREATE TABLE group_invites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  invited_email TEXT NOT NULL,
  invited_by UUID REFERENCES profiles(id),
  status TEXT CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Expenses (modified for multi-user)
CREATE TABLE expenses (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),    -- Personal expense owner
  group_id UUID REFERENCES groups(id),     -- Group expense
  description TEXT NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  type TEXT NOT NULL,  -- affitto, cibo, utenze, etc.

  -- Group expense fields
  paid_by UUID REFERENCES profiles(id),    -- Who paid
  split_type TEXT,  -- equal, custom, lend, offer
  split_data JSONB, -- Custom split amounts

  -- Legacy field
  money_flow TEXT,  -- carlPaid, pitPaid

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  -- Constraint: Either user_id OR group_id must be set
  CHECK (
    (user_id IS NOT NULL AND group_id IS NULL) OR
    (user_id IS NULL AND group_id IS NOT NULL)
  )
);

-- Expense splits (detailed tracking)
CREATE TABLE expense_splits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  expense_id INTEGER REFERENCES expenses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  amount NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

### Key Indexes

```sql
CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_group_id ON expenses(group_id);
CREATE INDEX idx_expenses_date ON expenses(date DESC);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);
CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_expense_splits_expense_id ON expense_splits(expense_id);
```

### Database Triggers

#### Auto-create Profile on Signup
```sql
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Function to create profile
CREATE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nickname)
  VALUES (new.id, new.email, SPLIT_PART(new.email, '@', 1));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Authentication & Authorization

### Authentication Flow

```
1. User enters email/password
        ↓
2. AuthService.login() called
        ↓
3. Supabase.auth.signInWithPassword()
        ↓
4. JWT token stored in secure storage
        ↓
5. Auth state listener triggered
        ↓
6. GoRouter redirects to /home
        ↓
7. ContextManager initialized
        ↓
8. User groups loaded
```

### AuthService Implementation

```dart
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => currentUser?.id;

  // Login
  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Signup
  Future<AuthResponse> signup(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Logout
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
```

### Row-Level Security (RLS) Policies

#### Profiles Table
```sql
-- Users can view all profiles (for invitations)
CREATE POLICY "Profiles are viewable by authenticated users"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);
```

#### Expenses Table
```sql
-- Users can view their personal expenses
CREATE POLICY "Users can view own personal expenses"
  ON expenses FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can view expenses from their groups
CREATE POLICY "Users can view group expenses"
  ON expenses FOR SELECT
  TO authenticated
  USING (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
    )
  );

-- Users can insert personal expenses
CREATE POLICY "Users can insert personal expenses"
  ON expenses FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid() AND group_id IS NULL);

-- Users can insert group expenses
CREATE POLICY "Users can insert group expenses"
  ON expenses FOR INSERT
  TO authenticated
  WITH CHECK (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
    )
  );
```

#### Groups Table
```sql
-- Users can view groups they're members of
CREATE POLICY "Users can view own groups"
  ON groups FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
    )
  );

-- Any authenticated user can create groups
CREATE POLICY "Authenticated users can create groups"
  ON groups FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());
```

---

## Navigation System

### GoRouter Configuration

```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final isAuthPage = state.matchedLocation == '/login' ||
                      state.matchedLocation == '/signup';

    // Redirect logic
    if (!isLoggedIn && !isAuthPage) return '/login';
    if (isLoggedIn && isAuthPage) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => SignupPage(),
    ),

    // Main app with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellWithNav(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => NewHomepage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              builder: (context, state) => ExpenseList(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => DashboardHub(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => ProfilePage(),
            ),
          ],
        ),
      ],
    ),

    // Full-screen analytics pages
    GoRoute(
      path: '/dashboard/monthly',
      builder: (context, state) => MonthlyView(),
    ),
    GoRoute(
      path: '/dashboard/category',
      builder: (context, state) => CategoryView(),
    ),
    GoRoute(
      path: '/dashboard/balance',
      builder: (context, state) => BalanceView(),
    ),
    GoRoute(
      path: '/dashboard/timeline',
      builder: (context, state) => TimelineView(),
    ),

    // Group management
    GoRoute(
      path: '/groups/create',
      builder: (context, state) => CreateGroupPage(),
    ),
    GoRoute(
      path: '/groups/:id',
      builder: (context, state) {
        final groupId = state.pathParameters['id']!;
        return GroupDetailPage(groupId: groupId);
      },
    ),
    GoRoute(
      path: '/groups/:id/invite',
      builder: (context, state) {
        final groupId = state.pathParameters['id']!;
        return InviteMemberPage(groupId: groupId);
      },
    ),
    GoRoute(
      path: '/invites/pending',
      builder: (context, state) => PendingInvitesPage(),
    ),
  ],
);
```

---

## Real-time Synchronization

### Stream-Based Architecture

All data in Solducci is fetched via **Supabase real-time streams**, ensuring instant synchronization across all devices.

#### ExpenseService Stream Implementation

```dart
class ExpenseService {
  final SupabaseClient _client = Supabase.instance.client;
  final ContextManager _contextManager = ContextManager();

  // Main expense stream (context-aware)
  Stream<List<Expense>> getExpensesStream() {
    final context = _contextManager.currentContext;

    if (context.isPersonal) {
      // Personal context: user's personal expenses only
      return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', AuthService().currentUserId!)
        .order('date', ascending: false)
        .map((data) => data.map((json) => Expense.fromJson(json)).toList());
    } else {
      // Group context: expenses from selected group only
      return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', context.groupId!)
        .order('date', ascending: false)
        .map((data) => data.map((json) => Expense.fromJson(json)).toList());
    }
  }
}
```

### Real-time Update Flow

```
Device A: User adds expense
        ↓
POST /rest/v1/expenses (Supabase REST API)
        ↓
PostgreSQL INSERT executed
        ↓
Supabase Realtime detects change
        ↓
WebSocket broadcast to all connected clients
        ↓
Device B: Stream receives update
        ↓
Stream listener rebuilds UI
        ↓
New expense appears instantly
```

### Benefits
- ✅ **Zero manual refresh** needed
- ✅ **Instant synchronization** across devices
- ✅ **Automatic conflict resolution** via database
- ✅ **Offline support** (via Supabase client caching)

---

## Multi-User Context System

### Architecture Overview

The **Context System** is the core innovation that allows seamless switching between personal and group expense views.

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    ContextManager                        │
│  • Holds current context (Personal or Group)            │
│  • Notifies all listeners on context change             │
│  • Single source of truth for app-wide context          │
└─────────────────────────────────────────────────────────┘
                        ↓ (notifies)
┌─────────────────────────────────────────────────────────┐
│                    ExpenseService                        │
│  • Reads ContextManager.currentContext                  │
│  • Returns filtered stream based on context             │
│  • Personal: WHERE user_id = X AND group_id IS NULL    │
│  • Group: WHERE group_id = Y                            │
└─────────────────────────────────────────────────────────┘
                        ↓ (provides data)
┌─────────────────────────────────────────────────────────┐
│                      UI Widgets                          │
│  • NewHomepage, ExpenseList, Dashboard, etc.            │
│  • Listen to expense stream                             │
│  • Rebuild automatically on context/data changes        │
└─────────────────────────────────────────────────────────┘
```

### Context Switching Flow

1. **User taps context switcher** in AppBar
2. **Modal bottom sheet opens** showing:
   - Personal option
   - List of user's groups
   - "Create New Group" button
3. **User selects a group**
4. **ContextManager.switchToGroup(group)** called
5. **notifyListeners()** triggers rebuild of:
   - AppBar (updates title)
   - Expense stream (filters by new context)
   - Dashboard (shows group-specific analytics)
6. **UI updates instantly** with group data

### Code Example: Context-Aware Widget

```dart
class NewHomepage extends StatefulWidget {
  @override
  State<NewHomepage> createState() => _NewHomepageState();
}

class _NewHomepageState extends State<NewHomepage> {
  final ContextManager _contextManager = ContextManager();
  final ExpenseService _expenseService = ExpenseService();

  @override
  void initState() {
    super.initState();
    // Listen to context changes
    _contextManager.addListener(_onContextChanged);
  }

  void _onContextChanged() {
    setState(() {}); // Rebuild when context changes
  }

  @override
  Widget build(BuildContext context) {
    final currentContext = _contextManager.currentContext;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentContext.isPersonal
            ? 'Personal Expenses'
            : currentContext.group!.name,
        ),
        actions: [
          // Context switcher button
          ContextSwitcher(),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.getExpensesStream(), // Context-aware
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final expenses = snapshot.data!;
          return ExpenseListView(expenses: expenses);
        },
      ),
    );
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    super.dispose();
  }
}
```

---

## Security & Privacy

### Security Measures

1. **Authentication**
   - JWT-based tokens (issued by Supabase Auth)
   - Secure password hashing (bcrypt via Supabase)
   - No plaintext passwords stored

2. **Authorization**
   - Row-Level Security (RLS) enforced at database level
   - No client-side authorization bypasses possible
   - All queries filtered by RLS policies

3. **Data Privacy**
   - Users only see their own personal expenses
   - Users only see groups they're members of
   - Group expenses visible only to group members
   - No cross-contamination between users/groups

4. **API Security**
   - Supabase anonymous key (rate-limited, public)
   - RLS policies enforce data access rules
   - No sensitive operations via anonymous key
   - Service role key never exposed to client

5. **Environment Security**
   - `.env` files excluded from version control
   - `--dart-define` for production builds
   - No hardcoded credentials in code

### Privacy Guarantees

| Data Type | Visibility | Access Control |
|-----------|-----------|----------------|
| Personal expenses | Only owner | RLS: `user_id = auth.uid()` |
| Group expenses | All group members | RLS: `group_id IN (user's groups)` |
| User profiles | All authenticated users | RLS: `authenticated` (for invitations) |
| Group memberships | Only members of that group | RLS: `user_id = auth.uid()` |
| Split balances | Only group members | Computed from visible expenses |

---

## Performance Considerations

### Database Optimization
- ✅ Indexes on frequently queried columns (user_id, group_id, date)
- ✅ Efficient RLS policies (no recursive queries)
- ✅ Pagination support (limit/offset)
- ✅ Connection pooling (via Supabase)

### Client-Side Optimization
- ✅ Stream-based updates (no polling)
- ✅ Lazy loading of analytics data
- ✅ Efficient Flutter widget rebuilds
- ✅ Image caching (for future avatar feature)

### Real-time Optimization
- ✅ WebSocket connection reuse
- ✅ Selective subscription (only active tables)
- ✅ Debounced UI updates

---

## Deployment Architecture

### Development Environment
```
Developer Machine
      ↓
Flutter App (Debug Mode)
      ↓
Supabase Project (Development)
      ↓
PostgreSQL Database (Supabase Cloud)
```

### Production Environment
```
User Device (iOS/Android/Web)
      ↓
Flutter App (Release Mode)
      ↓
Supabase Project (Production)
      ↓
PostgreSQL Database (Supabase Cloud)
      ↓
CDN (for static assets)
```

### CI/CD Pipeline (Future)
```
Git Push
  → GitHub Actions
  → Run Tests
  → Build App
  → Deploy to App Stores
  → Run Database Migrations
  → Deploy Web Version
```

---

## Testing Strategy (Future Implementation)

### Unit Tests
- Model serialization/deserialization
- Business logic in services
- Utility functions
- Balance calculations

### Integration Tests
- Supabase client interactions
- RLS policy validation
- Authentication flows
- Real-time stream behavior

### Widget Tests
- UI component rendering
- User interaction handling
- Navigation flows
- Form validation

### End-to-End Tests
- Complete user workflows
- Multi-user scenarios
- Real-time synchronization
- Cross-platform compatibility

---

## Code Quality & Standards

### Linting Configuration
```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - unnecessary_null_comparison
```

### Logging Standards
```dart
// Debug logging with emojis
if (kDebugMode) {
  print('🔧 Initializing Supabase...');
  print('✅ Login successful');
  print('⚠️ Legacy format detected');
  print('❌ Failed to load expenses');
  print('📊 Loaded ${expenses.length} expenses');
}
```

### Documentation Standards
- All public APIs documented with dartdoc comments
- Complex algorithms explained with inline comments
- README files in major directories
- Comprehensive `/docs` folder

---

## Future Technical Enhancements

### Short-term (Phase 3B-3D)
- [ ] Enhanced context switcher UI
- [ ] Improved error handling
- [ ] Loading state optimization
- [ ] Form validation improvements

### Medium-term
- [ ] Offline-first architecture (local SQLite cache)
- [ ] Push notifications for new expenses
- [ ] Receipt photo uploads (Supabase Storage)
- [ ] Export to CSV/PDF

### Long-term
- [ ] Multi-currency support
- [ ] Advanced analytics (charts, trends)
- [ ] Recurring expenses automation
- [ ] Budget tracking & alerts
- [ ] AI-powered expense categorization

---

## Troubleshooting & Debugging

### Common Issues

**Issue**: Expenses not appearing after context switch
- **Cause**: Stream not rebuilding
- **Solution**: Ensure widget is listening to `ContextManager` and rebuilding on change

**Issue**: RLS policy blocking legitimate access
- **Cause**: Incorrect policy logic
- **Solution**: Check policies with Supabase dashboard, verify JWT token

**Issue**: Real-time updates not working
- **Cause**: WebSocket connection failed
- **Solution**: Check network, verify Supabase project status, check `.stream()` configuration

### Debug Tools
- Flutter DevTools (Inspector, Network, Performance)
- Supabase Dashboard (Database, Auth, Logs)
- PostgreSQL logs (via Supabase)
- Browser DevTools (for Web platform)

---

## Conclusion

Solducci's architecture is designed for:
- ✅ **Scalability**: Multi-user, multi-group support
- ✅ **Real-time**: Instant synchronization across devices
- ✅ **Security**: RLS policies enforce data privacy
- ✅ **Maintainability**: Clear separation of concerns
- ✅ **Testability**: Service-based architecture
- ✅ **Extensibility**: Easy to add new features

The context-based architecture is the key innovation, allowing seamless switching between personal and group expense views while maintaining data privacy and performance.

---

*For implementation details, see:*
- [Developer Onboarding Guide](./04_DEVELOPER_ONBOARDING.md)
- [API Documentation](./05_API_DATA_FLOW.md)
- [Feature Guide](./03_FEATURE_GUIDE.md)
