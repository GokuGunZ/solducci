import 'package:flutter/material.dart';

/// Utility functions for list rendering
///
/// These are composable helpers that can be used with ANY state management pattern:
/// - BLoC
/// - Provider
/// - Riverpod
/// - GetX
/// - setState
/// - ValueNotifier
/// - Custom granular rebuild systems
///
/// Philosophy: Provide reusable UI building blocks, not rigid abstractions

/// Build an empty state widget
///
/// Usage with any state:
/// ```dart
/// if (tasks.isEmpty) {
///   return buildEmptyState(
///     context: context,
///     icon: Icons.task_outlined,
///     title: 'No tasks',
///     subtitle: 'Add your first task',
///     action: hasFilters ? ElevatedButton(...) : null,
///   );
/// }
/// ```
Widget buildEmptyState({
  required BuildContext context,
  required IconData icon,
  required String title,
  String? subtitle,
  Widget? action,
  EdgeInsetsGeometry padding = const EdgeInsets.all(32.0),
}) {
  return Center(
    child: Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            action,
          ],
        ],
      ),
    ),
  );
}

/// Build a loading state widget
///
/// Usage:
/// ```dart
/// if (isLoading) {
///   return buildLoadingState(
///     context: context,
///     message: 'Loading tasks...',
///   );
/// }
/// ```
Widget buildLoadingState({
  required BuildContext context,
  String? message,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ],
    ),
  );
}

/// Build an error state widget
///
/// Usage:
/// ```dart
/// if (errorMessage != null) {
///   return buildErrorState(
///     context: context,
///     message: errorMessage,
///     onRetry: () => bloc.add(RetryEvent()),
///   );
/// }
/// ```
Widget buildErrorState({
  required BuildContext context,
  required String message,
  VoidCallback? onRetry,
  EdgeInsetsGeometry padding = const EdgeInsets.all(32.0),
}) {
  return Center(
    child: Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Errore nel caricamento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Get appropriate empty state icon based on context
IconData getEmptyStateIcon({
  required bool hasFilters,
  required bool showCompleted,
}) {
  if (hasFilters) return Icons.filter_alt_off;
  if (!showCompleted) return Icons.check_circle_outline;
  return Icons.inbox_outlined;
}

/// Get appropriate empty state title based on context
String getEmptyStateTitle({
  required bool hasFilters,
  required bool showCompleted,
  String defaultTitle = 'Nessun elemento',
}) {
  if (hasFilters) return 'Nessun elemento trovato';
  if (!showCompleted) return 'Nessun elemento in sospeso';
  return defaultTitle;
}

/// Get appropriate empty state subtitle based on context
String? getEmptyStateSubtitle({
  required bool hasFilters,
  required bool showCompleted,
  String? defaultSubtitle,
}) {
  if (hasFilters) return 'Prova a modificare i filtri di ricerca';
  if (!showCompleted) return 'Tutti gli elementi sono stati completati!';
  return defaultSubtitle;
}
