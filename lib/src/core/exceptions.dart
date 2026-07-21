import 'json.dart';

/// Base type for failures produced by the Resend SDK.
sealed class ResendException implements Exception {
  /// Creates a Resend failure.
  const ResendException({required this.message, this.cause, this.stackTrace});

  /// Human-readable failure description.
  final String message;

  /// Original error that caused this failure, when available.
  final Object? cause;

  /// Stack trace associated with [cause], when available.
  final StackTrace? stackTrace;

  /// Returns a diagnostic representation of this value.
  @override
  String toString() => '$runtimeType: $message';
}

/// A non-successful response returned by the Resend API.
final class ResendApiException extends ResendException {
  /// Creates an API failure.
  ResendApiException({
    required this.statusCode,
    required super.message,
    this.name,
    this.responseBody,
    JsonMap? details,
    Map<String, String> headers = const <String, String>{},
  }) : details = details == null ? null : immutableJsonMap(details),
       headers = _normalizedHeaders(headers);

  /// HTTP status code returned by Resend.
  final int statusCode;

  /// Machine-readable Resend error name, when supplied.
  final String? name;

  /// Raw response body, retained for diagnostics.
  final String? responseBody;

  /// Parsed error response, when it was a JSON object.
  final JsonMap? details;

  /// Immutable response headers with lowercase names.
  final Map<String, String> headers;

  /// Returns a response header using a case-insensitive [name].
  String? header(String name) => headers[name.toLowerCase()];

  /// Resend's request identifier, when present.
  String? get requestId {
    return header('x-request-id') ??
        header('request-id') ??
        header('x-resend-request-id') ??
        header('resend-request-id') ??
        header('x-resend-id');
  }

  /// Returns a diagnostic representation of this value.
  @override
  String toString() {
    final String suffix = name == null ? '' : ' ($name)';
    return 'ResendApiException [$statusCode]$suffix: $message';
  }
}

/// A failure while communicating with Resend.
base class ResendNetworkException extends ResendException {
  /// Creates a network failure.
  const ResendNetworkException({
    required super.message,
    required this.method,
    required this.uri,
    super.cause,
    super.stackTrace,
  });

  /// HTTP method used by the failed request.
  final String method;

  /// URI targeted by the failed request.
  final Uri uri;
}

/// A request that exceeded its configured timeout.
final class ResendTimeoutException extends ResendNetworkException {
  /// Creates a timeout failure.
  const ResendTimeoutException({
    required this.timeout,
    required super.method,
    required super.uri,
    super.cause,
    super.stackTrace,
  }) : super(message: 'Request timed out after $timeout.');

  /// Maximum request duration that was exceeded.
  final Duration timeout;
}

/// A response whose successful payload could not be decoded.
final class ResendDecodeException extends ResendException {
  /// Creates a response decoding failure.
  const ResendDecodeException({
    required super.message,
    this.statusCode,
    this.responseBody,
    super.cause,
    super.stackTrace,
  });

  /// HTTP status code associated with the response, when available.
  final int? statusCode;

  /// Raw response body that could not be decoded, when available.
  final String? responseBody;
}

/// Freezes [headers] with lowercase keys for case-insensitive lookup.
Map<String, String> _normalizedHeaders(Map<String, String> headers) {
  return Map<String, String>.unmodifiable(<String, String>{
    for (final MapEntry<String, String> entry in headers.entries)
      entry.key.toLowerCase(): entry.value,
  });
}
