import 'package:equatable/equatable.dart';

/// Base class for all application failures/errors.
abstract class Failure extends Equatable {
  final String message;
  final dynamic exception;
  final StackTrace? stackTrace;

  const Failure(
    this.message, {
    this.exception,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, exception];

  @override
  String toString() => 'Failure(message: $message)';
}

/// Network connectivity failure (no internet, connection refused)
class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.exception,
    super.stackTrace,
  });
}

/// Request timeout failure
class TimeoutFailure extends Failure {
  const TimeoutFailure(
    super.message, {
    super.exception,
    super.stackTrace,
  });
}

/// Server error (5xx)
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(
    super.message, {
    this.statusCode,
    super.exception,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// Validation failure (422, field validation errors)
class ValidationFailure extends Failure {
  final Map<String, dynamic>? errors;

  const ValidationFailure(
    super.message, {
    this.errors,
    super.exception,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, errors];
}

/// Authentication failure (401, session expired)
class AuthFailure extends Failure {
  const AuthFailure(
    super.message, {
    super.exception,
    super.stackTrace,
  });
}

/// Rate limit failure (429, too many requests)
class RateLimitFailure extends Failure {
  final Duration? retryAfter;

  const RateLimitFailure(
    super.message, {
    this.retryAfter,
    super.exception,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, retryAfter];
}

/// Not found failure (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure(
    super.message, {
    super.exception,
    super.stackTrace,
  });
}

/// Local cache/storage failure
class CacheFailure extends Failure {
  const CacheFailure(
    super.message, {
    super.exception,
    super.stackTrace,
  });
}

/// Unknown/generic failure
class UnknownFailure extends Failure {
  const UnknownFailure(
    super.message, {
    super.exception,
    super.stackTrace,
  });
}
