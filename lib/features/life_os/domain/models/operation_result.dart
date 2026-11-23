/// Result wrapper that explicitly distinguishes successful operations
/// from connectivity failures or unsupported offline writes (Amendment 9).
sealed class OperationResult<T> {
  const OperationResult();

  bool get isSuccess => this is OperationSuccess<T>;
  bool get isFailure => this is OperationFailure<T>;

  T? get dataOrNull => switch (this) {
        OperationSuccess<T>(data: final d) => d,
        OperationFailure<T>() => null,
      };
}

class OperationSuccess<T> extends OperationResult<T> {
  final T data;
  const OperationSuccess(this.data);
}

class OperationFailure<T> extends OperationResult<T> {
  final String message;
  final bool isConnectivityIssue;
  final Object? error;
  final StackTrace? stackTrace;

  const OperationFailure(
    this.message, {
    this.isConnectivityIssue = false,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() => 'OperationFailure(message: $message, isConnectivityIssue: $isConnectivityIssue)';
}
