class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiError(this.message, {this.statusCode, this.code});

  factory ApiError.offline() => const ApiError('No internet connection. Please check your network.');
  factory ApiError.timeout() => const ApiError('Request timed out. Please try again.');
  factory ApiError.decoding() => const ApiError('Failed to parse server response.');
  factory ApiError.unauthorized(String msg) => ApiError(msg, statusCode: 401);
  factory ApiError.server(int status, String msg, {String? code}) =>
      ApiError(msg, statusCode: status, code: code);

  @override
  String toString() => message;
}
