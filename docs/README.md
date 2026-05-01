# 📚 Solducci Documentation

> **Comprehensive documentation for the Solducci expense tracking and task management app**

---

## 🎯 Quick Navigation

### For Users
- [Product Overview](./01_PRODUCT_OVERVIEW.md) - What is Solducci and how to use it

### For Product Managers
- [Product Overview](./01_PRODUCT_OVERVIEW.md) - Business value and features
- [Feature Guide](./03_FEATURE_GUIDE.md) - Detailed feature specifications
- [Documents Feature PM Guide](./PM_DOCUMENTS_FEATURE.md) - Task management feature

### For Developers
- [Developer Onboarding](./04_DEVELOPER_ONBOARDING.md) - Setup and getting started
- [Technical Architecture](./02_TECHNICAL_ARCHITECTURE.md) - System architecture
- [API & Data Flow](./05_API_DATA_FLOW.md) - API reference

### For Senior Developers & Architects
- [Senior Dev Architecture - Documents](./SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md) - Deep dive into Documents feature architecture
- [Component Library Architecture](./COMPONENT_LIBRARY_ARCHITECTURE.md) - Reusable components design
- [Reusable Components Dev Guide](./REUSABLE_COMPONENTS_DEV_GUIDE.md) - How to use component library

### For Claude Agents
- [Claude Agent - Documents Guide](./CLAUDE_AGENT_DOCUMENTS_GUIDE.md) - Maintain Documents feature
- [Claude Agent - Components Guide](./REUSABLE_COMPONENTS_AGENT_GUIDE.md) - Use component library
- [Spazio Implementation Guide](./SPACE_IMPLEMENTATION_GUIDE.md) - Implement "Spazio" feature end-to-end

---

## 📂 Documentation Structure

### Core App Documentation (00-05)
These documents cover the entire Solducci application:

| Document | Audience | Purpose |
|----------|----------|---------|
| [00_DOCUMENTATION_INDEX.md](./00_DOCUMENTATION_INDEX.md) | All | Navigation hub for all docs |
| [01_PRODUCT_OVERVIEW.md](./01_PRODUCT_OVERVIEW.md) | Non-technical, PM | Product vision and features |
| [02_TECHNICAL_ARCHITECTURE.md](./02_TECHNICAL_ARCHITECTURE.md) | Developers, Architects | System design and patterns |
| [03_FEATURE_GUIDE.md](./03_FEATURE_GUIDE.md) | Developers, QA, PM | Feature specifications |
| [04_DEVELOPER_ONBOARDING.md](./04_DEVELOPER_ONBOARDING.md) | New Developers | Setup and workflow |
| [05_API_DATA_FLOW.md](./05_API_DATA_FLOW.md) | Backend Devs | API reference |

### Documents Feature Documentation
Task management feature (`/documents` section):

| Document | Audience | Purpose |
|----------|----------|---------|
| [USER_GUIDE_DOCUMENTS.md](./USER_GUIDE_DOCUMENTS.md) | End Users | How to use Documents feature |
| [PM_DOCUMENTS_FEATURE.md](./PM_DOCUMENTS_FEATURE.md) | Product Managers | Business context and metrics |
| [SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md](./SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md) | Senior Developers | Deep technical architecture |
| [CLAUDE_AGENT_DOCUMENTS_GUIDE.md](./CLAUDE_AGENT_DOCUMENTS_GUIDE.md) | AI Agents | Maintenance and extension guide |

### Reusable Components Documentation
Generic UI components library:

| Document | Audience | Purpose |
|----------|----------|---------|
| [COMPONENT_LIBRARY_ARCHITECTURE.md](./COMPONENT_LIBRARY_ARCHITECTURE.md) | Architects | Design decisions and patterns |
| [REUSABLE_COMPONENTS_DEV_GUIDE.md](./REUSABLE_COMPONENTS_DEV_GUIDE.md) | Developers | How to use components |
| [REUSABLE_COMPONENTS_AGENT_GUIDE.md](./REUSABLE_COMPONENTS_AGENT_GUIDE.md) | AI Agents | Component usage for agents |

### UI Showcase Documentation
Developer tool for component gallery:

| Document | Audience | Purpose |
|----------|----------|---------|
| [UI_SHOWCASE_GUIDE.md](./UI_SHOWCASE_GUIDE.md) | Developers, Designers | Showcase feature documentation |

### Spazio Feature Documentation
Nuova 5a tab — contenuti condivisi (Task, Note, Asterischi, Risorse, Dispensa):

