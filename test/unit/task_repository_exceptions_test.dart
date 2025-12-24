import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/domain/repositories/task_repository.dart';

/// Test suite for TaskRepository exceptions
///
/// Tests the custom exception classes used by the repository pattern.
/// These tests don't require Supabase initialization.
void main() {
  group('RepositoryException', () {
    test('should have message and optional error', () {
      // Arrange
      final originalError = Exception('Original error');
      final stackTrace = StackTrace.current;

      // Act
      final exception = RepositoryException(
        'Test error',
        originalError,
        stackTrace,
      );

      // Assert
      expect(exception.message, equals('Test error'));
      expect(exception.originalError, equals(originalError));
      expect(exception.stackTrace, equals(stackTrace));
      expect(exception.toString(), contains('RepositoryException: Test error'));
    });

    test('should work without optional parameters', () {
      // Arrange & Act
      final exception = RepositoryException('Simple error');

      // Assert
      expect(exception.message, equals('Simple error'));
      expect(exception.originalError, isNull);
      expect(exception.stackTrace, isNull);
    });
  });

  group('NotFoundException', () {
    test('should extend RepositoryException', () {
      // Arrange & Act
      final exception = NotFoundException('Task not found');

      // Assert
      expect(exception, isA<RepositoryException>());
      expect(exception.message, equals('Task not found'));
      expect(exception.toString(), contains('NotFoundException: Task not found'));
    });

    test('should include original error and stack trace', () {
      // Arrange
      final originalError = Exception('DB error');
      final stackTrace = StackTrace.current;

      // Act
      final exception = NotFoundException(
        'Task not found',
        originalError,
        stackTrace,
      );

      // Assert
      expect(exception.originalError, equals(originalError));
      expect(exception.stackTrace, equals(stackTrace));
    });

    test('should have clear message for specific task', () {
      // Arrange & Act
      final exception = NotFoundException('Task with ID abc-123 not found');

      // Assert
      expect(exception.toString(), contains('NotFoundException'));
      expect(exception.toString(), contains('abc-123'));
    });
  });

  group('ValidationException', () {
    test('should include field errors', () {
      // Arrange & Act
      final exception = ValidationException(
        'Validation failed',
        fieldErrors: {
          'title': 'Title is required',
          'status': 'Invalid status',
        },
      );

      // Assert
      expect(exception, isA<RepositoryException>());
      expect(exception.message, equals('Validation failed'));
      expect(exception.fieldErrors?['title'], equals('Title is required'));
      expect(exception.fieldErrors?['status'], equals('Invalid status'));
      expect(exception.toString(), contains('Field errors:'));
    });

    test('should work without field errors', () {
      // Arrange & Act
      final exception = ValidationException('Simple validation error');

      // Assert
      expect(exception.message, equals('Simple validation error'));
      expect(exception.fieldErrors, isNull);
      expect(exception.toString(), equals('ValidationException: Simple validation error'));
    });

    test('should format message with multiple field errors', () {
      // Arrange
      final exception = ValidationException(
        'Task validation failed',
        fieldErrors: {
          'title': 'Title is required',
          'documentId': 'Document ID is required',
          'status': 'Invalid status value',
        },
      );

      // Act
      final message = exception.toString();

      // Assert
      expect(message, contains('ValidationException: Task validation failed'));
      expect(message, contains('Field errors:'));
      expect(message, contains('title'));
      expect(message, contains('documentId'));
      expect(message, contains('status'));
    });

    test('should handle empty field errors map', () {
      // Arrange & Act
      final exception = ValidationException(
        'Validation error',
        fieldErrors: {},
      );

      // Assert
      expect(exception.fieldErrors, isNotNull);
      expect(exception.fieldErrors!.isEmpty, isTrue);
      // Should not show "Field errors:" section for empty map
      expect(
        exception.toString(),
        equals('ValidationException: Validation error'),
      );
    });
  });

  group('NetworkException', () {
    test('should include status code', () {
      // Arrange & Act
      final exception = NetworkException(
        'Connection failed',
        statusCode: 500,
      );

      // Assert
      expect(exception, isA<RepositoryException>());
      expect(exception.message, equals('Connection failed'));
      expect(exception.statusCode, equals(500));
      expect(exception.toString(), contains('HTTP 500'));
    });

    test('should work without status code', () {
      // Arrange & Act
      final exception = NetworkException('Network error');

      // Assert
      expect(exception.statusCode, isNull);
      expect(exception.toString(), equals('NetworkException: Network error'));
    });

    test('should format message with different status codes', () {
      // Arrange & Act
      final testCases = [
        (statusCode: 400, message: 'Bad Request'),
        (statusCode: 401, message: 'Unauthorized'),
        (statusCode: 403, message: 'Forbidden'),
        (statusCode: 404, message: 'Not Found'),
        (statusCode: 500, message: 'Internal Server Error'),
        (statusCode: 503, message: 'Service Unavailable'),
      ];

      // Assert
      for (final testCase in testCases) {
        final exception = NetworkException(
          testCase.message,
          statusCode: testCase.statusCode,
        );

        expect(exception.statusCode, equals(testCase.statusCode));
        expect(exception.toString(), contains('HTTP ${testCase.statusCode}'));
        expect(exception.toString(), contains(testCase.message));
      }
    });

    test('should include original error and stack trace', () {
      // Arrange
      final originalError = Exception('Socket error');
      final stackTrace = StackTrace.current;

      // Act
      final exception = NetworkException(
        'Failed to connect',
        statusCode: 503,
        error: originalError,
        stackTrace: stackTrace,
      );

      // Assert
      expect(exception.originalError, equals(originalError));
      expect(exception.stackTrace, equals(stackTrace));
    });
  });

  group('Exception Hierarchy', () {
    test('all custom exceptions should extend RepositoryException', () {
      // Arrange & Act
      final notFoundEx = NotFoundException('Not found');
      final validationEx = ValidationException('Invalid');
      final networkEx = NetworkException('Network error');

      // Assert
      expect(notFoundEx, isA<RepositoryException>());
      expect(validationEx, isA<RepositoryException>());
      expect(networkEx, isA<RepositoryException>());
    });

    test('all custom exceptions should implement Exception', () {
      // Arrange & Act
      final repositoryEx = RepositoryException('Error');
      final notFoundEx = NotFoundException('Not found');
      final validationEx = ValidationException('Invalid');
      final networkEx = NetworkException('Network error');

      // Assert
      expect(repositoryEx, isA<Exception>());
      expect(notFoundEx, isA<Exception>());
      expect(validationEx, isA<Exception>());
      expect(networkEx, isA<Exception>());
    });
  });

  group('Exception Use Cases', () {
    test('should represent task not found scenario', () {
      // Arrange
      const taskId = 'task-abc-123';

      // Act
      final exception = NotFoundException(
        'Task with ID $taskId not found',
      );

      // Assert
      expect(exception.message, contains(taskId));
      expect(exception.toString(), contains('NotFoundException'));
    });

    test('should represent validation failure with multiple fields', () {
      // Arrange & Act
      final exception = ValidationException(
        'Task creation failed due to validation errors',
        fieldErrors: {
          'title': 'Title cannot be empty',
          'documentId': 'Document does not exist',
          'dueDate': 'Due date must be in the future',
        },
      );

      // Assert
      expect(exception.fieldErrors?.length, equals(3));
      expect(exception.message, contains('validation'));
    });

    test('should represent network timeout scenario', () {
      // Arrange & Act
      final exception = NetworkException(
        'Request timed out after 30 seconds',
        statusCode: 408,
      );

      // Assert
      expect(exception.statusCode, equals(408));
      expect(exception.message, contains('timed out'));
    });

    test('should represent database connection failure', () {
      // Arrange
      final originalError = Exception('Connection pool exhausted');

      // Act
      final exception = NetworkException(
        'Failed to connect to database',
        error: originalError,
      );

      // Assert
      expect(exception.originalError, isNotNull);
      expect(exception.message, contains('database'));
    });

    test('should represent circular reference validation', () {
      // Arrange & Act
      final exception = ValidationException(
        'Cannot set parent to a descendant task (circular reference)',
        fieldErrors: {
          'parentTaskId': 'Would create circular reference',
        },
      );

      // Assert
      expect(exception.fieldErrors?['parentTaskId'], isNotNull);
      expect(exception.message, contains('circular'));
    });
  });
}
