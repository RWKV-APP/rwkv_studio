class AppException implements Exception {
  final String message;
  final dynamic stackTrace;
  final String? code;
  final dynamic cause;

  const AppException(this.message, {this.stackTrace, this.code, this.cause});

  @override
  String toString() {
    if (cause != null) {
      return '$message: $cause';
    }
    return message;
  }
}
