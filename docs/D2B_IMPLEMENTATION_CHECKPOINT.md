# Step D.2b Implementation Checkpoint

**Status**: Ready to implement
**File**: `lib/views/documents/all_tasks_view.dart`
**Lines**: 1025 total
**Estimated Time**: 30 minutes

---

## Exact Changes Required

### Change 1: Add Imports (Lines 0-15)

**ADD after line 1**:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
```

**ADD after line 9**:
```dart
import 'package:solducci/blocs/task_list/task_list_bloc_export.dart';
import 'package:solducci/core/di/service_locator.dart';
```

### Change 2: Transform AllTasksView (Lines 26-42)

**REPLACE**:
```dart
class AllTasksView extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;

  const AllTasksView({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
  });

  @override
  State<AllTasksView> createState() => _AllTasksViewState();
}
```

**WITH**:
```dart
class AllTasksView extends StatelessWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;

  const AllTasksView({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<TaskListBloc>();
        bloc.add(TaskListLoadRequested(document.id));
        return bloc;
      },
      child: _AllTasksViewContent(
        document: document,
        showAllPropertiesNotifier: showAllPropertiesNotifier,
        onInlineCreationCallbackChanged: onInlineCreationCallbackChanged,
        availableTags: availableTags,
      ),
    );
  }
}
```

### Change 3: Rename State Class (Line 44)

**REPLACE**:
```dart
class _AllTasksViewState extends State<AllTasksView>
    with AutomaticKeepAliveClientMixin {
```

**WITH**:
```dart
// New wrapper widget for content
class _AllTasksViewContent extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;

  const _AllTasksViewContent({
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
  });

  @override
  State<_AllTasksViewContent> createState() => _AllTasksViewContentState();
}

class _AllTasksViewContentState extends State<_AllTasksViewContent>
    with AutomaticKeepAliveClientMixin {
```

### Change 4: Update widget.document References

Throughout the file, ALL instances of `widget.document` remain the same (accessing from parent widget).

---

## Verification Steps

After making these changes:

1. **Compile Check**:
   ```bash
   flutter analyze lib/views/documents/all_tasks_view.dart
   ```

2. **Expected Result**:
   - Should compile successfully
   - May have warnings about unused variables (will be cleaned up in next steps)
   - App should still run using old stream system

3. **Manual Test**:
   - Open app
   - Navigate to a document
   - Verify tasks still load (using old stream, BLoC not yet used)

---

## What This Achieves

✅ BlocProvider wraps the view
✅ TaskListBloc is created and initialized
✅ TaskListLoadRequested event is dispatched
✅ App still works (old stream system still active)
✅ Ready for Step D.2c (replace StreamBuilder)

---

## Rollback if Needed

If issues arise, restore from git:
```bash
git checkout lib/views/documents/all_tasks_view.dart
```

---

**Next**: Proceed to Step D.2c in migration guide
