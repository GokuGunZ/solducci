# Sprint 4: Advanced Testing - Implementation Plan

**Status**: 📅 Ready to Start
**Estimated Duration**: 1-2 sessions
**Focus**: Unit tests for specialized services

---

## 🎯 Objectives

Create comprehensive unit tests for the specialized services extracted in Sprint 3:

1. **TaskHierarchyService Tests** - Hierarchy operations
2. **TaskTagService Tests** - Tag management
3. **TaskCompletionService Tests** - Completion logic

---

## 📋 Task Breakdown

### Task 4.1: TaskHierarchyService Tests

**File**: `test/unit/task_hierarchy_service_test.dart`

**Test Groups**:
1. **getTaskWithSubtasks** (3-4 tests)
   - Should return null for non-existent task
   - Should return task with subtasks loaded
   - Should delegate to repository correctly

2. **loadTaskWithSubtasks** (5-6 tests)
   - Should load task with filtered subtasks
   - Should filter out completed tasks when includeCompleted=false
   - Should include completed tasks when includeCompleted=true
   - Should handle tasks with no subtasks
   - Should work recursively for nested subtasks

3. **validateParentChange** (4-5 tests)
   - Should return true for null parent
   - Should return true for valid parent (not a descendant)
   - Should return false for direct child as parent
   - Should return false for indirect descendant as parent
   - Should handle deep hierarchies

4. **markDescendantsAsProcessed** (2-3 tests)
   - Should mark all descendants in set
   - Should handle task with no subtasks
   - Should work recursively

**Estimated**: 14-18 tests

---

### Task 4.2: TaskTagService Tests

**File**: `test/unit/task_tag_service_test.dart`

**Test Groups**:
1. **getTaskTags** (2-3 tests)
   - Should return tags for a task
   - Should return empty list if no tags
   - Should handle errors gracefully

2. **getEffectiveTags** (4-5 tests)
   - Should return own tags only (no parent)
   - Should return own tags + parent tags
   - Should handle recursive inheritance
   - Should avoid duplicate tags
   - Should handle task with no tags

3. **getEffectiveTagsForTasks** (3-4 tests)
   - Should batch load tags for multiple tasks
   - Should return empty map for empty input
   - Should handle tasks with no tags
   - Should optimize with single query

4. **assignTags/addTag/removeTag** (6-7 tests)
   - assignTags: Should replace all tags
   - assignTags: Should clear tags if empty list
   - assignTags: Should trigger state update
   - addTag: Should add single tag
   - addTag: Should trigger state update
   - removeTag: Should remove single tag
   - removeTag: Should trigger state update

5. **getTasksByTag** (3-4 tests)
   - Should return tasks with specific tag
   - Should include/exclude completed based on flag
   - Should load subtasks correctly
   - Should handle tag with no tasks

**Estimated**: 18-23 tests

---

### Task 4.3: TaskCompletionService Tests

**File**: `test/unit/task_completion_service_test.dart`

**Test Groups**:
1. **completeTask** (6-7 tests)
   - Should mark non-recurring task as completed
   - Should add recurring task to history and reset
   - Should throw if task has incomplete subtasks
   - Should throw if task not found
   - Should check parent completion after completion
   - Should calculate next occurrence for recurring
   - Should handle task with no recurrence

2. **uncompleteTask** (3-4 tests)
   - Should set task back to pending
   - Should recursively uncomplete parent if completed
   - Should handle task with no parent
   - Should update timestamp

3. **checkParentCompletion** (4-5 tests)
   - Should complete parent if all subtasks completed
   - Should not complete parent if any subtask incomplete
   - Should handle parent with no subtasks
   - Should handle non-existent parent
   - Should not complete already completed parent

4. **getCompletionHistory** (2-3 tests)
   - Should return completion history ordered by date
   - Should return empty list if no history
   - Should handle errors gracefully

**Estimated**: 15-19 tests

---

## 🧪 Testing Strategy

### Mock Dependencies

Each service will need mocked dependencies:

```dart
// TaskHierarchyService
- Mock TaskRepository
- Mock childrenFetcher callback
- Mock descendantsFetcher callback

// TaskTagService
- Mock TagService
- Mock TaskHierarchyService
- Mock TaskStateManager
- Mock taskFetcher callback
- Mock childrenFetcher callback

// TaskCompletionService
- Mock taskFetcher callback
- Mock childrenFetcher callback
- Mock recurrenceFetcher callback
- Mock parentCompletionChecker callback
- Mock uncompleteParent callback
```

### Test Utilities

Create test helpers for common scenarios:
- Mock task builders with various configurations
- Mock tag builders
- Mock recurrence patterns
- Callback function mocks

---

## 📊 Success Criteria

- [ ] TaskHierarchyService: 14-18 tests passing
- [ ] TaskTagService: 18-23 tests passing
- [ ] TaskCompletionService: 15-19 tests passing
- [ ] Total new tests: 47-60 tests
- [ ] All tests passing (existing + new)
- [ ] Code coverage > 80% for specialized services
- [ ] Zero compilation errors

---

## 📝 Implementation Order

1. **TaskHierarchyService Tests** (simplest, fewest dependencies)
2. **TaskCompletionService Tests** (moderate complexity)
3. **TaskTagService Tests** (most complex, most dependencies)

---

## 🎯 Expected Metrics After Sprint 4

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Total tests | 110 | 157-170 | 150+ |
| Specialized service tests | 0 | 47-60 | 45+ |
| Code coverage (services) | ~40% | ~80% | 80% |
| Test execution time | ~3s | ~4-5s | < 10s |

---

*Next Session: Start with Task 4.1 - TaskHierarchyService Tests*
