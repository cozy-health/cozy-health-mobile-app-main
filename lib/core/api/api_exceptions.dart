abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ApiNetworkException extends ApiException {
  ApiNetworkException() : super('No internet connection');
}

class ApiTimeoutException extends ApiException {
  ApiTimeoutException() : super('Request timed out');
}

class ApiAuthException extends ApiException {
  ApiAuthException({int? statusCode})
    : super('Session expired', statusCode: statusCode);
}

class ApiValidationException extends ApiException {
  final Map<String, List<String>> fieldErrors;
  ApiValidationException(this.fieldErrors, String message, {int? statusCode})
    : super(message, statusCode: statusCode);
}

class ApiServerException extends ApiException {
  ApiServerException({int? statusCode})
    : super('Server error', statusCode: statusCode);
}

class ApiAgeActionException extends ApiValidationException {
  ApiAgeActionException({
    required super.statusCode,
    required Map<String, List<String>> fieldErrors,
    this.code,
    this.retryAfterSeconds,
  }) : super(fieldErrors, 'The age or guardian step could not be confirmed.');

  final String? code;
  final int? retryAfterSeconds;
}

class ApiUnknownException extends ApiException {
  ApiUnknownException(super.message, {super.statusCode});
}

class ApiSecureConnectionException extends ApiException {
  ApiSecureConnectionException() : super('Secure connection unavailable');
}

class ApiRateLimitException extends ApiException {
  ApiRateLimitException(super.message, this.retryAfterSeconds)
    : super(statusCode: 429);
  final int retryAfterSeconds;
}
