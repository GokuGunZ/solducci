import 'package:get_it/get_it.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/service/recurrence_service.dart';
import 'package:solducci/service/task_order_persistence_service.dart';
import 'package:solducci/service/task/task_hierarchy_service.dart';
import 'package:solducci/service/task/task_tag_service.dart';
import 'package:solducci/service/task/task_completion_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/domain/repositories/task_completion_repository.dart';
import 'package:solducci/domain/repositories/task_tag_repository.dart';
import 'package:solducci/data/repositories/supabase_task_repository.dart';
import 'package:solducci/data/repositories/supabase_task_completion_repository.dart';
import 'package:solducci/data/repositories/supabase_task_tag_repository.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Setup all services and dependencies
///
/// This should be called once at app startup, before runApp().
/// Registers all services as lazy singletons for dependency injection.
///
/// Usage:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await setupServiceLocator();
///   runApp(MyApp());
/// }
/// ```
Future<void> setupServiceLocator() async {
  AppLogger.info('Setting up service locator...');

  // Core infrastructure
  getIt.registerLazySingleton<TaskStateManager>(() => TaskStateManager());

  // Repositories (Data access layer)
  getIt.registerLazySingleton<TaskRepository>(() => SupabaseTaskRepository());
  getIt.registerLazySingleton<TaskCompletionRepository>(
    () => SupabaseTaskCompletionRepository(),
  );
  getIt.registerLazySingleton<TaskTagRepository>(
    () => SupabaseTaskTagRepository(),
  );

  // Specialized Task Services
  getIt.registerLazySingleton<TaskHierarchyService>(
    () => TaskHierarchyService(getIt<TaskRepository>()),
  );
  getIt.registerLazySingleton<TaskTagService>(
    () => TaskTagService(
      getIt<TaskTagRepository>(),
      getIt<TaskHierarchyService>(),
      getIt<TaskStateManager>(),
    ),
  );
  getIt.registerLazySingleton<TaskCompletionService>(
    () => TaskCompletionService(getIt<TaskCompletionRepository>()),
  );

  // Services (Singleton pattern - one instance shared across app)
  getIt.registerLazySingleton<TaskService>(() => TaskService());
  getIt.registerLazySingleton<DocumentService>(() => DocumentService());
  getIt.registerLazySingleton<TagService>(() => TagService());
  getIt.registerLazySingleton<RecurrenceService>(() => RecurrenceService());
  getIt.registerLazySingleton<TaskOrderPersistenceService>(
    () => TaskOrderPersistenceService(),
  );

  AppLogger.info('Service locator setup complete');
  AppLogger.debug('Registered services: 7, repositories: 3, specialized task services: 3');
}

/// Reset service locator (for testing)
void resetServiceLocator() {
  AppLogger.debug('Resetting service locator');
  getIt.reset();
}
