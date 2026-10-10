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

class ApiUnknownException extends ApiException {
  ApiUnknownException(super.message);
}

class ApiSecureConnectionException extends ApiException {
  ApiSecureConnectionException() : super('Secure connection unavailable');
}
