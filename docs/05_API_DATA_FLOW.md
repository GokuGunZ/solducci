# Solducci - API & Data Flow Documentation

> **Audience**: Backend developers, API consumers, integration developers
> **Level**: Technical, API-focused

---

## Table of Contents
1. [API Overview](#api-overview)
2. [Authentication Flow](#authentication-flow)
3. [Data Flow Patterns](#data-flow-patterns)
4. [Service APIs](#service-apis)
5. [Database Operations](#database-operations)
6. [Real-time Subscriptions](#real-time-subscriptions)
7. [Error Handling](#error-handling)
8. [Performance Considerations](#performance-considerations)

---

## API Overview

### Backend Architecture

Solducci uses **Supabase** as its backend-as-a-service (BaaS), which provides:
- **PostgreSQL database** with Row-Level Security (RLS)
- **RESTful API** auto-generated from database schema
- **Real-time WebSocket** subscriptions
- **Authentication** (JWT-based)

### API Base URLs

```
Development: https://your-project.supabase.co
Production:  https://your-production-project.supabase.co
```

### Authentication

All API requests require authentication via JWT token in the `Authorization` header:

```
Authorization: Bearer <jwt_token>
```

The JWT token is obtained after successful login and is automatically included by the Supabase client.

### Response Formats

**Success Response**:
```json
{
  "data": [...],
  "status": 200
}
```

**Error Response**:
```json
{
  "message": "Error description",
  "code": "ERROR_CODE",
  "status": 400
}
```

---

## Authentication Flow

### 1. User Signup

**Endpoint**: `POST /auth/v1/signup`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response**:
```json
{
  "user": {
    "id": "uuid-here",
    "email": "user@example.com",
    "created_at": "2024-11-15T10:00:00Z"
  },
  "session": {
    "access_token": "jwt-token-here",
    "refresh_token": "refresh-token-here",
    "expires_in": 3600
  }
}
```

**Flutter Implementation**:
```dart
final response = await Supabase.instance.client.auth.signUp(
  email: email,
  password: password,
);

if (response.user != null) {
  // Signup successful
  // Profile auto-created via database trigger
}
```

**Database Side-Effects**:
1. User created in `auth.users` table
2. Trigger fires: `on_auth_user_created`
3. Profile record auto-created in `public.profiles`

---

### 2. User Login

**Endpoint**: `POST /auth/v1/token?grant_type=password`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response**:
```json
{
  "access_token": "jwt-token-here",
  "refresh_token": "refresh-token-here",
  "expires_in": 3600,
  "user": {
    "id": "uuid-here",
    "email": "user@example.com"
  }
}
```

**Flutter Implementation**:
```dart
final response = await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);

if (response.session != null) {
  // Login successful
  // JWT token stored automatically
}
```

---

### 3. Token Refresh

**Endpoint**: `POST /auth/v1/token?grant_type=refresh_token`

**Request**:
```json
{
  "refresh_token": "refresh-token-here"
}
```

**Response**:
```json
{
  "access_token": "new-jwt-token-here",
  "refresh_token": "new-refresh-token-here",
  "expires_in": 3600
}
```

**Flutter Implementation**:
```dart
// Automatic refresh handled by Supabase client
// Manual refresh (if needed):
await Supabase.instance.client.auth.refreshSession();
```

---

### 4. Logout

**Endpoint**: `POST /auth/v1/logout`

**Request**: No body, just Authorization header

**Response**:
```json
{}
```

**Flutter Implementation**:
```dart
await Supabase.instance.client.auth.signOut();
// Clears JWT token and session
```

---

## Data Flow Patterns

### Pattern 1: Create Operation

**Example**: Create a personal expense

```
┌─────────────┐
│  UI Widget  │
└──────┬──────┘
       │ 1. User fills form
       ↓
┌─────────────────┐
│ ExpenseService  │
└──────┬──────────┘
       │ 2. addExpense(expense)
       ↓
┌─────────────────┐
│ Supabase Client │
└──────┬──────────┘
       │ 3. POST /rest/v1/expenses
       ↓
┌─────────────────┐
│   PostgreSQL    │
└──────┬──────────┘
       │ 4. INSERT INTO expenses
       │ 5. RLS policy check
       │ 6. Row inserted
       ↓
┌─────────────────┐
│ Realtime Server │
└──────┬──────────┘
       │ 7. Broadcast change
       ↓
┌─────────────────┐
│ All Subscribers │ (including original client)
└──────┬──────────┘
       │ 8. Stream emits new data
       ↓
┌─────────────┐
│ UI Updates  │
└─────────────┘
```

**Request Details**:
```http
POST /rest/v1/expenses
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "user_id": "uuid-of-user",
  "description": "Groceries",
  "amount": 85.50,
  "date": "2024-11-15T10:00:00Z",
  "type": "cibo",
  "money_flow": "carlPaid"
}
```

**Response**:
```json
{
  "id": 123,
  "user_id": "uuid-of-user",
  "description": "Groceries",
  "amount": 85.50,
  "date": "2024-11-15T10:00:00Z",
  "type": "cibo",
  "money_flow": "carlPaid",
  "created_at": "2024-11-15T10:00:01Z"
}
```

---

### Pattern 2: Read Operation (Stream)

**Example**: Subscribe to expense stream

```
┌─────────────┐
│  UI Widget  │
└──────┬──────┘
       │ 1. StreamBuilder created
       ↓
┌─────────────────┐
│ ExpenseService  │
└──────┬──────────┘
       │ 2. getExpensesStream()
       ↓
┌─────────────────┐
│ Supabase Client │
└──────┬──────────┘
       │ 3. Subscribe to 'expenses' table
       │ 4. WebSocket connection established
       ↓
┌─────────────────┐
│ Realtime Server │
└──────┬──────────┘
       │ 5. Send initial data
       │ 6. Listen for changes
       ↓
┌─────────────┐
│  UI Widget  │ (receives updates automatically)
└─────────────┘
```

**WebSocket Message (Initial Data)**:
```json
{
  "event": "SELECT",
  "payload": {
    "data": [
      {
        "id": 123,
        "description": "Groceries",
        "amount": 85.50,
        ...
      },
      ...
    ]
  }
}
```

**WebSocket Message (Insert Event)**:
```json
{
  "event": "INSERT",
  "payload": {
    "data": {
      "id": 124,
      "description": "Coffee",
      "amount": 3.50,
      ...
    }
  }
}
```

---

### Pattern 3: Update Operation

**Example**: Edit an expense

```
┌─────────────┐
│  UI Widget  │
└──────┬──────┘
       │ 1. User edits expense
       ↓
┌─────────────────┐
│ ExpenseService  │
└──────┬──────────┘
       │ 2. updateExpense(expense)
       ↓
┌─────────────────┐
│ Supabase Client │
└──────┬──────────┘
       │ 3. PATCH /rest/v1/expenses?id=eq.123
       ↓
┌─────────────────┐
│   PostgreSQL    │
└──────┬──────────┘
       │ 4. UPDATE expenses SET ... WHERE id = 123
       │ 5. RLS policy check (user_id = auth.uid())
       │ 6. Row updated
       ↓
┌─────────────────┐
│ Realtime Server │
└──────┬──────────┘
       │ 7. Broadcast UPDATE event
       ↓
┌─────────────────┐
│ All Subscribers │
└──────┬──────────┘
       │ 8. Stream emits updated data
       ↓
┌─────────────┐
│ UI Updates  │
└─────────────┘
```

**Request Details**:
```http
PATCH /rest/v1/expenses?id=eq.123
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "description": "Groceries (updated)",
  "amount": 90.00
}
```

**Response**:
```json
{
  "id": 123,
  "description": "Groceries (updated)",
  "amount": 90.00,
  ...
}
```

---

### Pattern 4: Delete Operation

**Example**: Delete an expense

```
┌─────────────┐
│  UI Widget  │
└──────┬──────┘
       │ 1. User swipes to delete
       ↓
┌─────────────────┐
│ ExpenseService  │
└──────┬──────────┘
       │ 2. deleteExpense(expenseId)
       ↓
┌─────────────────┐
│ Supabase Client │
└──────┬──────────┘
       │ 3. DELETE /rest/v1/expenses?id=eq.123
       ↓
┌─────────────────┐
│   PostgreSQL    │
└──────┬──────────┘
       │ 4. DELETE FROM expenses WHERE id = 123
       │ 5. RLS policy check
       │ 6. Row deleted (CASCADE to expense_splits)
       ↓
┌─────────────────┐
│ Realtime Server │
└──────┬──────────┘
       │ 7. Broadcast DELETE event
       ↓
┌─────────────────┐
│ All Subscribers │
└──────┬──────────┘
       │ 8. Stream emits updated list (without deleted item)
       ↓
┌─────────────┐
│ UI Updates  │
└─────────────┘
```

**Request Details**:
```http
DELETE /rest/v1/expenses?id=eq.123
Authorization: Bearer <jwt_token>
```

**Response**:
```json
{}
```

---

## Service APIs

### AuthService API

#### getCurrentUser()
```dart
User? getCurrentUser()
```

**Returns**: Current authenticated user or `null`

**Example**:
```dart
final user = AuthService().currentUser;
if (user != null) {
  print('Logged in as: ${user.email}');
}
```

---

#### login(email, password)
```dart
Future<AuthResponse> login(String email, String password)
```

**Parameters**:
- `email`: User email address
- `password`: User password

**Returns**: `AuthResponse` with user and session

**Throws**: `AuthException` on failure

**Example**:
```dart
try {
  final response = await AuthService().login(
    'user@example.com',
    'password123',
  );
  print('Login successful: ${response.user?.email}');
} catch (e) {
  print('Login failed: $e');
}
```

---

#### signup(email, password)
```dart
Future<AuthResponse> signup(String email, String password)
```

**Parameters**:
- `email`: New user email
- `password`: New user password

**Returns**: `AuthResponse` with user and session

**Throws**: `AuthException` on failure

**Example**:
```dart
try {
  final response = await AuthService().signup(
    'newuser@example.com',
    'securepassword',
  );
  print('Signup successful: ${response.user?.id}');
} catch (e) {
  print('Signup failed: $e');
}
```

---

#### logout()
```dart
Future<void> logout()
```

**Returns**: `Future<void>`

**Throws**: `AuthException` on failure

**Example**:
```dart
await AuthService().logout();
print('Logged out successfully');
```

---

### ExpenseService API

#### getExpensesStream()
```dart
Stream<List<Expense>> getExpensesStream()
```

**Returns**: Stream of expense list (context-aware)

**Behavior**:
- **Personal context**: Returns expenses where `user_id = current_user` AND `group_id IS NULL`
- **Group context**: Returns expenses where `group_id = selected_group`

**Example**:
```dart
final stream = ExpenseService().getExpensesStream();

stream.listen((expenses) {
  print('Received ${expenses.length} expenses');
});

// Or in widget:
StreamBuilder<List<Expense>>(
  stream: ExpenseService().getExpensesStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView(children: ...);
    }
    return CircularProgressIndicator();
  },
)
```

---

#### addExpense(expense)
```dart
Future<void> addExpense(Expense expense)
```

**Parameters**:
- `expense`: Expense object to create

**Returns**: `Future<void>`

**Throws**: `PostgrestException` on failure

**Side Effects**:
- If group expense: Creates `expense_splits` records
- Triggers real-time update to all subscribers

**Example**:
```dart
final expense = Expense(
  description: 'Lunch',
  amount: 12.50,
  date: DateTime.now(),
  type: Tipologia.ristorante,
  userId: AuthService().currentUserId,
  groupId: null, // Personal expense
);

await ExpenseService().addExpense(expense);
```

---

#### updateExpense(expense)
```dart
Future<void> updateExpense(Expense expense)
```

**Parameters**:
- `expense`: Expense object with updated fields

**Returns**: `Future<void>`

**Throws**: `PostgrestException` on failure

**Side Effects**:
- If split-related fields changed: Recalculates `expense_splits`
- Triggers real-time update

**Example**:
```dart
expense.amount = 15.00;
expense.description = 'Lunch (updated)';

await ExpenseService().updateExpense(expense);
```

---

#### deleteExpense(expenseId)
```dart
Future<void> deleteExpense(int expenseId)
```

**Parameters**:
- `expenseId`: ID of expense to delete

**Returns**: `Future<void>`

**Throws**: `PostgrestException` on failure

**Side Effects**:
- Cascades delete to `expense_splits`
- Triggers real-time update

**Example**:
```dart
await ExpenseService().deleteExpense(123);
```

---

#### calculateBalance()
```dart
Future<DebtBalance> calculateBalance()
```

**Returns**: `DebtBalance` object with debt calculations

**Behavior**:
- Calculates total paid by each group member
- Calculates total owed by each member
- Computes net balance

**Example**:
```dart
final balance = await ExpenseService().calculateBalance();
print('Balance: €${balance.netBalance}');
```

---

### GroupService API

#### getUserGroups()
```dart
Future<List<ExpenseGroup>> getUserGroups()
```

**Returns**: List of groups user is a member of

**Example**:
```dart
final groups = await GroupService().getUserGroups();
print('User is in ${groups.length} groups');
```

---

#### createGroup(name, description)
```dart
Future<ExpenseGroup> createGroup(String name, String? description)
```

**Parameters**:
- `name`: Group name (required)
- `description`: Group description (optional)

**Returns**: Created `ExpenseGroup` object

**Side Effects**:
- Creates group record
- Adds creator as admin member

**Example**:
```dart
final group = await GroupService().createGroup(
  'Roommates',
  'Shared apartment expenses',
);
print('Created group: ${group.id}');
```

---

#### inviteMember(groupId, email)
```dart
Future<void> inviteMember(String groupId, String email)
```

**Parameters**:
- `groupId`: UUID of group
- `email`: Email of user to invite

**Returns**: `Future<void>`

**Throws**: `PostgrestException` if user not found or already invited

**Side Effects**:
- Creates invitation record with 7-day expiry

**Example**:
```dart
await GroupService().inviteMember(
  'group-uuid-here',
  'friend@example.com',
);
```

---

#### acceptInvitation(inviteId)
```dart
Future<void> acceptInvitation(String inviteId)
```

**Parameters**:
- `inviteId`: UUID of invitation

**Returns**: `Future<void>`

**Side Effects**:
- Creates `group_member` record with "member" role
- Updates invitation status to "accepted"

**Example**:
```dart
await GroupService().acceptInvitation('invite-uuid-here');
```

---

#### rejectInvitation(inviteId)
```dart
Future<void> rejectInvitation(String inviteId)
```

**Parameters**:
- `inviteId`: UUID of invitation

**Returns**: `Future<void>`

**Side Effects**:
- Updates invitation status to "rejected"

**Example**:
```dart
await GroupService().rejectInvitation('invite-uuid-here');
```

---

#### getGroupMembers(groupId)
```dart
Future<List<GroupMember>> getGroupMembers(String groupId)
```

**Parameters**:
- `groupId`: UUID of group

**Returns**: List of `GroupMember` objects

**Example**:
```dart
final members = await GroupService().getGroupMembers('group-uuid');
print('Group has ${members.length} members');
```

---

### ProfileService API

#### getCurrentProfile()
```dart
Future<UserProfile> getCurrentProfile()
```

**Returns**: Current user's profile

**Example**:
```dart
final profile = await ProfileService().getCurrentProfile();
print('Nickname: ${profile.nickname}');
```

---

#### updateProfile(nickname, avatarUrl)
```dart
Future<void> updateProfile(String? nickname, String? avatarUrl)
```

**Parameters**:
- `nickname`: New nickname (optional)
- `avatarUrl`: New avatar URL (optional)

**Returns**: `Future<void>`

**Example**:
```dart
await ProfileService().updateProfile('NewNickname', null);
```

---

#### searchProfileByEmail(email)
```dart
Future<UserProfile?> searchProfileByEmail(String email)
```

**Parameters**:
- `email`: Email to search for

**Returns**: `UserProfile` if found, `null` otherwise

**Example**:
```dart
final profile = await ProfileService().searchProfileByEmail(
  'friend@example.com',
);

if (profile != null) {
  print('Found user: ${profile.nickname}');
}
```

---

### ContextManager API

#### currentContext (getter)
```dart
ExpenseContext get currentContext
```

**Returns**: Current expense context (personal or group)

**Example**:
```dart
final context = ContextManager().currentContext;

if (context.isPersonal) {
  print('In personal context');
} else {
  print('In group context: ${context.group?.name}');
}
```

---

#### switchToPersonal()
```dart
void switchToPersonal()
```

**Side Effects**:
- Updates `_currentContext` to personal
- Calls `notifyListeners()` to trigger UI rebuild

**Example**:
```dart
ContextManager().switchToPersonal();
```

---

#### switchToGroup(group)
```dart
void switchToGroup(ExpenseGroup group)
```

**Parameters**:
- `group`: Group to switch to

**Side Effects**:
- Updates `_currentContext` to group
- Calls `notifyListeners()` to trigger UI rebuild

**Example**:
```dart
final group = await GroupService().getUserGroups().first;
ContextManager().switchToGroup(group);
```

---

#### loadUserGroups()
```dart
Future<void> loadUserGroups()
```

**Side Effects**:
- Fetches user's groups from database
- Updates `_userGroups` list
- Calls `notifyListeners()`

**Example**:
```dart
await ContextManager().loadUserGroups();
print('Loaded ${ContextManager().userGroups.length} groups');
```

---

## Database Operations

### Direct Database Queries

While services abstract most operations, you can perform direct queries using the Supabase client:

#### Select Query
```dart
final response = await Supabase.instance.client
  .from('expenses')
  .select()
  .eq('user_id', userId)
  .order('date', ascending: false)
  .limit(10);

final expenses = response.map((json) => Expense.fromJson(json)).toList();
```

**Generated SQL**:
```sql
SELECT *
FROM expenses
WHERE user_id = 'uuid-here'
ORDER BY date DESC
LIMIT 10;
```

---

#### Insert Query
```dart
final response = await Supabase.instance.client
  .from('expenses')
  .insert({
    'user_id': userId,
    'description': 'Coffee',
    'amount': 3.50,
    'date': DateTime.now().toIso8601String(),
    'type': 'ristorante',
  })
  .select()
  .single();

final expense = Expense.fromJson(response);
```

**Generated SQL**:
```sql
INSERT INTO expenses (user_id, description, amount, date, type)
VALUES ('uuid', 'Coffee', 3.50, '2024-11-15T10:00:00Z', 'ristorante')
RETURNING *;
```

---

#### Update Query
```dart
await Supabase.instance.client
  .from('expenses')
  .update({'amount': 5.00})
  .eq('id', expenseId);
```

**Generated SQL**:
```sql
UPDATE expenses
SET amount = 5.00
WHERE id = 123;
```

---

#### Delete Query
```dart
await Supabase.instance.client
  .from('expenses')
  .delete()
  .eq('id', expenseId);
```

**Generated SQL**:
```sql
DELETE FROM expenses
WHERE id = 123;
```

---

### Complex Queries

#### Join Query (Expenses with User Info)
```dart
final response = await Supabase.instance.client
  .from('expenses')
  .select('''
    *,
    payer:profiles!paid_by(nickname, email)
  ''')
  .eq('group_id', groupId);
```

**Generated SQL**:
```sql
SELECT
  expenses.*,
  profiles.nickname AS payer_nickname,
  profiles.email AS payer_email
FROM expenses
LEFT JOIN profiles ON expenses.paid_by = profiles.id
WHERE expenses.group_id = 'group-uuid';
```

---

#### Aggregation Query
```dart
final response = await Supabase.instance.client
  .from('expenses')
  .select('type, amount.sum()')
  .eq('user_id', userId);
```

**Generated SQL**:
```sql
SELECT
  type,
  SUM(amount) AS amount_sum
FROM expenses
WHERE user_id = 'uuid'
GROUP BY type;
```

---

## Real-time Subscriptions

### Stream Subscription Pattern

```dart
// Subscribe to table changes
final stream = Supabase.instance.client
  .from('expenses')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .order('date', ascending: false);

// Listen to stream
final subscription = stream.listen((data) {
  print('Received ${data.length} expenses');
  // Update UI
});

// Cancel subscription when done
subscription.cancel();
```

### WebSocket Events

**Connection Established**:
```json
{
  "event": "system",
  "topic": "realtime:expenses",
  "payload": {
    "status": "ok"
  }
}
```

**INSERT Event**:
```json
{
  "event": "INSERT",
  "table": "expenses",
  "schema": "public",
  "commit_timestamp": "2024-11-15T10:00:00Z",
  "new": {
    "id": 124,
    "description": "New expense",
    "amount": 10.00,
    ...
  }
}
```

**UPDATE Event**:
```json
{
  "event": "UPDATE",
  "table": "expenses",
  "schema": "public",
  "commit_timestamp": "2024-11-15T10:05:00Z",
  "old": {
    "id": 124,
    "amount": 10.00
  },
  "new": {
    "id": 124,
    "amount": 15.00
  }
}
```

**DELETE Event**:
```json
{
  "event": "DELETE",
  "table": "expenses",
  "schema": "public",
  "commit_timestamp": "2024-11-15T10:10:00Z",
  "old": {
    "id": 124
  }
}
```

---

## Error Handling

### Error Types

#### 1. AuthException
```dart
try {
  await AuthService().login(email, password);
} on AuthException catch (e) {
  if (e.statusCode == '400') {
    print('Invalid credentials');
  } else if (e.statusCode == '422') {
    print('User not found');
  } else {
    print('Auth error: ${e.message}');
  }
}
```

**Common codes**:
- `400`: Invalid request
- `422`: Invalid credentials
- `500`: Server error

---

#### 2. PostgrestException
```dart
try {
  await ExpenseService().addExpense(expense);
} on PostgrestException catch (e) {
  if (e.code == '23503') {
    print('Foreign key violation');
  } else if (e.code == '42501') {
    print('RLS policy violation (permission denied)');
  } else {
    print('Database error: ${e.message}');
  }
}
```

**Common codes**:
- `23503`: Foreign key violation
- `23505`: Unique constraint violation
- `42501`: Insufficient privilege (RLS)

---

#### 3. Network Errors
```dart
try {
  await ExpenseService().addExpense(expense);
} on SocketException {
  print('No internet connection');
} on TimeoutException {
  print('Request timed out');
} catch (e) {
  print('Unknown error: $e');
}
```

---

### Error Response Formats

**Auth Error**:
```json
{
  "error": "invalid_grant",
  "error_description": "Invalid login credentials"
}
```

**Database Error**:
```json
{
  "code": "42501",
  "message": "new row violates row-level security policy",
  "details": null,
  "hint": null
}
```

---

## Performance Considerations

### 1. Query Optimization

**✅ Good: Use indexes**
```dart
// Database has index on user_id
final expenses = await Supabase.instance.client
  .from('expenses')
  .select()
  .eq('user_id', userId); // Fast (uses index)
```

**❌ Bad: Full table scan**
```dart
// No index on description
final expenses = await Supabase.instance.client
  .from('expenses')
  .select()
  .ilike('description', '%grocery%'); // Slow (full table scan)
```

---

### 2. Pagination

**✅ Good: Use limit + offset**
```dart
final expenses = await Supabase.instance.client
  .from('expenses')
  .select()
  .eq('user_id', userId)
  .order('date', ascending: false)
  .range(0, 19); // First 20 items

// Next page:
.range(20, 39); // Next 20 items
```

---

### 3. Selective Fields

**✅ Good: Select only needed fields**
```dart
final data = await Supabase.instance.client
  .from('expenses')
  .select('id, description, amount')
  .eq('user_id', userId);
```

**❌ Bad: Select all fields when not needed**
```dart
final data = await Supabase.instance.client
  .from('expenses')
  .select('*') // Fetches all columns including unused ones
  .eq('user_id', userId);
```

---

### 4. Batch Operations

**✅ Good: Batch insert**
```dart
await Supabase.instance.client
  .from('expenses')
  .insert([
    {'description': 'A', 'amount': 10},
    {'description': 'B', 'amount': 20},
    {'description': 'C', 'amount': 30},
  ]);
// Single network request
```

**❌ Bad: Multiple individual inserts**
```dart
for (var expense in expenses) {
  await Supabase.instance.client
    .from('expenses')
    .insert(expense.toJson());
  // Multiple network requests (slow)
}
```

---

### 5. Stream Management

**✅ Good: Cancel subscriptions**
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = stream.listen((data) {
      // Handle data
    });
  }

  @override
  void dispose() {
    _subscription.cancel(); // Prevent memory leak
    super.dispose();
  }
}
```

---

## API Rate Limits

Supabase has the following rate limits (default tier):

| Operation | Limit |
|-----------|-------|
| API requests | 500 requests/second |
| Real-time connections | 500 concurrent connections |
| Authentication | 30 requests/hour per IP (signup/login) |

**Handling Rate Limits**:
```dart
try {
  await ExpenseService().addExpense(expense);
} on PostgrestException catch (e) {
  if (e.code == '429') {
    print('Rate limit exceeded, please wait');
    // Implement exponential backoff
  }
}
```

---

## Testing API Endpoints

### Using curl

**Login**:
```bash
curl -X POST https://your-project.supabase.co/auth/v1/token?grant_type=password \
  -H "Content-Type: application/json" \
  -H "apikey: your-anon-key" \
  -d '{"email":"user@example.com","password":"password123"}'
```

**Fetch Expenses**:
```bash
curl -X GET https://your-project.supabase.co/rest/v1/expenses \
  -H "apikey: your-anon-key" \
  -H "Authorization: Bearer your-jwt-token"
```

**Create Expense**:
```bash
curl -X POST https://your-project.supabase.co/rest/v1/expenses \
  -H "apikey: your-anon-key" \
  -H "Authorization: Bearer your-jwt-token" \
  -H "Content-Type: application/json" \
  -d '{"description":"Test","amount":10.00,"date":"2024-11-15T10:00:00Z","type":"altro"}'
```

---

## Conclusion

This documentation covers the complete API surface of Solducci, including:
- ✅ Authentication flows
- ✅ Service APIs
- ✅ Database operations
- ✅ Real-time subscriptions
- ✅ Error handling
- ✅ Performance optimization

For implementation examples and architecture details, see:
- [Technical Architecture](./02_TECHNICAL_ARCHITECTURE.md)
- [Developer Onboarding](./04_DEVELOPER_ONBOARDING.md)
- [Feature Guide](./03_FEATURE_GUIDE.md)

---

*Last updated: November 2024*