| Document | Audience | Purpose |
|----------|----------|---------|
| [SPACE_PRODUCT_REQUIREMENTS.md](./SPACE_PRODUCT_REQUIREMENTS.md) | PM, Designers | Vision, requisiti funzionali, regole di accesso |
| [SPACE_TECHNICAL_DESIGN.md](./SPACE_TECHNICAL_DESIGN.md) | Senior Developers | DB schema, modelli, services, routing, RLS |
| [SPACE_IMPLEMENTATION_GUIDE.md](./SPACE_IMPLEMENTATION_GUIDE.md) | Developers, AI Agents | Guida step-by-step fase per fase |

### Legacy & Utility Documentation
Historical and setup documents:

| Document | Purpose |
|----------|---------|
| [CHANGELOG.md](./CHANGELOG.md) | Version history |
| [README_MULTIUSER.md](./README_MULTIUSER.md) | Multi-user feature docs |
| [SETUP_GUIDE.md](./SETUP_GUIDE.md) | Environment setup |
| [BALANCE_CALCULATION.md](./BALANCE_CALCULATION.md) | Balance logic details |
| [MIGRATION_INSTRUCTIONS.md](./MIGRATION_INSTRUCTIONS.md) | Database migrations |
| [APPLY_MIGRATIONS.md](./APPLY_MIGRATIONS.md) | How to run migrations |
| [DATABASE_MIGRATION_STATUS.md](./DATABASE_MIGRATION_STATUS.md) | Migration tracking |

---

## 🚀 Getting Started

### I'm a new developer
1. Read [Product Overview](./01_PRODUCT_OVERVIEW.md) to understand what you're building
2. Follow [Developer Onboarding](./04_DEVELOPER_ONBOARDING.md) to setup your environment
3. Review [Technical Architecture](./02_TECHNICAL_ARCHITECTURE.md) to understand the system
4. Check [Feature Guide](./03_FEATURE_GUIDE.md) for specific features

### I'm working on Documents feature
1. Read [User Guide](./USER_GUIDE_DOCUMENTS.md) to understand user perspective
2. Review [PM Guide](./PM_DOCUMENTS_FEATURE.md) for business context
3. Study [Senior Dev Architecture](./SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md) for implementation details
4. Use [Claude Agent Guide](./CLAUDE_AGENT_DOCUMENTS_GUIDE.md) as reference

### I need to use reusable components
1. Check [Component Library Architecture](./COMPONENT_LIBRARY_ARCHITECTURE.md) for design rationale
2. Follow [Dev Guide](./REUSABLE_COMPONENTS_DEV_GUIDE.md) for usage examples
3. Reference [Agent Guide](./REUSABLE_COMPONENTS_AGENT_GUIDE.md) for quick lookup

### I'm a Claude Agent
1. Identify task type (Documents feature, components, general)
2. Use appropriate agent guide:
   - [Documents Feature](./CLAUDE_AGENT_DOCUMENTS_GUIDE.md)
   - [Components](./REUSABLE_COMPONENTS_AGENT_GUIDE.md)
3. Follow decision trees and checklists
4. Reference architecture docs as needed

---

## 🎨 App Features Overview

### Expense Tracking (Main Feature)
- Personal and group expense management
- Multiple split types (equal, custom, lend, offer)
- Automatic balance calculations
- Real-time synchronization across devices
- Multi-group support

**Documentation**: See [01_PRODUCT_OVERVIEW.md](./01_PRODUCT_OVERVIEW.md)

### Documents (Task Management)
- Task creation and organization
- Advanced filtering (priority, status, size, date, tags)
- Drag & drop reordering
- Tag-based categorization
- Completed tasks tracking

**Documentation**: See [USER_GUIDE_DOCUMENTS.md](./USER_GUIDE_DOCUMENTS.md)

### Reusable Components
- Generic filterable list views
- Category scroll bars
- Highlight animations
- Reorderable list bases

**Documentation**: See [REUSABLE_COMPONENTS_DEV_GUIDE.md](./REUSABLE_COMPONENTS_DEV_GUIDE.md)

### UI Showcase
- Component gallery
- Design system documentation
- Interactive demos
- Developer tool (test@te.st only)

**Documentation**: See [UI_SHOWCASE_GUIDE.md](./UI_SHOWCASE_GUIDE.md)

---

## 📊 Tech Stack

- **Frontend**: Flutter 3.x (Dart)
- **Backend**: Supabase (PostgreSQL)
- **State Management**: BLoC pattern
- **Real-time**: Supabase Realtime (WebSocket)
- **Authentication**: Supabase Auth (JWT)
- **Navigation**: GoRouter

**Details**: See [02_TECHNICAL_ARCHITECTURE.md](./02_TECHNICAL_ARCHITECTURE.md)

---

## 🏗️ Architecture Highlights

### State Management
- **Unified BLoC Pattern**: Single source of truth per feature
- **Granular Rebuilds**: ValueListenableBuilder for performance
- **Stream-based**: Real-time data updates

### Component Architecture
- **Compositional**: Small, reusable components
- **Generic-first**: Type-parameterized for reusability
- **SOLID principles**: Clear separation of concerns

