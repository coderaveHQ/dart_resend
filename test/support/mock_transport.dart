import 'dart:convert';

import 'package:dart_resend/src/core/transport.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Creates a deterministic transport backed by [handler] for resource tests.
ResendTransport mockTransport(
  Future<http.Response> Function(http.Request request) handler, {
  String? apiKey = 're_test',
}) {
  return ResendTransport(
    apiKey: apiKey,
    client: MockClient(handler),
    baseUri: Uri.parse('https://api.test/v1'),
  );
}

/// Encodes [body] as a JSON response with deterministic metadata.
http.Response jsonResponse(
  Object? body, {
  int statusCode = 200,
  Map<String, String> headers = const <String, String>{},
}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: <String, String>{'content-type': 'application/json', ...headers},
  );
}

/// Decodes the JSON body captured from [request].
Object? decodedBody(http.Request request) {
  return request.body.isEmpty ? null : jsonDecode(request.body);
}
