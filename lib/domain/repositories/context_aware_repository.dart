import 'package:solducci/service/context_manager.dart';

/// Contract for repositories capable of querying and observing entities
/// strictly scoped to an [ExpenseContext].
abstract interface class ContextAwareRepository<T> {
  /// Fetches all entities matching the given [context].
  Future<List<T>> getByContext(ExpenseContext context);

  /// Streams real-time changes for entities matching the given [context].
  Stream<List<T>> watchByContext(ExpenseContext context);
}
