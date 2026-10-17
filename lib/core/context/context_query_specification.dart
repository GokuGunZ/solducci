import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:solducci/service/context_manager.dart';

/// Extension on [PostgrestFilterBuilder] to automatically apply systematic
/// context filtering (Personal, Group, or View) to database queries.
extension ContextQueryFilter<T> on PostgrestFilterBuilder<T> {
  /// Filters records according to the active [ExpenseContext].
  ///
  /// - **Personal Context**: matches `user_id = currentUserId` AND `group_id IS NULL`.
  /// - **Group Context**: matches `group_id = context.groupId`.
  /// - **View Context**: matches `group_id IN (context.groupIds)`, optionally with
  ///   personal records if `context.includesPersonal` is true.
  PostgrestFilterBuilder<T> filterByContext(
    ExpenseContext context, {
    String? currentUserId,
  }) {
    final uid = currentUserId ?? Supabase.instance.client.auth.currentUser?.id;

    if (context.isPersonal) {
      if (uid != null) {
        return eq('user_id', uid).isFilter('group_id', null);
      }
      return isFilter('group_id', null);
    } else if (context.isGroup) {
      final gid = context.groupId;
      if (gid != null) {
        return eq('group_id', gid);
      }
      return this;
    } else if (context.isView) {
      if (context.groupIds.isEmpty) {
        if (context.includesPersonal && uid != null) {
          return eq('user_id', uid).isFilter('group_id', null);
        }
        // Empty view filter fallback
        return eq('id', '00000000-0000-0000-0000-000000000000');
      }

      if (context.includesPersonal && uid != null) {
        final groupList = context.groupIds.join(',');
        return or('group_id.in.($groupList),and(user_id.eq.$uid,group_id.is.null)');
      } else {
        return inFilter('group_id', context.groupIds);
      }
    }

    return this;
  }
}
