import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/service/recurrence_service.dart';

/// Mock services for testing
class MockTaskService extends Mock implements TaskService {}
class MockDocumentService extends Mock implements DocumentService {}
class MockTagService extends Mock implements TagService {}
class MockRecurrenceService extends Mock implements RecurrenceService {}

/// Setup test service locator with mocks
void setupTestServiceLocator() {
  final getIt = GetIt.instance;

  // Reset GetIt instance
  getIt.reset();

  // Register mock services
  getIt.registerLazySingleton<TaskService>(() => MockTaskService());
  getIt.registerLazySingleton<DocumentService>(() => MockDocumentService());
  getIt.registerLazySingleton<TagService>(() => MockTagService());
  getIt.registerLazySingleton<RecurrenceService>(() => MockRecurrenceService());
}

/// Cleanup test service locator
void cleanupTestServiceLocator() {
  GetIt.instance.reset();
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