### Performance
- **Optimistic Updates**: Immediate UI feedback
- **Tag Preloading**: Batch queries to avoid N+1
- **Lazy Loading**: Load on-demand when needed
- **Memoization**: Cache expensive computations

**Details**: See [SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md](./SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md)

---

## 🧪 Testing

- **Unit Tests**: Business logic and services
- **Widget Tests**: UI component rendering
- **Integration Tests**: End-to-end flows
- **BLoC Tests**: State management logic

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/blocs/unified_task_list_bloc_test.dart
```

**Details**: See [04_DEVELOPER_ONBOARDING.md](./04_DEVELOPER_ONBOARDING.md)

---

## 📝 Contributing

### Documentation Standards
- ✅ Update docs when code changes
- ✅ Use markdown for all documentation
- ✅ Include code examples
- ✅ Add diagrams for complex flows
- ✅ Specify audience for each document

### When to Update Docs

| Change Type | Update Required |
|-------------|-----------------|
| New feature | Feature Guide, Architecture docs |
| New component | Component library docs, Showcase |
| API change | API & Data Flow doc |
| Architecture change | Technical Architecture, Senior Dev docs |
| Setup change | Developer Onboarding |

---

## 🔍 Finding Documentation

### By Feature
- **Expenses**: [01_PRODUCT_OVERVIEW.md](./01_PRODUCT_OVERVIEW.md), [03_FEATURE_GUIDE.md](./03_FEATURE_GUIDE.md)
- **Groups**: [README_MULTIUSER.md](./README_MULTIUSER.md)
- **Documents/Tasks**: [USER_GUIDE_DOCUMENTS.md](./USER_GUIDE_DOCUMENTS.md)
- **Components**: [REUSABLE_COMPONENTS_DEV_GUIDE.md](./REUSABLE_COMPONENTS_DEV_GUIDE.md)

### By Technology
- **Flutter/Dart**: [02_TECHNICAL_ARCHITECTURE.md](./02_TECHNICAL_ARCHITECTURE.md)
- **Supabase**: [05_API_DATA_FLOW.md](./05_API_DATA_FLOW.md)
- **BLoC**: [SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md](./SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md)

### By Task
- **Setup Environment**: [04_DEVELOPER_ONBOARDING.md](./04_DEVELOPER_ONBOARDING.md)
- **Add New Feature**: [SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md](./SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md)
- **Debug Issue**: [CLAUDE_AGENT_DOCUMENTS_GUIDE.md](./CLAUDE_AGENT_DOCUMENTS_GUIDE.md)
- **Use Component**: [REUSABLE_COMPONENTS_DEV_GUIDE.md](./REUSABLE_COMPONENTS_DEV_GUIDE.md)

---

## 📞 Getting Help

### For Questions About
- **Product/Features**: See [01_PRODUCT_OVERVIEW.md](./01_PRODUCT_OVERVIEW.md), [03_FEATURE_GUIDE.md](./03_FEATURE_GUIDE.md)
- **Technical Architecture**: See [02_TECHNICAL_ARCHITECTURE.md](./02_TECHNICAL_ARCHITECTURE.md)
- **Setup/Environment**: See [04_DEVELOPER_ONBOARDING.md](./04_DEVELOPER_ONBOARDING.md)
- **API/Database**: See [05_API_DATA_FLOW.md](./05_API_DATA_FLOW.md)

### Documentation Feedback
If you find:
- ❌ Incorrect information
- 📝 Missing documentation
- 🤔 Unclear explanations
- 💡 Improvement suggestions

Please create an issue or contact the team.

---

## 📅 Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | Jan 2025 | Complete documentation restructure |
| | | - Added Documents feature docs |
| | | - Added Component library docs |
| | | - Added UI Showcase docs |
| | | - Removed temporary/duplicate docs |
| 1.0 | Nov 2024 | Initial comprehensive docs |
| | | - Product overview |
| | | - Technical architecture |
| | | - Developer onboarding |

---

## 🗂️ Folder Structure

```
docs/
├── README.md (this file)              # Documentation hub
├── 00-05_*.md                         # Core app documentation
├── *_DOCUMENTS_*.md                   # Documents feature docs
├── REUSABLE_COMPONENTS_*.md           # Component library docs
├── UI_SHOWCASE_GUIDE.md               # Showcase documentation
├── COMPONENT_LIBRARY_ARCHITECTURE.md  # Component design
├── CHANGELOG.md                       # Version history
├── *_GUIDE.md                         # Setup and usage guides
├── analysis/                          # Code analysis notes
└── archive/                           # Historical documentation
```

---

**Last Updated**: January 2025
**Documentation Version**: 2.0
**App Version**: 1.0.0

---

**Happy Coding!** 🚀
