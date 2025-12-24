import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/service/recurrence_service.dart';
import 'package:solducci/service/task_order_persistence_service.dart';
import 'package:solducci/utils/task_state_manager.dart';

/// Mock services for testing
class MockTaskService extends Mock implements TaskService {}
class MockDocumentService extends Mock implements DocumentService {}
class MockTagService extends Mock implements TagService {}
class MockRecurrenceService extends Mock implements RecurrenceService {}
class MockTaskOrderPersistenceService extends Mock implements TaskOrderPersistenceService {}
class MockTaskStateManager extends Mock implements TaskStateManager {}

/// Setup test service locator with mocks
void setupTestServiceLocator() {
  // Reset GetIt instance
  getIt.reset();

  // Register mock services
  getIt.registerLazySingleton<TaskService>(() => MockTaskService());
  getIt.registerLazySingleton<DocumentService>(() => MockDocumentService());
  getIt.registerLazySingleton<TagService>(() => MockTagService());
  getIt.registerLazySingleton<RecurrenceService>(() => MockRecurrenceService());
  getIt.registerLazySingleton<TaskOrderPersistenceService>(() => MockTaskOrderPersistenceService());
  getIt.registerLazySingleton<TaskStateManager>(() => MockTaskStateManager());
}

/// Cleanup test service locator
void cleanupTestServiceLocator() {
  getIt.reset();
}

/// Pump a widget with Material app wrapper
Future<void> pumpWidgetWithMaterial(
  WidgetTester tester,
  Widget widget, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: widget,
      ),
    ),
  );
}

/// Wait for all animations to complete
Future<void> pumpAndSettleWithTimeout(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await tester.pumpAndSettle(timeout);
}
