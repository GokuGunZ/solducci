# Solducci - Feature Guide

> **Audience**: Product managers, QA testers, designers, junior developers
> **Level**: Feature-focused, user-story driven

---

## Table of Contents
1. [Authentication & User Management](#authentication--user-management)
2. [Expense Management](#expense-management)
3. [Group Management](#group-management)
4. [Context Switching](#context-switching)
5. [Expense Splitting](#expense-splitting)
6. [Analytics & Dashboard](#analytics--dashboard)
7. [User Profile](#user-profile)
8. [Future Features](#future-features)

---

## Authentication & User Management

### Feature: User Registration
**Status**: ✅ Implemented

#### User Story
> As a new user, I want to create an account so that I can start tracking my expenses.

#### Implementation Details
- **Location**: [lib/views/login_page.dart](../lib/views/login_page.dart), [lib/views/signup_page.dart](../lib/views/signup_page.dart)
- **Service**: [lib/service/auth_service.dart](../lib/service/auth_service.dart)

#### Flow
1. User navigates to signup page
2. Enters email and password
3. Submits form
4. Supabase creates user account
5. Database trigger auto-creates profile record
6. User is automatically logged in
7. Redirected to home page

#### Validations
- ✅ Email format validation
- ✅ Password minimum length (6 characters)
- ✅ Password confirmation match
- ✅ Duplicate email detection

#### Error Handling
- Invalid email format → "Please enter a valid email"
- Weak password → "Password must be at least 6 characters"
- Email already registered → "User already registered"
- Network error → "Connection failed, please try again"

---

### Feature: User Login
**Status**: ✅ Implemented

#### User Story
> As a returning user, I want to log in to access my expense data.

#### Implementation Details
- **Location**: [lib/views/login_page.dart](../lib/views/login_page.dart)
- **Service**: [lib/service/auth_service.dart](../lib/service/auth_service.dart)

#### Flow
1. User enters email and password
2. Taps "Login" button
3. AuthService validates credentials with Supabase
4. JWT token stored securely
5. ContextManager initialized
6. User groups loaded
7. Redirected to home page

#### Validations
- ✅ Email and password required
- ✅ Credentials verification

#### Error Handling
- Invalid credentials → "Invalid email or password"
- Network error → "Connection failed"
- Account not verified → "Please verify your email"

---

### Feature: User Logout
**Status**: ✅ Implemented

#### User Story
> As a logged-in user, I want to log out securely.

#### Implementation Details
- **Location**: [lib/views/new_homepage.dart](../lib/views/new_homepage.dart)
- **Service**: [lib/service/auth_service.dart](../lib/service/auth_service.dart)

#### Flow
1. User taps logout button in AppBar
2. Confirmation dialog appears
3. User confirms logout
4. AuthService signs out from Supabase
5. JWT token cleared
6. ContextManager reset
7. Redirected to login page

---

## Expense Management

### Feature: Create Personal Expense
**Status**: ✅ Implemented

#### User Story
> As a user, I want to add a personal expense so that I can track my spending.

#### Implementation Details
- **Location**: [lib/models/expense_form.dart](../lib/models/expense_form.dart)
- **Service**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### Flow
1. User taps FAB (Floating Action Button) on home page
2. Expense form modal appears (full-screen)
3. User fills in:
   - Amount (currency input)
   - Description
   - Date (defaults to today)
   - Category (dropdown)
4. User taps "Save"
5. ExpenseService creates expense in database
6. Real-time stream updates
7. New expense appears in list instantly

#### Fields
| Field | Type | Required | Default | Validation |
|-------|------|----------|---------|------------|
| Amount | Double | Yes | - | > 0 |
| Description | String | Yes | - | Max 100 chars |
| Date | DateTime | Yes | Today | Not in future |
| Category | Enum | Yes | "Altro" | From predefined list |

#### Categories
1. 🏠 **Affitto** (Rent) - Blue
2. 🍕 **Cibo** (Food/Groceries) - Green
3. 💡 **Utenze** (Utilities) - Orange
4. 🧹 **Prodotti Casa** (Household) - Purple
5. 🍽️ **Ristorante** (Dining Out) - Red
6. 🎮 **Tempo Libero** (Entertainment) - Pink
7. 📦 **Altro** (Other) - Grey

#### Success Indicators
- ✅ Expense appears in list
- ✅ SnackBar confirms "Expense added"
- ✅ Form closes automatically
- ✅ Balance updates (if group context)

---

### Feature: Create Group Expense
**Status**: ✅ Implemented

#### User Story
> As a group member, I want to add a group expense and specify how it should be split.

#### Implementation Details
- **Location**: [lib/models/expense_form.dart](../lib/models/expense_form.dart), [lib/widgets/group_expense_fields.dart](../lib/widgets/group_expense_fields.dart)
- **Service**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### Flow
1. User switches to group context
2. Taps FAB on home page
3. Expense form appears with additional group fields:
   - **Who paid?** (select group member)
   - **Split type** (equal, custom, lend, offer)
   - Custom split editor (if custom selected)
4. User fills all fields
5. Taps "Save"
6. ExpenseService creates expense with split data
7. ExpenseSplits records created automatically
8. All group members see the new expense instantly

#### Group-Specific Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Paid By | UUID | Yes | Group member who paid |
| Split Type | Enum | Yes | How to divide expense |
| Split Data | Map | Conditional | Custom amounts (if custom split) |

#### Split Type Options
See [Expense Splitting](#expense-splitting) section for details.

---

### Feature: Edit Expense
**Status**: ✅ Implemented

#### User Story
> As a user, I want to edit an existing expense to correct mistakes.

#### Implementation Details
- **Location**: [lib/models/expense_form.dart](../lib/models/expense_form.dart)
- **Service**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### Flow
1. User taps on expense in list
2. Bottom sheet shows expense details
3. User taps "Edit" button
4. Expense form pre-filled with existing data
5. User modifies fields
6. Taps "Save"
7. ExpenseService updates expense
8. Split recalculation (if split type changed)
9. Updated expense appears in list

#### Recalculation Trigger
If these fields change, splits are recalculated:
- Amount
- Split type
- Split data (custom amounts)
- Group members involved

---

### Feature: Delete Expense
**Status**: ✅ Implemented

#### User Story
> As a user, I want to delete an expense I added by mistake.

#### Implementation Details
- **Location**: [lib/widgets/expense_list_item.dart](../lib/widgets/expense_list_item.dart)
- **Service**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### Flow (Swipe-to-Delete)
1. User swipes expense item left
2. Delete action appears
3. User continues swipe or taps delete
4. Confirmation dialog appears
5. User confirms
6. ExpenseService deletes expense from database
7. Associated expense_splits deleted (cascade)
8. Expense disappears from list

#### Alternative Flow (Detail View)
1. User taps expense
2. Bottom sheet opens
3. User taps delete icon
4. Confirmation dialog appears
5. User confirms deletion
6. Expense deleted

#### Safeguards
- ✅ Confirmation dialog required
- ✅ Cascade delete for splits
- ✅ No undo (future feature)

---

### Feature: View Expense Details
**Status**: ✅ Implemented

#### User Story
> As a user, I want to see full details of an expense including split information.

#### Implementation Details
- **Location**: [lib/widgets/expense_list_item.dart](../lib/widgets/expense_list_item.dart)

#### Flow
1. User taps on expense in list
2. Modal bottom sheet appears
3. Displays:
   - Amount (large, formatted)
   - Description
   - Date (formatted)
   - Category (with icon and color)
   - Who paid (if group expense)
   - Split type (if group expense)
   - Split breakdown (who owes what)
4. Actions available:
   - Edit button
   - Delete button
   - Close button

#### Information Displayed (Personal Expense)
- 💰 Amount: €123.45
- 📝 Description: "Grocery shopping"
- 📅 Date: "15 Nov 2024"
- 🏷️ Category: Cibo (Food)

#### Information Displayed (Group Expense)
- 💰 Amount: €150.00
- 📝 Description: "Rent payment"
- 📅 Date: "1 Nov 2024"
- 🏷️ Category: Affitto (Rent)
- 👤 Paid by: Marco
- 🔀 Split: Equally among 2 members
- Split details:
  - Marco owes: €0.00 (paid)
  - Sofia owes: €75.00

---

## Group Management

### Feature: Create Group
**Status**: ✅ Implemented

#### User Story
> As a user, I want to create a group so that I can share expenses with others.

#### Implementation Details
- **Location**: [lib/views/groups/create_group_page.dart](../lib/views/groups/create_group_page.dart)
- **Service**: [lib/service/group_service.dart](../lib/service/group_service.dart)

#### Flow
1. User navigates to Profile page
2. Taps "Create New Group" button
3. Group creation form appears
4. User enters:
   - Group name (required)
   - Description (optional)
5. Taps "Create"
6. GroupService creates group in database
7. User automatically added as admin member
8. Group appears in user's group list
9. ContextManager refreshes user groups
10. User can switch to new group immediately

#### Validations
- ✅ Name required (min 3 characters)
- ✅ Name max 50 characters
- ✅ Description optional (max 200 characters)

#### Success Indicators
- ✅ Group appears in profile page
- ✅ Group selectable in context switcher
- ✅ User marked as admin

---

### Feature: Invite Group Member
**Status**: ✅ Implemented

#### User Story
> As a group admin, I want to invite someone to my group via email.

#### Implementation Details
- **Location**: [lib/views/groups/invite_member_page.dart](../lib/views/groups/invite_member_page.dart)
- **Service**: [lib/service/group_service.dart](../lib/service/group_service.dart)

#### Flow
1. User (admin) opens group detail page
2. Taps "Invite Member" button
3. Invitation form appears
4. User enters invitee's email
5. Taps "Send Invitation"
6. GroupService:
   - Checks if email exists in profiles
   - Creates invitation record with expiry (7 days)
   - Sets status to "pending"
7. Invitee can see invitation in their pending invites
8. SnackBar confirms "Invitation sent"

#### Validations
- ✅ Valid email format
- ✅ User exists in system
- ✅ User not already in group
- ✅ No duplicate pending invitation

#### Invitation Expiry
- Default: **7 days** from creation
- After expiry: Status changed to "expired"
- Expired invitations not shown to invitee

---

### Feature: Accept/Reject Group Invitation
**Status**: ✅ Implemented

#### User Story
> As an invited user, I want to accept or reject group invitations.

#### Implementation Details
- **Location**: [lib/views/groups/pending_invites_page.dart](../lib/views/groups/pending_invites_page.dart)
- **Service**: [lib/service/group_service.dart](../lib/service/group_service.dart)

#### Flow (Accept)
1. User navigates to Profile page
2. Sees "Pending Invitations" badge
3. Taps to view invitations
4. List of pending invitations appears
5. Each shows:
   - Group name
   - Invited by (name/email)
   - Expiry date
6. User taps "Accept"
7. GroupService:
   - Creates group_member record
   - Sets role to "member"
   - Updates invitation status to "accepted"
8. User's groups list refreshed
9. User can now switch to new group

#### Flow (Reject)
1. User taps "Reject" on invitation
2. Confirmation dialog appears
3. User confirms
4. GroupService updates invitation status to "rejected"
5. Invitation removed from list

#### Business Rules
- ✅ Only "pending" invitations shown
- ✅ Expired invitations auto-hidden
- ✅ Accepted invitations grant "member" role
- ✅ User becomes group member immediately upon acceptance

---

### Feature: View Group Details
**Status**: ✅ Implemented

#### User Story
> As a group member, I want to see group information and member list.

#### Implementation Details
- **Location**: [lib/views/groups/group_detail_page.dart](../lib/views/groups/group_detail_page.dart)
- **Service**: [lib/service/group_service.dart](../lib/service/group_service.dart)

#### Information Displayed
1. **Group Info**
   - Name
   - Description
   - Created date
   - Number of members

2. **Member List**
   - Nickname (or email if no nickname)
   - Avatar (placeholder for now)
   - Role badge (admin/member)
   - Join date

3. **Actions (Admin Only)**
   - Invite member button
   - Remove member (future)
   - Edit group settings (future)

#### Permissions
| Action | Admin | Member |
|--------|-------|--------|
| View details | ✅ | ✅ |
| View members | ✅ | ✅ |
| Invite members | ✅ | ❌ |
| Remove members | ✅ | ❌ |
| Delete group | ✅ | ❌ |
| Leave group | ✅ | ✅ |

---

### Feature: Remove Group Member
**Status**: 🚧 Planned (Future)

#### User Story
> As a group admin, I want to remove a member who no longer needs access.

#### Planned Flow
1. Admin opens group detail page
2. Taps on member
3. Selects "Remove from group"
4. Confirmation dialog
5. Member removed
6. Member can no longer see group expenses

---

## Context Switching

### Feature: Switch Between Personal & Group
**Status**: ✅ Implemented

#### User Story
> As a user with multiple groups, I want to easily switch between personal and group expense views.

#### Implementation Details
- **Location**: [lib/widgets/context_switcher.dart](../lib/widgets/context_switcher.dart)
- **Service**: [lib/service/context_manager.dart](../lib/service/context_manager.dart)

#### Flow
1. User taps context indicator in AppBar (shows current context)
2. Modal bottom sheet appears with:
   - "Personal" option (always available)
   - List of user's groups
   - "Create New Group" button
3. User selects context (personal or specific group)
4. ContextManager updates current context
5. notifyListeners() called
6. All listening widgets rebuild:
   - AppBar title updates
   - Expense stream filters change
   - Dashboard shows context-specific data
7. Modal closes
8. UI reflects new context immediately

#### Context Indicator Display
- **Personal context**: "Personal Expenses"
- **Group context**: "[Group Name]"
- Icon: 👤 for personal, 👥 for group

#### What Changes on Context Switch
| Component | Personal Context | Group Context |
|-----------|------------------|---------------|
| AppBar title | "Personal Expenses" | Group name |
| Expense list | User's personal expenses | Group's expenses |
| Dashboard | Personal analytics | Group analytics |
| Balance view | N/A | Group balances |
| FAB expense form | Personal expense form | Group expense form |

#### Technical Implementation
```dart
// ContextManager notifies listeners
_contextManager.switchToGroup(selectedGroup);

// ExpenseService detects change
Stream<List<Expense>> getExpensesStream() {
  if (_contextManager.currentContext.isPersonal) {
    // Filter: user_id = current user AND group_id IS NULL
  } else {
    // Filter: group_id = selected group
  }
}

// UI rebuilds automatically
StreamBuilder<List<Expense>>(
  stream: _expenseService.getExpensesStream(),
  builder: (context, snapshot) {
    // Always shows correct data for current context
  },
)
```

---

## Expense Splitting

### Feature: Equal Split
**Status**: ✅ Implemented

#### User Story
> As a group member, I want to split an expense equally among all members.

#### Use Cases
- Shared dinner at a restaurant
- Utilities bill
- Groceries for the household

#### Implementation
- **Location**: [lib/models/split_type.dart](../lib/models/split_type.dart)
- **Service**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### How It Works
1. User creates group expense
2. Selects "Equal Split" (Equamente tra tutti)
3. Amount divided equally: `amount / member_count`
4. ExpenseSplits created for each member
5. Payer owes €0
6. Others owe their equal share

#### Example
- **Amount**: €150
- **Group**: 3 members (Alice, Bob, Charlie)
- **Paid by**: Alice
- **Result**:
  - Alice owes: €0 (she paid)
  - Bob owes: €50
  - Charlie owes: €50
  - Alice is owed: €100 total

---

### Feature: Custom Split
**Status**: ✅ Implemented

#### User Story
> As a group member, I want to specify exact amounts each person should pay.

#### Use Cases
- Different room sizes (rent split)
- Unequal consumption (utilities)
- Person-specific purchases

#### Implementation
- **Location**: [lib/widgets/custom_split_editor.dart](../lib/widgets/custom_split_editor.dart)
- **Service**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### How It Works
1. User creates group expense
2. Selects "Custom Split" (Importi custom)
3. Custom split editor appears
4. User enters amount for each member
5. UI shows running total and remaining amount
6. Validation: Total must equal expense amount
7. User saves expense
8. ExpenseSplits created with custom amounts

#### Example
- **Amount**: €900 (rent)
- **Group**: Alice (big room), Bob (small room)
- **Paid by**: Alice
- **Custom split**:
  - Alice: €550 (big room)
  - Bob: €350 (small room)
- **Result**:
  - Alice owes: €0 (she paid)
  - Bob owes: €350
  - Alice is owed: €350

#### Validations
- ✅ All members must have an amount
- ✅ Sum must equal total expense
- ✅ Amounts must be ≥ 0
- ✅ Cannot save until totals match

---

### Feature: Lend Split (Advance Payment)
**Status**: ✅ Implemented

#### User Story
> As a group member, I want to record that I advanced money that others will reimburse.

#### Use Cases
- Paid hotel upfront, others reimburse later
- Bought tickets for the group
- Advanced payment for group purchase

#### Implementation
- **Location**: [lib/models/split_type.dart](../lib/models/split_type.dart)
- **Service**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### How It Works
1. User creates group expense
2. Selects "Lend" (Presta)
3. Amount divided equally among OTHER members
4. Payer owes €0
5. Others owe their equal share
6. Full reimbursement expected

#### Example
- **Amount**: €200 (concert tickets)
- **Group**: Marco (payer), Sofia, Luigi
- **Paid by**: Marco
- **Split type**: Lend
- **Result**:
  - Marco owes: €0
  - Sofia owes: €100 (reimburse Marco)
  - Luigi owes: €100 (reimburse Marco)
  - Marco is owed: €200 total

#### Difference from Equal Split
| Aspect | Equal Split | Lend Split |
|--------|-------------|------------|
| Payer's share | Pays their portion | Pays nothing (full reimbursement) |
| Others' share | Equal split | Equal split |
| Intent | Shared expense | Advance payment |

---

### Feature: Offer Split (Gift)
**Status**: ✅ Implemented

#### User Story
> As a group member, I want to record that I'm treating the group (no reimbursement).

#### Use Cases
- Birthday treat
- Celebration dinner
- Thank-you gift

#### Implementation
- **Location**: [lib/models/split_type.dart](../lib/models/split_type.dart)
- **Service**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### How It Works
1. User creates group expense
2. Selects "Offer" (Offri)
3. Amount entirely attributed to payer
4. No splits created (or splits with €0)
5. No reimbursement expected
6. Tracked for transparency only

#### Example
- **Amount**: €80 (birthday dinner)
- **Group**: Alice, Bob, Charlie
- **Paid by**: Alice (it's Bob's birthday)
- **Split type**: Offer
- **Result**:
  - Alice owes: €0
  - Bob owes: €0 (it's a gift)
  - Charlie owes: €0
  - Alice is owed: €0

#### Use Case
Tracks that expense occurred, but doesn't create debts. Useful for:
- Transparency in group spending
- Historical record
- Understanding who contributes more voluntarily

---

## Analytics & Dashboard

### Feature: Dashboard Hub
**Status**: ✅ Implemented

#### User Story
> As a user, I want a central place to access all analytics views.

#### Implementation Details
- **Location**: [lib/views/dashboard_hub.dart](../lib/views/dashboard_hub.dart)

#### Components
Grid of clickable cards:
1. **Monthly View** - Expenses grouped by month
2. **Category View** - Breakdown by category
3. **Timeline View** - Chronological expense list
4. **Balance View** - Debt/credit calculations (group only)
5. **Recurring Expenses** - Placeholder (future)
6. **Charts** - Placeholder (future)

#### Navigation
Each card navigates to full-screen analytics view.

---

### Feature: Monthly View
**Status**: ✅ Implemented

#### User Story
> As a user, I want to see my expenses organized by month with totals.

#### Implementation Details
- **Location**: [lib/views/monthly_view.dart](../lib/views/monthly_view.dart)
- **Service**: [lib/models/dashboard_data.dart](../lib/models/dashboard_data.dart)

#### Display
- Expenses grouped by month
- Each month shows:
  - Month label (e.g., "Novembre 2024")
  - List of expenses
  - Monthly total
- Sorted newest to oldest
- Context-aware (personal/group)

#### Example Display
```
Novembre 2024                    Total: €1,245.67
├─ 15 Nov - Groceries            €85.00
├─ 10 Nov - Rent                 €900.00
├─ 5 Nov - Restaurant            €45.50
└─ 1 Nov - Utilities             €215.17

Ottobre 2024                     Total: €1,156.32
├─ 28 Oct - Groceries            €92.00
...
```

---

### Feature: Category View
**Status**: ✅ Implemented

#### User Story
> As a user, I want to see how much I spend in each category.

#### Implementation Details
- **Location**: [lib/views/category_view.dart](../lib/views/category_view.dart)
- **Service**: [lib/models/dashboard_data.dart](../lib/models/dashboard_data.dart)

#### Display
- Categories sorted by total (highest first)
- Each category shows:
  - Category icon and name
  - Total amount
  - Number of expenses
  - Percentage of total spending
  - Color-coded bar

#### Example Display
```
Affitto (Rent)               €900.00      45%    [██████████]
├─ 2 expenses

Cibo (Groceries)             €450.00      22.5%  [████]
├─ 12 expenses

Ristorante (Dining)          €320.00      16%    [███]
├─ 8 expenses

...
```

#### Analytics Calculated
- Total per category: `SUM(amount) WHERE type = category`
- Count per category: `COUNT(*) WHERE type = category`
- Percentage: `(category_total / grand_total) * 100`

---

### Feature: Timeline View
**Status**: ✅ Implemented

#### User Story
> As a user, I want to see a chronological list of all expenses.

#### Implementation Details
- **Location**: [lib/views/timeline_view.dart](../lib/views/timeline_view.dart)
- **Service**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### Display
- Expenses grouped by date sections:
  - "Oggi" (Today)
  - "Ieri" (Yesterday)
  - Specific dates (e.g., "15 Novembre 2024")
- Each expense shows:
  - Category icon
  - Description
  - Amount
  - Time (if today/yesterday)
- Sorted newest first
- Swipe-to-delete enabled

#### Example Display
```
Oggi
├─ 14:30 - Restaurant            €45.00
└─ 09:15 - Coffee                €3.50

Ieri
├─ 20:00 - Groceries             €87.00
└─ 12:00 - Lunch                 €12.50

15 Novembre 2024
├─ Rent                          €900.00
└─ Utilities                     €125.00
```

---

### Feature: Balance View
**Status**: ✅ Implemented (Group only)

#### User Story
> As a group member, I want to see who owes money to whom.

#### Implementation Details
- **Location**: [lib/views/balance_view.dart](../lib/views/balance_view.dart)
- **Service**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### Calculation Logic
For each group member:
1. **Total Paid**: Sum of all expenses where `paid_by = member_id`
2. **Total Owed**: Sum of their splits from all group expenses
3. **Balance**: `Total Paid - Total Owed`
   - Positive balance → Member is owed money
   - Negative balance → Member owes money
   - Zero balance → Even

#### Example Display (2-member group)
```
Marco
├─ Paid: €1,200.00
├─ Owes: €800.00
└─ Balance: +€400.00 (is owed)

Sofia
├─ Paid: €400.00
├─ Owes: €800.00
└─ Balance: -€400.00 (owes)

Net Settlement:
Sofia owes Marco €400.00
```

#### Example Display (3-member group)
```
Alice
├─ Paid: €900.00
├─ Owes: €600.00
└─ Balance: +€300.00

Bob
├─ Paid: €600.00
├─ Owes: €600.00
└─ Balance: €0.00 (even)

Charlie
├─ Paid: €300.00
├─ Owes: €600.00
└─ Balance: -€300.00

Net Settlement:
Charlie owes Alice €300.00
Bob is settled up
```

#### Refresh Button
- Manual refresh trigger
- Recalculates all balances
- Updates UI with latest data

---

## User Profile

### Feature: View Profile
**Status**: ✅ Implemented

#### User Story
> As a user, I want to see my profile information and groups.

#### Implementation Details
- **Location**: [lib/views/profile_page.dart](../lib/views/profile_page.dart)
- **Service**: [lib/service/profile_service.dart](../lib/service/profile_service.dart)

#### Information Displayed
1. **User Info**
   - Avatar (placeholder)
   - Nickname
   - Email
   - Edit profile button

2. **My Groups**
   - List of groups user is member of
   - Each shows:
     - Group name
     - Member count
     - User's role (admin/member)
   - Tap to view group details

3. **Pending Invitations**
   - Badge showing count
   - Tap to view invitations

4. **Actions**
   - Create new group button
   - Logout button

---

### Feature: Edit Profile
**Status**: ✅ Implemented

#### User Story
> As a user, I want to update my nickname and avatar.

#### Implementation Details
- **Location**: [lib/views/profile_page.dart](../lib/views/profile_page.dart)
- **Service**: [lib/service/profile_service.dart](../lib/service/profile_service.dart)

#### Flow
1. User taps "Edit Profile"
2. Edit form appears
3. User can modify:
   - Nickname
   - Avatar (future: upload image)
4. Taps "Save"
5. ProfileService updates database
6. Profile page refreshes

#### Validations
- ✅ Nickname min 2 characters
- ✅ Nickname max 30 characters
- ✅ Nickname cannot be only whitespace

---

## Future Features

### Recurring Expenses / Subscriptions
**Status**: 📋 Planned

#### User Story
> As a user, I want to set up recurring expenses that automatically add each month.

#### Planned Features
- Define recurring expense template
- Frequency: daily, weekly, monthly, yearly
- Auto-create on schedule
- Edit future occurrences
- Pause/resume subscriptions
- Notification before auto-creation

---

### Personal Expenses View
**Status**: 📋 Planned

#### User Story
> As a user, I want a dedicated view for just my personal expenses.

#### Planned Features
- Dedicated tab or page
- Personal-only filtering
- Personal analytics
- Tags/labels for organization
- Budget tracking

---

### Notes System
**Status**: 📋 Planned

#### User Story
> As a user, I want to add notes to expenses for additional context.

#### Planned Features
- Rich text notes
- Attach notes to expenses
- Search notes
- Group notes vs personal notes
- Note history

---

### Receipt Photos
**Status**: 📋 Planned

#### User Story
> As a user, I want to attach receipt photos to expenses.

#### Planned Features
- Upload photos from camera/gallery
- Multiple photos per expense
- Image viewer
- OCR for automatic expense extraction
- Compression for storage efficiency

---

### Export Functionality
**Status**: 📋 Planned

#### User Story
> As a user, I want to export my expense data for external analysis.

#### Planned Features
- Export to CSV
- Export to PDF report
- Date range selection
- Category filtering
- Email export

---

### Multi-Currency Support
**Status**: 📋 Planned

#### User Story
> As a user traveling abroad, I want to track expenses in different currencies.

#### Planned Features
- Currency selection per expense
- Real-time exchange rates
- Base currency conversion
- Multi-currency reports
- Historical exchange rates

---

### Budget Tracking
**Status**: 📋 Planned

#### User Story
> As a user, I want to set spending limits and track against them.

#### Planned Features
- Budget per category
- Monthly budget limits
- Progress indicators
- Alerts when approaching limit
- Budget vs actual reports

---

### Advanced Charts
**Status**: 📋 Planned

#### User Story
> As a user, I want visual charts to understand spending trends.

#### Planned Features
- Pie charts (category breakdown)
- Line charts (spending over time)
- Bar charts (monthly comparison)
- Interactive charts
- Export chart images

---

## Testing Checklist

### Manual Testing Scenarios

#### Authentication Flow
- [ ] Sign up with new account
- [ ] Sign up with existing email (should fail)
- [ ] Log in with correct credentials
- [ ] Log in with wrong credentials (should fail)
- [ ] Log out and verify redirect to login

#### Personal Expense Flow
- [ ] Create personal expense
- [ ] Edit personal expense
- [ ] Delete personal expense
- [ ] View expense details

#### Group Flow
- [ ] Create new group
- [ ] Invite member to group
- [ ] Accept group invitation
- [ ] Reject group invitation
- [ ] View group details
- [ ] Switch between personal and group context

#### Group Expense Flow
- [ ] Create group expense (equal split)
- [ ] Create group expense (custom split)
- [ ] Create group expense (lend)
- [ ] Create group expense (offer)
- [ ] Verify splits calculated correctly
- [ ] Edit group expense
- [ ] Delete group expense

#### Analytics Flow
- [ ] View monthly view
- [ ] View category view
- [ ] View timeline view
- [ ] View balance view (group)
- [ ] Verify calculations correct
- [ ] Test with empty data

#### Real-time Sync
- [ ] Add expense on Device A, verify appears on Device B
- [ ] Edit expense on Device A, verify updates on Device B
- [ ] Delete expense on Device A, verify removed on Device B
- [ ] Create group on Device A, verify appears on Device B

---

## Known Issues & Limitations

### Current Limitations
1. **No offline support** - Requires internet connection
2. **No undo functionality** - Deletions are permanent
3. **No export feature** - Cannot export data yet
4. **No receipt photos** - Text-only expenses
5. **Single currency** - Euro (€) only
6. **Limited analytics** - No charts/graphs yet
7. **No push notifications** - Must open app to see updates

### Known Bugs
- None reported in current version

---

## Feature Priority Matrix

| Feature | Priority | Status | Target Phase |
|---------|----------|--------|--------------|
| Authentication | P0 | ✅ Done | MVP |
| Personal expenses | P0 | ✅ Done | MVP |
| Group management | P0 | ✅ Done | MVP |
| Expense splitting | P0 | ✅ Done | MVP |
| Context switching | P0 | ✅ Done | MVP |
| Basic analytics | P0 | ✅ Done | MVP |
| Recurring expenses | P1 | 📋 Planned | Phase 4 |
| Receipt photos | P1 | 📋 Planned | Phase 5 |
| Export | P1 | 📋 Planned | Phase 5 |
| Charts | P2 | 📋 Planned | Phase 6 |
| Multi-currency | P2 | 📋 Planned | Phase 6 |
| Budget tracking | P2 | 📋 Planned | Phase 7 |
| Notes system | P3 | 📋 Planned | Phase 7 |

---

*For implementation details, see:*
- [Technical Architecture](./02_TECHNICAL_ARCHITECTURE.md)
- [Developer Onboarding](./04_DEVELOPER_ONBOARDING.md)
- [API Documentation](./05_API_DATA_FLOW.md)
