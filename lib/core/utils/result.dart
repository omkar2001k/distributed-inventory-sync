/// A simple and readable Result type to handle operations without Dartz.
/// Enables 3-YOE standard clean error handling with strong null safety.
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Factory constructor for successful outcomes
  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  /// Factory constructor for failure outcomes
  factory Result.failure(String error) {
    return Result._(error: error, isSuccess: false);
  }

  /// Transforms the result based on success or failure state
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(String error) onFailure,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    } else {
      return onFailure(error ?? 'An unexpected error occurred');
    }
  }
}
