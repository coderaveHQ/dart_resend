/// Metadata describing the server's current request-rate budget.
final class ResendRateLimit {
  /// Creates rate-limit metadata.
  const ResendRateLimit({this.limit, this.remaining, this.resetAfter});

  /// Maximum requests permitted in the current window, when reported.
  final int? limit;

  /// Requests remaining in the current window, when reported.
  final int? remaining;

  /// Time until the current window resets, when reported.
  final Duration? resetAfter;
}

/// A successful Resend response and its HTTP metadata.
final class ResendResponse<T> {
  /// Creates a successful response.
  ResendResponse({
    required this.data,
    required this.statusCode,
    Map<String, String> headers = const <String, String>{},
  }) : headers = _normalizedHeaders(headers);

  /// Decoded response data.
  final T data;

  /// HTTP status code returned by Resend.
  final int statusCode;

  /// Deeply immutable response headers with lowercase names.
  final Map<String, String> headers;

  /// Whether [statusCode] is in the successful 2xx range.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

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

  /// Parsed rate-limit metadata, or `null` when no such headers were sent.
  ResendRateLimit? get rateLimit {
    final int? limit = _integerHeader('ratelimit-limit');
    final int? remaining = _integerHeader('ratelimit-remaining');
    final Duration? resetAfter = _durationHeader('ratelimit-reset');
    if (limit == null && remaining == null && resetAfter == null) {
      return null;
    }
    return ResendRateLimit(
      limit: limit,
      remaining: remaining,
      resetAfter: resetAfter,
    );
  }

  int? _integerHeader(String name) {
    final String? value = header(name) ?? header('x-$name');
    return value == null ? null : int.tryParse(value);
  }

  Duration? _durationHeader(String name) {
    final String? value = header(name) ?? header('x-$name');
    final double? seconds = value == null ? null : double.tryParse(value);
    if (seconds == null || !seconds.isFinite || seconds < 0) {
      return null;
    }
    return Duration(
      microseconds: (seconds * Duration.microsecondsPerSecond).round(),
    );
  }
}

Map<String, String> _normalizedHeaders(Map<String, String> headers) {
  return Map<String, String>.unmodifiable(<String, String>{
    for (final MapEntry<String, String> entry in headers.entries)
      entry.key.toLowerCase(): entry.value,
  });
}
