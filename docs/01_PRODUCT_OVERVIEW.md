# Solducci - Product Overview

> **Audience**: Non-technical stakeholders, product managers, business team
> **Level**: High-level, business-focused

---

## What is Solducci?

Solducci is a **collaborative expense tracking application** designed to simplify how people manage shared finances. Whether you're splitting rent with roommates, managing expenses with your partner, or tracking costs for a group trip, Solducci makes it easy to see who paid what and who owes whom.

### The Problem We Solve

Managing shared expenses is frustrating:
- 💸 **Manual calculations** are time-consuming and error-prone
- 📱 **Spreadsheets** don't sync in real-time and require constant updates
- 🤝 **Trust issues** arise from unclear financial records
- 😰 **Awkward conversations** about money happen too often

### Our Solution

Solducci provides:
- ✅ **Instant synchronization** across all devices
- ✅ **Automatic debt calculations** - no more manual math
- ✅ **Transparent records** everyone can see
- ✅ **Flexible splitting options** for different scenarios
- ✅ **Beautiful, intuitive interface** anyone can use

---

## Who Is It For?

### Primary Users
1. **Couples** sharing household expenses
2. **Roommates** splitting rent, utilities, and groceries
3. **Travel groups** tracking shared vacation costs
4. **Office teams** managing team expenses
5. **Families** coordinating household spending

### User Personas

**👫 Marco & Sofia (Couple)**
- Live together, share all household costs
- Want to avoid awkward money discussions
- Need automatic tracking of who's paid more

**🏠 University Roommates**
- 3-4 people sharing an apartment
- Split rent, utilities, and groceries differently
- Need flexibility in how expenses are divided

**✈️ Travel Group**
- Friends on a vacation together
- Different people pay for different things
- Want quick settlement at the end of the trip

---

## Core Features

### 1. Personal & Group Expenses
- Track your own personal spending
- Create groups for shared expenses
- Switch between personal and group views instantly

### 2. Flexible Expense Splitting
Choose how to divide each expense:

| Split Type | Description | Use Case |
|------------|-------------|----------|
| **Equal Split** | Divided equally among everyone | Shared dinner |
| **Custom Split** | Specify exact amounts per person | Rent + utilities |
| **Lend** | One person advances money, others reimburse | Someone pays upfront |
| **Offer** | One person gifts the expense | Birthday treat |

### 3. Automatic Balance Tracking
- See at a glance who owes money to whom
- Real-time updates as new expenses are added
- Clear visualization of debts and credits

### 4. Smart Organization
- **Categories**: Rent, Food, Utilities, Household, Dining, Entertainment, Other
- **Monthly view**: See expenses grouped by month
- **Timeline**: Chronological view of all transactions
- **Analytics**: Breakdown by category with percentages

### 5. Group Management
- Create unlimited groups
- Invite members via email
- Manage member roles (admin/member)
- View pending invitations

---

## How It Works

### Getting Started (3 Steps)

```
1. Sign Up → 2. Create or Join Group → 3. Start Adding Expenses
```

### Adding an Expense

1. **Enter details**: Amount, description, date, category
2. **Select who paid**: Which group member paid
3. **Choose split type**: Equal, custom, lend, or offer
4. **Save**: Balances update automatically

### Viewing Your Balance

The app automatically calculates:
- How much you've paid
- How much you've spent
- How much you owe or are owed
- **Net balance** with each person

---

## Technology & Platform Support

### Available On
- 📱 **iOS** - iPhone and iPad
- 🤖 **Android** - All Android devices
- 🌐 **Web** - Any modern web browser
- 💻 **Desktop** - macOS, Windows, Linux

### Data & Security
- 🔒 **Secure authentication** with email/password
- ☁️ **Cloud-based** - access from anywhere
- 🔄 **Real-time sync** - changes appear instantly
- 🗄️ **Reliable database** - powered by Supabase (PostgreSQL)
- 🔐 **Privacy-first** - only group members see group data

---

## Product Status

### Current Version: **1.0.0**

#### ✅ What's Available Now (MVP Complete)
- User authentication (signup/login)
- Personal expense tracking
- Group creation and management
- Group member invitations
- Expense splitting (4 types)
- Balance calculations
- Multiple analytics views
- Real-time synchronization
- Multi-platform support

#### 🚧 In Development (Phase 3B-3D)
- Enhanced UI for context switching
- Additional group management features
- Improved expense form workflows

#### 📋 Future Roadmap
- **Recurring expenses** - Automatic monthly bills
- **Advanced charts** - Visual spending trends
- **Notes system** - Add context to expenses
- **Export functionality** - Download reports
- **Receipt photos** - Attach images to expenses
- **Multi-currency** - Support for different currencies
- **Budget limits** - Set spending caps per category

---

## Business Model & Goals

### Current Focus
- Building a **robust MVP** with essential features
- Gathering **user feedback** from early adopters
- Establishing **best practices** for team collaboration

### Target Metrics
- **User satisfaction**: Ease of use and reliability
- **Engagement**: Daily/weekly active users
- **Group creation rate**: Number of groups per user
- **Expense frequency**: Transactions per group per week

### Competitive Advantages
1. **Real-time sync** - Instant updates across devices
2. **Flexible splitting** - 4 different split types
3. **Context switching** - Easy toggle between personal and group
4. **Multi-platform** - Works everywhere
5. **Open development** - Transparent roadmap and progress

---

## Use Case Examples

### Example 1: Roommate Scenario

**Group**: "Via Roma 42 Apartment"
**Members**: Alice, Bob, Charlie

**Monthly Expenses**:
- 🏠 Rent (€1200) - Paid by Alice, split equally → €400 each
- 💡 Utilities (€90) - Paid by Bob, split equally → €30 each
- 🛒 Groceries (€150) - Paid by Charlie, split equally → €50 each

**Result**: App automatically shows:
- Alice is owed €800 (paid €1200, owes €80)
- Bob is owed €60 (paid €90, owes €430)
- Charlie owes €260 (paid €150, owes €430)

### Example 2: Couple Scenario

**Group**: "Marco & Sofia"
**Members**: Marco, Sofia

**This Month**:
- Marco paid €500 for rent
- Sofia paid €200 for groceries
- Marco paid €50 for dinner

**Result**:
- Total: €750
- Each should pay: €375
- Marco paid: €550, owed: €375 → Marco is owed €175
- Sofia paid: €200, owed: €375 → Sofia owes €175

---

## Success Stories (Future)

> "Solducci completely eliminated awkward money conversations with my roommates. Now we just add expenses as they happen and settle up at the end of the month." - *Future user testimonial*

> "Finally, an app that actually syncs in real-time. No more 'did you update the spreadsheet?' messages!" - *Future user testimonial*

---

## Getting Help

### For Product Questions
- Review the [Feature Documentation](./02_FEATURE_GUIDE.md)
- Check the [User Guide](./SETUP_GUIDE.md)

### For Development
- See [Technical Architecture](./03_TECHNICAL_ARCHITECTURE.md)
- Read [Developer Onboarding](./04_DEVELOPER_ONBOARDING.md)

### For Status Updates
- Review [Current Status](./CURRENT_STATUS.md)
- Check [Changelog](./CHANGELOG.md)

---

## Contact & Feedback

This is a **team learning project** - we welcome questions, suggestions, and feedback!

**Project Repository**: [Link to your GitHub/GitLab]
**Documentation**: `/docs` folder in the repository
**Issue Tracking**: [Link to your issue tracker]

---

*Last updated: November 2024*
*Version: 1.0.0*
