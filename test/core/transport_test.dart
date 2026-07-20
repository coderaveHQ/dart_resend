import 'dart:async';
import 'dart:convert';

import 'package:dart_resend/src/core/exceptions.dart';
import 'package:dart_resend/src/core/json.dart';
import 'package:dart_resend/src/core/response.dart';
import 'package:dart_resend/src/core/transport.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('ResendTransport construction', () {
    test('uses production defaults and can close its owned client', () {
      final ResendTransport transport = ResendTransport(apiKey: 're_test');
      expect(transport.baseUri, Uri.parse('https://api.resend.com'));
      expect(transport.timeout, const Duration(seconds: 30));
      expect(transport.userAgent, 'dart_resend/2.0.0');
      transport.close();
      transport.close();
    });

    test('validates configuration', () {
      expect(() => ResendTransport(apiKey: '  '), throwsArgumentError);
      expect(
        () => ResendTransport(apiKey: 'key', baseUri: Uri.parse('/relative')),
        throwsArgumentError,
      );
      expect(
        () => ResendTransport(
          apiKey: 'key',
          baseUri: Uri.parse('ftp://api.resend.com'),
        ),
        throwsArgumentError,
      );
      expect(
        () => ResendTransport(
          apiKey: 'key',
          baseUri: Uri.parse('https://api.resend.com?query=value'),
        ),
        throwsArgumentError,
      );
      expect(
        () => ResendTransport(apiKey: 'key', timeout: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => ResendTransport(apiKey: 'key', userAgent: ' '),
        throwsArgumentError,
      );
    });

    test('respects injected-client ownership', () {
      final _TrackingClient callerOwned = _TrackingClient();
      ResendTransport(apiKey: 'key', client: callerOwned).close();
      expect(callerOwned.closeCount, 0);

      final _TrackingClient transportOwned = _TrackingClient();
      final ResendTransport transport = ResendTransport(
        apiKey: 'key',
        client: transportOwned,
        closeClient: true,
      );
      transport.close();
      transport.close();
      expect(transportOwned.closeCount, 1);
    });
  });

  group('requests', () {
    test('encodes URI, JSON, and protected and custom headers', () async {
      late http.Request captured;
      final MockClient client = MockClient((http.Request request) async {
        captured = request;
        return http.Response(
          '{"id":"email-id"}',
          201,
          headers: <String, String>{'X-Request-Id': 'request-id'},
        );
      });
      final ResendTransport transport = ResendTransport(
        apiKey: 'real-key',
        client: client,
        baseUri: Uri.parse('https://example.com/api/'),
        defaultHeaders: const <String, String>{
          'X-Default': 'default',
          'Accept': 'text/plain',
          'Authorization': 'bad-key',
        },
      );

      final ResendResponse<String> response = await transport.post<String>(
        pathSegments: const <String>['emails', 'a/b c'],
        query: const <String, String>{'cursor': 'a/b c'},
        body: const <String, Object?>{
          'to': <Object?>['person@example.com'],
        },
        headers: const <String, String>{
          'x-default': 'request',
          'USER-AGENT': 'custom-agent',
          'Authorization': 'worse-key',
          'Content-Type': 'text/plain',
        },
        idempotencyKey: 'operation-id',
        decode: (JsonMap json) => json.requiredString('id'),
      );

      expect(captured.method, 'POST');
      expect(captured.url.pathSegments, <String>['api', 'emails', 'a/b c']);
      expect(captured.url.toString(), contains('a%2Fb%20c'));
      expect(captured.url.queryParameters['cursor'], 'a/b c');
      expect(captured.headers['authorization'], 'Bearer real-key');
      expect(captured.headers['content-type'], 'application/json');
      expect(captured.headers['accept'], 'text/plain');
      expect(captured.headers['user-agent'], 'custom-agent');
      expect(captured.headers['x-default'], 'request');
      expect(captured.headers['idempotency-key'], 'operation-id');
      expect(jsonDecode(captured.body), <String, Object?>{
        'to': <Object?>['person@example.com'],
      });
      expect(response.data, 'email-id');
      expect(response.statusCode, 201);
      expect(response.requestId, 'request-id');
    });

    test('supports unauthenticated form requests', () async {
      late http.Request captured;
      final ResendTransport transport = ResendTransport(
        client: MockClient((http.Request request) async {
          captured = request;
          return http.Response('{"access_token":"token"}', 200);
        }),
      );

      final ResendResponse<String> response = await transport.post<String>(
        pathSegments: const <String>['oauth', 'token'],
        form: const <String, String>{
          'grant_type': 'authorization_code',
          'code': 'secret code',
        },
        headers: const <String, String>{'Authorization': 'Basic client'},
        authenticated: false,
        decode: (JsonMap json) => json.requiredString('access_token'),
      );

      expect(captured.headers['authorization'], 'Basic client');
      expect(
        captured.headers['content-type'],
        startsWith('application/x-www-form-urlencoded'),
      );
      expect(captured.bodyFields, <String, String>{
        'grant_type': 'authorization_code',
        'code': 'secret code',
      });
      expect(response.data, 'token');
    });

    test('convenience methods forward all HTTP methods', () async {
      final List<String> methods = <String>[];
      final ResendTransport transport = ResendTransport(
        client: MockClient((http.Request request) async {
          methods.add(request.method);
          return http.Response('{"method":"${request.method}"}', 200);
        }),
      );
      String decode(JsonMap json) => json.requiredString('method');

      expect(
        (await transport.get<String>(
          pathSegments: const <String>['resource'],
          query: const <String, String>{},
          headers: const <String, String>{'X-Test': 'get'},
          authenticated: false,
          decode: decode,
        )).data,
        'GET',
      );
      expect(
        (await transport.patch<String>(
          pathSegments: const <String>['resource'],
          form: const <String, String>{'value': 'patch'},
          headers: const <String, String>{'X-Test': 'patch'},
          idempotencyKey: 'patch-id',
          authenticated: false,
          decode: decode,
        )).data,
        'PATCH',
      );
      expect(
        (await transport.delete<String>(
          pathSegments: const <String>['resource'],
          body: const <String, Object?>{'value': 'delete'},
          headers: const <String, String>{'X-Test': 'delete'},
          idempotencyKey: 'delete-id',
          authenticated: false,
          decode: decode,
        )).data,
        'DELETE',
      );
      expect(methods, <String>['GET', 'PATCH', 'DELETE']);
    });

    test('accepts empty successful response bodies', () async {
      final ResendTransport transport = ResendTransport(
        apiKey: 'key',
        client: MockClient(
          (http.Request request) async => http.Response('', 204),
        ),
      );
      final ResendResponse<bool> response = await transport.delete<bool>(
        pathSegments: const <String>['oauth', 'revoke'],
        decode: (JsonMap json) => json.isEmpty,
      );
      expect(response.data, isTrue);
      expect(response.statusCode, 204);
    });

    test('validates request arguments and closed state', () async {
      final ResendTransport transport = ResendTransport(
        apiKey: 'key',
        client: MockClient(
          (http.Request request) async => http.Response('{}', 200),
        ),
      );
      bool decode(JsonMap json) => true;

      await expectLater(
        transport.request<bool>(
          method: ' ',
          pathSegments: const <String>['resource'],
          decode: decode,
        ),
        throwsArgumentError,
      );
      await expectLater(
        transport.get<bool>(pathSegments: const <String>[''], decode: decode),
        throwsArgumentError,
      );
      await expectLater(
        transport.post<bool>(
          pathSegments: const <String>['resource'],
          idempotencyKey: ' ',
          decode: decode,
        ),
        throwsArgumentError,
      );
      await expectLater(
        transport.post<bool>(
          pathSegments: const <String>['resource'],
          body: const <String, Object?>{},
          form: const <String, String>{},
          decode: decode,
        ),
        throwsArgumentError,
      );

      final ResendTransport unauthenticated = ResendTransport(
        client: MockClient(
          (http.Request request) async => http.Response('{}', 200),
        ),
      );
      await expectLater(
        unauthenticated.get<bool>(
          pathSegments: const <String>['resource'],
          decode: decode,
        ),
        throwsStateError,
      );

      transport.close();
      await expectLater(
        transport.get<bool>(
          pathSegments: const <String>['resource'],
          decode: decode,
        ),
        throwsStateError,
      );
    });
  });

  group('multipart requests', () {
    test('uploads bytes, fields, query, and headers', () async {
      late http.Request captured;
      final ResendTransport transport = ResendTransport(
        apiKey: 'key',
        client: MockClient((http.Request request) async {
          captured = request;
          return http.Response('{"id":"import-id"}', 200);
        }),
      );

      final ResendResponse<String> response = await transport
          .multipartPost<String>(
            pathSegments: const <String>['contacts', 'imports'],
            query: const <String, String>{'validate': 'true'},
            bytes: utf8.encode('email\nperson@example.com'),
            filename: 'contacts.csv',
            fileField: 'contacts',
            fields: const <String, String>{'audience_id': 'audience-id'},
            headers: const <String, String>{'X-Test': 'value'},
            idempotencyKey: 'import-operation',
            decode: (JsonMap json) => json.requiredString('id'),
          );

      expect(captured.method, 'POST');
      expect(captured.url.queryParameters['validate'], 'true');
      expect(captured.headers['authorization'], 'Bearer key');
      expect(captured.headers['x-test'], 'value');
      expect(captured.headers['idempotency-key'], 'import-operation');
      expect(
        captured.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(captured.body, contains('name="contacts"'));
      expect(captured.body, contains('filename="contacts.csv"'));
      expect(captured.body, contains('person@example.com'));
      expect(captured.body, contains('audience-id'));
      expect(response.data, 'import-id');
    });

    test('supports unauthenticated multipart calls', () async {
      late http.Request captured;
      final ResendTransport transport = ResendTransport(
        client: MockClient((http.Request request) async {
          captured = request;
          return http.Response('{}', 200);
        }),
      );
      await transport.multipartPost<void>(
        pathSegments: const <String>['imports'],
        bytes: const <int>[],
        filename: 'empty.csv',
        authenticated: false,
        decode: (JsonMap json) {},
      );
      expect(captured.headers, isNot(contains('authorization')));
    });

    test('validates multipart arguments and closed state', () async {
      final ResendTransport transport = ResendTransport(
        apiKey: 'key',
        client: MockClient(
          (http.Request request) async => http.Response('{}', 200),
        ),
      );
      bool decode(JsonMap json) => true;

      await expectLater(
        transport.multipartPost<bool>(
          pathSegments: const <String>['imports'],
          bytes: const <int>[],
          filename: ' ',
          decode: decode,
        ),
        throwsArgumentError,
      );
      await expectLater(
        transport.multipartPost<bool>(
          pathSegments: const <String>['imports'],
          bytes: const <int>[],
          filename: 'file.csv',
          fileField: ' ',
          decode: decode,
        ),
        throwsArgumentError,
      );
      await expectLater(
        transport.multipartPost<bool>(
          pathSegments: const <String>[''],
          bytes: const <int>[],
          filename: 'file.csv',
          decode: decode,
        ),
        throwsArgumentError,
      );
      await expectLater(
        transport.multipartPost<bool>(
          pathSegments: const <String>['imports'],
          bytes: const <int>[],
          filename: 'file.csv',
          idempotencyKey: ' ',
          decode: decode,
        ),
        throwsArgumentError,
      );
      final ResendTransport noKey = ResendTransport(
        client: MockClient(
          (http.Request request) async => http.Response('{}', 200),
        ),
      );
      await expectLater(
        noKey.multipartPost<bool>(
          pathSegments: const <String>['imports'],
          bytes: const <int>[],
          filename: 'file.csv',
          decode: decode,
        ),
        throwsStateError,
      );

      transport.close();
      await expectLater(
        transport.multipartPost<bool>(
          pathSegments: const <String>['imports'],
          bytes: const <int>[],
          filename: 'file.csv',
          decode: decode,
        ),
        throwsStateError,
      );
    });
  });

  group('failures', () {
    test('maps Resend, nested, and OAuth API error shapes', () async {
      Future<ResendApiException> invoke(String body) async {
        final ResendTransport transport = ResendTransport(
          apiKey: 'key',
          client: MockClient(
            (http.Request request) async => http.Response(
              body,
              422,
              headers: const <String, String>{'X-Request-Id': 'request-id'},
            ),
          ),
        );
        try {
          await transport.get<void>(
            pathSegments: const <String>['resource'],
            decode: (JsonMap json) {},
          );
          throw StateError('Expected a failure.');
        } on ResendApiException catch (error) {
          return error;
        }
      }

      final ResendApiException resend = await invoke(
        '{"name":"validation_error","message":"Invalid input"}',
      );
      expect(resend.name, 'validation_error');
      expect(resend.message, 'Invalid input');
      expect(resend.statusCode, 422);
      expect(resend.requestId, 'request-id');
      expect(resend.details, isNotNull);

      final ResendApiException nested = await invoke(
        '{"error":{"code":"nested_error","message":"Nested message"}}',
      );
      expect(nested.name, 'nested_error');
      expect(nested.message, 'Nested message');

      final ResendApiException oauth = await invoke(
        '{"error":"invalid_grant","error_description":"Expired code"}',
      );
      expect(oauth.name, 'invalid_grant');
      expect(oauth.message, 'Expired code');

      final ResendApiException typed = await invoke(
        '{"type":"typed_error","message":"Typed message"}',
      );
      expect(typed.name, 'typed_error');

      final ResendApiException outerMessage = await invoke(
        '{"error":{"code":"nested_error"},"message":"Outer message"}',
      );
      expect(outerMessage.message, 'Outer message');

      final ResendApiException stringError = await invoke(
        '{"error":"plain_error"}',
      );
      expect(stringError.name, 'plain_error');
      expect(stringError.message, 'plain_error');
    });

    test('retains non-object and malformed API error bodies', () async {
      Future<ResendApiException> invoke(
        String body, {
        String? reasonPhrase,
      }) async {
        final ResendTransport transport = ResendTransport(
          apiKey: 'key',
          client: MockClient(
            (http.Request request) async =>
                http.Response(body, 500, reasonPhrase: reasonPhrase),
          ),
        );
        try {
          await transport.get<void>(
            pathSegments: const <String>['resource'],
            decode: (JsonMap json) {},
          );
          throw StateError('Expected a failure.');
        } on ResendApiException catch (error) {
          return error;
        }
      }

      final ResendApiException malformed = await invoke(
        'server exploded',
        reasonPhrase: 'Server Error',
      );
      expect(malformed.message, 'Server Error');
      expect(malformed.details, isNull);
      expect(malformed.responseBody, 'server exploded');

      final ResendApiException array = await invoke('[]');
      expect(array.details, isNull);

      final ResendApiException empty = await invoke('');
      expect(empty.message, 'Request failed with status code 500.');
    });

    test('wraps invalid JSON and model decoders', () async {
      Future<Object> invoke(String body, void Function(JsonMap) decode) async {
        final ResendTransport transport = ResendTransport(
          apiKey: 'key',
          client: MockClient(
            (http.Request request) async => http.Response(body, 200),
          ),
        );
        try {
          await transport.get<void>(
            pathSegments: const <String>['resource'],
            decode: decode,
          );
          return StateError('Expected a failure.');
        } catch (error) {
          return error;
        }
      }

      final Object invalid = await invoke('not-json', (JsonMap json) {});
      expect(invalid, isA<ResendDecodeException>());
      expect((invalid as ResendDecodeException).responseBody, 'not-json');

      final Object array = await invoke('[]', (JsonMap json) {});
      expect(array, isA<ResendDecodeException>());

      final ResendDecodeException original = ResendDecodeException(
        message: 'already decoded',
      );
      final Object preserved = await invoke('{}', (JsonMap json) {
        throw original;
      });
      expect(preserved, same(original));

      final Object model = await invoke('{}', (JsonMap json) {
        throw const FormatException('missing field');
      });
      expect(model, isA<ResendDecodeException>());
      expect((model as ResendDecodeException).cause, isA<FormatException>());
      expect(model.statusCode, 200);
    });

    test('maps timeout, HTTP client, and other network failures', () async {
      final ResendTransport timeoutTransport = ResendTransport(
        apiKey: 'key',
        client: _HangingClient(),
        timeout: const Duration(milliseconds: 1),
      );
      await expectLater(
        timeoutTransport.get<void>(
          pathSegments: const <String>['resource'],
          decode: (JsonMap json) {},
        ),
        throwsA(
          isA<ResendTimeoutException>()
              .having(
                (ResendTimeoutException error) => error.method,
                'method',
                'GET',
              )
              .having(
                (ResendTimeoutException error) => error.timeout,
                'timeout',
                const Duration(milliseconds: 1),
              ),
        ),
      );

      final ResendTransport clientTransport = ResendTransport(
        apiKey: 'key',
        client: _ErrorClient(http.ClientException('offline')),
      );
      await expectLater(
        clientTransport.get<void>(
          pathSegments: const <String>['resource'],
          decode: (JsonMap json) {},
        ),
        throwsA(
          isA<ResendNetworkException>().having(
            (ResendNetworkException error) => error.message,
            'message',
            'offline',
          ),
        ),
      );

      final StateError cause = StateError('socket failed');
      final ResendTransport otherTransport = ResendTransport(
        apiKey: 'key',
        client: _ErrorClient(cause),
      );
      await expectLater(
        otherTransport.get<void>(
          pathSegments: const <String>['resource'],
          decode: (JsonMap json) {},
        ),
        throwsA(
          isA<ResendNetworkException>()
              .having(
                (ResendNetworkException error) => error.message,
                'message',
                'Network request failed.',
              )
              .having(
                (ResendNetworkException error) => error.cause,
                'cause',
                same(cause),
              ),
        ),
      );
    });
  });
}

final class _TrackingClient extends http.BaseClient {
  int closeCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }

  @override
  void close() {
    closeCount++;
  }
}

final class _ErrorClient extends http.BaseClient {
  _ErrorClient(this.error);

  final Object error;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return Future<http.StreamedResponse>.error(error);
  }
}

final class _HangingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return Completer<http.StreamedResponse>().future;
  }
}
