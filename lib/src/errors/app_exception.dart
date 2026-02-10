class AppException implements Exception {
  final String message;
  final String? stackTrace;
  final String? code;

  AppException(this.message, {this.stackTrace, this.code});

  @override
  String toString() {
    return message;
  }
}
