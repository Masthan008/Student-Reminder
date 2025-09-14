abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class NetworkException extends AppException {
  const NetworkException(
    String message, {
    String? code,
    dynamic details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    return 'NetworkException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class AuthException extends AppException {
  const AuthException(
    String message, {
    String? code,
    dynamic details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    return 'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class StorageException extends AppException {
  const StorageException(
    String message, {
    String? code,
    dynamic details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    return 'StorageException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class ValidationException extends AppException {
  const ValidationException(
    String message, {
    String? code,
    dynamic details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    return 'ValidationException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class SyncException extends AppException {
  const SyncException(
    String message, {
    String? code,
    dynamic details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    return 'SyncException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class NotificationException extends AppException {
  const NotificationException(
    String message, {
    String? code,
    dynamic details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    return 'NotificationException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}