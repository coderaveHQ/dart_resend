import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'json.dart';
import 'response.dart';

/// Shared HTTP transport used by Resend resource clients.
final class ResendTransport {
  /// Creates a transport.
  ///
  /// When [client] is omitted, the transport creates and owns one. An injected
  /// client remains caller-owned unless [closeClient] is `true`.
  ResendTransport({
    String? apiKey,
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 30),
    this.userAgent = 'dart_resend/2.0.0',
    Map<String, String> defaultHeaders = const <String, String>{},
    bool closeClient = false,
  }) : _apiKey = apiKey,
       _client = client ?? http.Client(),
       _ownsClient = client == null || closeClient,
       baseUri = baseUri ?? Uri.parse('https://api.resend.com'),
       _defaultHeaders = Map<String, String>.unmodifiable(defaultHeaders) {
    if (apiKey != null && apiKey.trim().isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'must not be empty');
    }
    if (!this.baseUri.hasScheme || !this.baseUri.hasAuthority) {
      throw ArgumentError.value(
        this.baseUri,
        'baseUri',
        'must be an absolute URI',
      );
    }
    if (this.baseUri.scheme != 'https' && this.baseUri.scheme != 'http') {
      throw ArgumentError.value(
        this.baseUri,
        'baseUri',
        'must use HTTP or HTTPS',
      );
    }
    if (this.baseUri.hasQuery || this.baseUri.hasFragment) {
      throw ArgumentError.value(
        this.baseUri,
        'baseUri',
        'must not contain a query or fragment',
      );
    }
    if (timeout.inMicroseconds <= 0) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
    if (userAgent.trim().isEmpty) {
      throw ArgumentError.value(userAgent, 'userAgent', 'must not be empty');
    }
  }

  /// Bearer credential added only to authenticated requests.
  final String? _apiKey;

  /// HTTP client that streams each constructed request.
  final http.Client _client;

  /// Whether [close] must also release [_client].
  final bool _ownsClient;

  /// Caller-provided headers merged before per-request headers.
  final Map<String, String> _defaultHeaders;

  /// Prevents request dispatch after this transport has been closed.
  bool _closed = false;

  /// Base URI against which endpoint paths are resolved.
  final Uri baseUri;

  /// Maximum duration of a complete HTTP request and response read.
  final Duration timeout;

  /// User-Agent header sent with each request.
  final String userAgent;

  /// Sends a GET request.
  Future<ResendResponse<T>> get<T>({
    required List<String> pathSegments,
    Map<String, String>? query,
    Map<String, String>? headers,
    bool authenticated = true,
    required T Function(JsonMap) decode,
  }) {
    return request<T>(
      method: 'GET',
      pathSegments: pathSegments,
      query: query,
      headers: headers,
      authenticated: authenticated,
      decode: decode,
    );
  }

  /// Sends a POST request with an optional JSON or form-encoded body.
  Future<ResendResponse<T>> post<T>({
    required List<String> pathSegments,
    Map<String, String>? query,
    Object? body,
    Map<String, String>? form,
    Map<String, String>? headers,
    String? idempotencyKey,
    bool authenticated = true,
    required T Function(JsonMap) decode,
  }) {
    return request<T>(
      method: 'POST',
      pathSegments: pathSegments,
      query: query,
      body: body,
      form: form,
      headers: headers,
      idempotencyKey: idempotencyKey,
      authenticated: authenticated,
      decode: decode,
    );
  }

  /// Sends a PATCH request with an optional JSON or form-encoded body.
  Future<ResendResponse<T>> patch<T>({
    required List<String> pathSegments,
    Map<String, String>? query,
    Object? body,
    Map<String, String>? form,
    Map<String, String>? headers,
    String? idempotencyKey,
    bool authenticated = true,
    required T Function(JsonMap) decode,
  }) {
    return request<T>(
      method: 'PATCH',
      pathSegments: pathSegments,
      query: query,
      body: body,
      form: form,
      headers: headers,
      idempotencyKey: idempotencyKey,
      authenticated: authenticated,
      decode: decode,
    );
  }

  /// Sends a DELETE request with an optional JSON or form-encoded body.
  Future<ResendResponse<T>> delete<T>({
    required List<String> pathSegments,
    Map<String, String>? query,
    Object? body,
    Map<String, String>? form,
    Map<String, String>? headers,
    String? idempotencyKey,
    bool authenticated = true,
    required T Function(JsonMap) decode,
  }) {
    return request<T>(
      method: 'DELETE',
      pathSegments: pathSegments,
      query: query,
      body: body,
      form: form,
      headers: headers,
      idempotencyKey: idempotencyKey,
      authenticated: authenticated,
      decode: decode,
    );
  }

  /// Sends a request and decodes a successful JSON-object response.
  ///
  /// Each item in [pathSegments] is encoded as one URI path segment. All 2xx
  /// responses are successful. Empty successful bodies are decoded as an empty
  /// JSON object.
  Future<ResendResponse<T>> request<T>({
    required String method,
    required List<String> pathSegments,
    Map<String, String>? query,
    Object? body,
    Map<String, String>? form,
    Map<String, String>? headers,
    String? idempotencyKey,
    bool authenticated = true,
    required T Function(JsonMap) decode,
  }) async {
    if (_closed) {
      throw StateError('The Resend transport is closed.');
    }

    final String normalizedMethod = method.trim().toUpperCase();
    if (normalizedMethod.isEmpty) {
      throw ArgumentError.value(method, 'method', 'must not be empty');
    }
    for (final String segment in pathSegments) {
      if (segment.isEmpty) {
        throw ArgumentError.value(
          pathSegments,
          'pathSegments',
          'must not contain empty segments',
        );
      }
    }
    if (idempotencyKey != null && idempotencyKey.trim().isEmpty) {
      throw ArgumentError.value(
        idempotencyKey,
        'idempotencyKey',
        'must not be empty',
      );
    }
    if (body != null && form != null) {
      throw ArgumentError('Only one of body and form may be provided.');
    }
    if (authenticated && _apiKey == null) {
      throw StateError('An API key is required for authenticated requests.');
    }

    // Encode each path component independently to prevent identifier slashes
    // from changing the endpoint hierarchy.
    final Uri uri = _buildUri(pathSegments, query);
    final http.Request request = http.Request(normalizedMethod, uri);
    request.headers.addAll(
      _buildHeaders(
        contentType: body != null
            ? 'application/json'
            : form != null
            ? 'application/x-www-form-urlencoded; charset=utf-8'
            : null,
        headers: headers,
        idempotencyKey: idempotencyKey,
        authenticated: authenticated,
      ),
    );
    if (body != null) {
      request.body = jsonEncode(immutableJsonValue(body));
    } else if (form != null) {
      request.bodyFields = form;
    }

    // Centralize response/error decoding so every HTTP verb has identical
    // timeout, exception, and metadata behavior.
    return _execute<T>(request, decode);
  }

  /// Sends a multipart/form-data POST request containing one in-memory file.
  Future<ResendResponse<T>> multipartPost<T>({
    required List<String> pathSegments,
    Map<String, String>? query,
    required List<int> bytes,
    required String filename,
    String fileField = 'file',
    Map<String, String> fields = const <String, String>{},
    Map<String, String>? headers,
    String? idempotencyKey,
    bool authenticated = true,
    required T Function(JsonMap) decode,
  }) async {
    if (_closed) {
      throw StateError('The Resend transport is closed.');
    }
    if (filename.trim().isEmpty) {
      throw ArgumentError.value(filename, 'filename', 'must not be empty');
    }
    if (fileField.trim().isEmpty) {
      throw ArgumentError.value(fileField, 'fileField', 'must not be empty');
    }
    for (final String segment in pathSegments) {
      if (segment.isEmpty) {
        throw ArgumentError.value(
          pathSegments,
          'pathSegments',
          'must not contain empty segments',
        );
      }
    }
    if (idempotencyKey != null && idempotencyKey.trim().isEmpty) {
      throw ArgumentError.value(
        idempotencyKey,
        'idempotencyKey',
        'must not be empty',
      );
    }
    if (authenticated && _apiKey == null) {
      throw StateError('An API key is required for authenticated requests.');
    }

    final Uri uri = _buildUri(pathSegments, query);
    final http.MultipartRequest request = http.MultipartRequest('POST', uri);
    request.headers.addAll(
      _buildHeaders(
        contentType: null,
        headers: headers,
        idempotencyKey: idempotencyKey,
        authenticated: authenticated,
      ),
    );
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(fileField, bytes, filename: filename),
    );
    return _execute<T>(request, decode);
  }

  /// Executes one request and normalizes network, API, and decode failures.
  Future<ResendResponse<T>> _execute<T>(
    http.BaseRequest request,
    T Function(JsonMap) decode,
  ) async {
    final String method = request.method;
    final Uri uri = request.url;
    late final http.Response response;
    try {
      response = await _send(request).timeout(timeout);
    } on TimeoutException catch (error, stackTrace) {
      throw ResendTimeoutException(
        timeout: timeout,
        method: method,
        uri: uri,
        cause: error,
        stackTrace: stackTrace,
      );
    } on http.ClientException catch (error, stackTrace) {
      throw ResendNetworkException(
        message: error.message,
        method: method,
        uri: uri,
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw ResendNetworkException(
        message: 'Network request failed.',
        method: method,
        uri: uri,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // Decode malformed response bytes lossily so diagnostics retain a readable
    // body even when an upstream proxy returns invalid UTF-8.
    final String responseBody = utf8.decode(
      response.bodyBytes,
      allowMalformed: true,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiException(response, responseBody);
    }

    final JsonMap json = _decodeSuccessBody(response, responseBody);
    late final T data;
    try {
      data = decode(json);
    } on ResendDecodeException {
      rethrow;
    } catch (error, stackTrace) {
      throw ResendDecodeException(
        message: 'Failed to decode the Resend response payload.',
        statusCode: response.statusCode,
        responseBody: responseBody,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return ResendResponse<T>(
      data: data,
      statusCode: response.statusCode,
      headers: response.headers,
    );
  }

  /// Closes this transport and its HTTP client when the transport owns it.
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    if (_ownsClient) {
      _client.close();
    }
  }

  /// Sends [request] and buffers its streamed response for JSON decoding.
  Future<http.Response> _send(http.BaseRequest request) async {
    final http.StreamedResponse streamedResponse = await _client.send(request);
    return http.Response.fromStream(streamedResponse);
  }

  /// Resolves encoded [pathSegments] and [query] against [baseUri].
  Uri _buildUri(List<String> pathSegments, Map<String, String>? query) {
    final List<String> baseSegments = baseUri.pathSegments
        .where((String segment) => segment.isNotEmpty)
        .toList(growable: false);
    return baseUri.replace(
      pathSegments: <String>[...baseSegments, ...pathSegments],
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  /// Merges defaults and request headers, then enforces protected headers.
  Map<String, String> _buildHeaders({
    required String? contentType,
    required Map<String, String>? headers,
    required String? idempotencyKey,
    required bool authenticated,
  }) {
    final Map<String, String> result = <String, String>{};
    _mergeHeaders(result, <String, String>{
      'Accept': 'application/json',
      'User-Agent': userAgent,
    });
    _mergeHeaders(result, _defaultHeaders);
    if (headers != null) {
      _mergeHeaders(result, headers);
    }
    // Protected headers are written after caller headers so authentication and
    // entity encoding cannot be overridden with a differently cased key.
    if (authenticated) {
      _setHeader(result, 'Authorization', 'Bearer ${_apiKey!}');
    }
    if (contentType != null) {
      _setHeader(result, 'Content-Type', contentType);
    }
    if (idempotencyKey != null) {
      _setHeader(result, 'Idempotency-Key', idempotencyKey);
    }
    return result;
  }

  /// Case-insensitively merges [source] into [target].
  void _mergeHeaders(Map<String, String> target, Map<String, String> source) {
    for (final MapEntry<String, String> entry in source.entries) {
      _setHeader(target, entry.key, entry.value);
    }
  }

  /// Replaces any case variant of [name] before assigning [value].
  void _setHeader(Map<String, String> target, String name, String value) {
    target.removeWhere(
      (String existing, String _) =>
          existing.toLowerCase() == name.toLowerCase(),
    );
    target[name] = value;
  }

  /// Decodes a successful body as an object, treating an empty body as `{}`.
  JsonMap _decodeSuccessBody(http.Response response, String responseBody) {
    if (responseBody.trim().isEmpty) {
      return const <String, Object?>{};
    }
    try {
      final Object? decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Expected a JSON object.');
      }
      return _toJsonMap(decoded);
    } catch (error, stackTrace) {
      throw ResendDecodeException(
        message: 'Failed to decode the Resend response as a JSON object.',
        statusCode: response.statusCode,
        responseBody: responseBody,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Extracts structured API error fields while retaining the raw body.
  ResendApiException _apiException(
    http.Response response,
    String responseBody,
  ) {
    JsonMap? details;
    if (responseBody.trim().isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(responseBody);
        if (decoded is Map<String, Object?>) {
          details = _toJsonMap(decoded);
        }
      } catch (_) {
        // Non-JSON error bodies are retained in responseBody.
      }
    }

    // Resend endpoints use both top-level errors and an `error` object; prefer
    // the nested object while retaining the full payload in `details`.
    final JsonMap? nestedError = _nestedError(details);
    final JsonMap? error = nestedError ?? details;
    final String? errorName =
        _stringValue(error, 'name') ??
        _stringValue(error, 'code') ??
        _stringValue(error, 'type') ??
        _stringValue(details, 'error');
    final String message =
        _stringValue(error, 'message') ??
        _stringValue(details, 'error_description') ??
        _stringValue(details, 'message') ??
        (details?['error'] is String ? details!['error']! as String : null) ??
        response.reasonPhrase ??
        'Request failed with status code ${response.statusCode}.';

    return ResendApiException(
      statusCode: response.statusCode,
      message: message,
      name: errorName,
      responseBody: responseBody,
      details: details,
      headers: response.headers,
    );
  }

  /// Returns a nested structured `error` object when one is present.
  JsonMap? _nestedError(JsonMap? details) {
    final Object? value = details?['error'];
    return value is Map<String, Object?> ? _toJsonMap(value) : null;
  }

  /// Reads [key] only when its error-payload value is a string.
  String? _stringValue(JsonMap? map, String key) {
    final Object? value = map?[key];
    return value is String ? value : null;
  }

  /// Freezes decoded JSON before exposing it through response models.
  JsonMap _toJsonMap(Map<String, Object?> value) => immutableJsonMap(value);
}
