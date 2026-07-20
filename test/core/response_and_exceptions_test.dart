import 'package:dart_resend/src/core/exceptions.dart';
import 'package:dart_resend/src/core/json.dart';
import 'package:dart_resend/src/core/response.dart';
import 'package:test/test.dart';

void main() {
  group('ResendResponse', () {
    test('stores data, status, and immutable case-insensitive headers', () {
      final Map<String, String> source = <String, String>{'X-Test': 'value'};
      final ResendResponse<String> response = ResendResponse<String>(
        data: 'data',
        statusCode: 201,
        headers: source,
      );
      source['X-Test'] = 'changed';

      expect(response.data, 'data');
      expect(response.statusCode, 201);
      expect(response.isSuccess, isTrue);
      expect(response.header('X-TEST'), 'value');
      expect(() => response.headers['new'] = 'value', throwsUnsupportedError);
      expect(
        ResendResponse<void>(data: null, statusCode: 300).isSuccess,
        isFalse,
      );
    });

    test('reads each supported request-id header', () {
      for (final String name in <String>[
        'x-request-id',
        'request-id',
        'x-resend-request-id',
        'resend-request-id',
        'x-resend-id',
      ]) {
        final ResendResponse<void> response = ResendResponse<void>(
          data: null,
          statusCode: 200,
          headers: <String, String>{name: 'request-id'},
        );
        expect(response.requestId, 'request-id');
      }
      expect(
        ResendResponse<void>(data: null, statusCode: 200).requestId,
        isNull,
      );
    });

    test('parses standard and prefixed rate-limit headers', () {
      final ResendRateLimit standard = ResendResponse<void>(
        data: null,
        statusCode: 200,
        headers: const <String, String>{
          'ratelimit-limit': '10',
          'ratelimit-remaining': '7',
          'ratelimit-reset': '1.5',
        },
      ).rateLimit!;
      expect(standard.limit, 10);
      expect(standard.remaining, 7);
      expect(standard.resetAfter, const Duration(milliseconds: 1500));

      final ResendRateLimit prefixed = ResendResponse<void>(
        data: null,
        statusCode: 200,
        headers: const <String, String>{
          'x-ratelimit-limit': '20',
          'x-ratelimit-remaining': '19',
          'x-ratelimit-reset': '2',
        },
      ).rateLimit!;
      expect(prefixed.limit, 20);
      expect(prefixed.remaining, 19);
      expect(prefixed.resetAfter, const Duration(seconds: 2));
    });

    test('ignores absent and malformed rate-limit headers', () {
      expect(
        ResendResponse<void>(data: null, statusCode: 200).rateLimit,
        isNull,
      );
      expect(
        ResendResponse<void>(
          data: null,
          statusCode: 200,
          headers: const <String, String>{
            'ratelimit-limit': 'many',
            'ratelimit-remaining': 'some',
            'ratelimit-reset': 'later',
          },
        ).rateLimit,
        isNull,
      );
      expect(
        ResendResponse<void>(
          data: null,
          statusCode: 200,
          headers: const <String, String>{'ratelimit-reset': '-1'},
        ).rateLimit,
        isNull,
      );
      expect(
        ResendResponse<void>(
          data: null,
          statusCode: 200,
          headers: const <String, String>{'ratelimit-reset': 'Infinity'},
        ).rateLimit,
        isNull,
      );

      const ResendRateLimit partial = ResendRateLimit(remaining: 1);
      expect(partial.limit, isNull);
      expect(partial.remaining, 1);
      expect(partial.resetAfter, isNull);
    });
  });

  group('Resend exceptions', () {
    test('API exception preserves immutable diagnostics', () {
      final JsonMap details = <String, Object?>{
        'message': 'Denied',
        'nested': <Object?>['value'],
      };
      final Map<String, String> headers = <String, String>{
        'X-Request-Id': 'request-id',
      };
      final ResendApiException exception = ResendApiException(
        statusCode: 403,
        message: 'Denied',
        name: 'invalid_api_key',
        responseBody: '{"message":"Denied"}',
        details: details,
        headers: headers,
      );
      details['message'] = 'changed';
      headers['X-Request-Id'] = 'changed';

      expect(exception.statusCode, 403);
      expect(exception.message, 'Denied');
      expect(exception.name, 'invalid_api_key');
      expect(exception.responseBody, contains('Denied'));
      expect(exception.details!['message'], 'Denied');
      expect(exception.header('X-REQUEST-ID'), 'request-id');
      expect(exception.requestId, 'request-id');
      expect(exception.cause, isNull);
      expect(exception.stackTrace, isNull);
      expect(
        exception.toString(),
        'ResendApiException [403] (invalid_api_key): Denied',
      );
      expect(() => exception.details!['new'] = true, throwsUnsupportedError);
      expect(() => exception.headers['new'] = 'value', throwsUnsupportedError);
    });

    test('API exception supports request-id fallbacks and absent details', () {
      for (final String name in <String>[
        'request-id',
        'x-resend-request-id',
        'resend-request-id',
        'x-resend-id',
      ]) {
        final ResendApiException exception = ResendApiException(
          statusCode: 400,
          message: 'Bad request',
          headers: <String, String>{name: 'request-id'},
        );
        expect(exception.requestId, 'request-id');
      }
      final ResendApiException exception = ResendApiException(
        statusCode: 400,
        message: 'Bad request',
      );
      expect(exception.details, isNull);
      expect(exception.requestId, isNull);
      expect(exception.toString(), 'ResendApiException [400]: Bad request');
    });

    test('network, timeout, and decode failures retain their causes', () {
      final StateError cause = StateError('offline');
      final StackTrace stackTrace = StackTrace.current;
      final Uri uri = Uri.parse('https://api.resend.com/emails');
      final ResendNetworkException network = ResendNetworkException(
        message: 'offline',
        method: 'GET',
        uri: uri,
        cause: cause,
        stackTrace: stackTrace,
      );
      expect(network.method, 'GET');
      expect(network.uri, uri);
      expect(network.cause, same(cause));
      expect(network.stackTrace, same(stackTrace));
      expect(network.toString(), 'ResendNetworkException: offline');

      final ResendTimeoutException timeout = ResendTimeoutException(
        timeout: const Duration(seconds: 2),
        method: 'POST',
        uri: uri,
        cause: cause,
        stackTrace: stackTrace,
      );
      expect(timeout.timeout, const Duration(seconds: 2));
      expect(timeout.method, 'POST');
      expect(timeout.message, contains('0:00:02'));

      final ResendDecodeException decode = ResendDecodeException(
        message: 'invalid JSON',
        statusCode: 200,
        responseBody: 'not JSON',
        cause: cause,
        stackTrace: stackTrace,
      );
      expect(decode.statusCode, 200);
      expect(decode.responseBody, 'not JSON');
      expect(decode.cause, same(cause));
      expect(decode.stackTrace, same(stackTrace));
      expect(decode.toString(), 'ResendDecodeException: invalid JSON');
    });
  });
}
