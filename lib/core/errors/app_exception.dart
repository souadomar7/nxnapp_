/// Base abstract exception for all app-level errors.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Authentication-related errors (login, signup, token refresh, etc.)
class AuthException extends AppException {
  const AuthException({required super.message, super.code});

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

/// Thrown when the device has no internet connection.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'network_unavailable',
  });

  @override
  String toString() => 'NetworkException(code: $code, message: $message)';
}

/// Thrown when the server returns an error response.
class ServerException extends AppException {
  final int statusCode;

  const ServerException({
    required super.message,
    required this.statusCode,
    super.code,
  });

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, code: $code, message: $message)';
}

/// Thrown when form or input validation fails.
class ValidationException extends AppException {
  const ValidationException({required super.message, super.code});

  @override
  String toString() => 'ValidationException(code: $code, message: $message)';
}

/// Thrown when the user lacks the required permissions.
class PermissionException extends AppException {
  const PermissionException({
    super.message = 'You are not authorized to perform this action.',
    super.code = 'unauthorized',
  });

  @override
  String toString() => 'PermissionException(code: $code, message: $message)';
}

/// Thrown when a payment operation fails.
class PaymentException extends AppException {
  const PaymentException({required super.message, super.code});

  @override
  String toString() => 'PaymentException(code: $code, message: $message)';
}

/// Thrown when a requested resource cannot be found.
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.code = 'not_found',
  });

  @override
  String toString() => 'NotFoundException(code: $code, message: $message)';
}
