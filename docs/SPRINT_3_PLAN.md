# Sprint 3: Service Decomposition - Implementation Plan

**Status**: 📅 Ready to Start
**Estimated Duration**: 2 weeks
**Current TaskService**: 765 lines (884 lines total)
**Target**: < 300 lines coordinator

---

## 🎯 Objectives

Break down TaskService into specialized services following Single Responsibility Principle:

1. **TaskHierarchyService** - Hierarchy and tree operations
2. **TaskTagService** - Tag management and queries
3. **TaskCompletionService** - Completion logic with recurrence
4. **TaskService** - Coordinator (orchestrates other services)

---

## 📋 Task Breakdown

### Task 3.1: Extract TaskHierarchyService

**Methods to Extract** (6 methods, ~120 lines):
- `getChildTasks(parentTaskId)` - Get immediate children
- `getDescendantTasks(taskId)` - Get all descendants recursively
- `getTaskWithSubtasks(taskId)` - Load full subtree
- `_loadTaskWithSubtasks()` - Helper for recursive loading
- `_markDescendantsAsProcessed()` - Helper for processing
- Circular reference detection logic

**Responsibilities**:
- Parent-child relationship queries
- Recursive tree operations
- Subtask loading
- Hierarchy validation

### Task 3.2: Extract TaskTagService

**Methods to Extract** (8 methods, ~180 lines):
- `getTaskTags(taskId)` - Get tags for one task
- `getEffectiveTags(taskId)` - Get tags with inheritance
- `getEffectiveTagsForTasks()` - Batch tag loading
- `getEffectiveTagsForTasksWithSubtasks()` - Recursive batch
- `assignTags(taskId, tagIds)` - Assign tags
- `addTag(taskId, tagId)` - Add single tag
- `removeTag(taskId, tagId)` - Remove single tag
- `getTasksByTag(tagId)` - Query by tag

**Responsibilities**:
- Tag assignment and removal
- Tag inheritance from parent tasks
- Batch tag operations
- Tag-based queries

### Task 3.3: Extract TaskCompletionService

**Methods to Extract** (5 methods, ~140 lines):
- `completeTask(taskId, notes)` - Complete with recurrence
- `uncompleteTask(taskId)` - Uncomplete task
- `_checkParentCompletion()` - Auto-complete parent
- `getCompletionHistory(taskId)` - History for recurring
- Integration with RecurrenceService

**Responsibilities**:
- Task completion logic
- Recurrence handling
- Completion history
- Parent auto-completion
- Subtask completion validation

### Task 3.4: Refactor TaskService as Coordinator

**Remaining Methods** (~325 lines total):
- CRUD operations (delegates to repository)
- Stream operations (delegates to repository)
- Orchestration methods that use multiple services
- State management notifications

**New Structure**:
```dart
class TaskService {
  final TaskRepository _repository;
  final TaskHierarchyService _hierarchyService;
  final TaskTagService _tagService;
  final TaskCompletionService _completionService;
  final TaskStateManager _stateManager;

  // Orchestration methods that delegate
}
```

---

## 📂 File Structure

```
lib/
  service/
    task_service.dart (300 lines) ← Coordinator
    task/
      task_hierarchy_service.dart (150 lines) ← NEW
      task_tag_service.dart (220 lines) ← NEW
      task_completion_service.dart (180 lines) ← NEW

test/
  unit/
    task_hierarchy_service_test.dart ← NEW
    task_tag_service_test.dart ← NEW
    task_completion_service_test.dart ← NEW
```

---

## 🎯 Success Criteria

- [ ] TaskService < 300 lines
- [ ] All extracted services have single responsibility
- [ ] All existing functionality preserved
- [ ] Tests for each new service
- [ ] Zero compilation errors
- [ ] App still works correctly

---

## 📝 Implementation Order

1. **TaskHierarchyService** (simplest, no external dependencies)
2. **TaskTagService** (depends on hierarchy for recursive tags)
3. **TaskCompletionService** (depends on hierarchy and recurrence)
4. **Refactor TaskService** (update to use all new services)

---

## 🔄 Dependencies Between Services

```
TaskService (Coordinator)
  ├─> TaskRepository (data access)
  ├─> TaskHierarchyService
  │     └─> TaskRepository
  ├─> TaskTagService
  │     ├─> TagService
  │     └─> TaskHierarchyService (for recursive tags)
  ├─> TaskCompletionService
  │     ├─> TaskRepository
  │     ├─> RecurrenceService
  │     └─> TaskHierarchyService (for subtask checks)
  └─> TaskStateManager (notifications)
```

---

## 📊 Expected Metrics After Sprint 3

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| TaskService lines | 765 | ~300 | < 300 |
| Services count | 1 | 4 | 4 |
| Avg service size | 765 | ~210 | < 250 |
| Responsibilities per service | 8+ | 1-2 | 1-2 |
| Test files | 0 | 3 | 3 |

---

*Next Session: Start with Task 3.1 - Extract TaskHierarchyService*
