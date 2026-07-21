import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/resources/logs.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../support/mock_transport.dart';

/// Registers this file's test cases with the package:test runner.
void main() {
  // Verifies: log model exposes summary and detail fields.
  test('log model exposes summary and detail fields', () {
    final ResendApiLog log = ResendApiLog.fromJson(_detailLog);
    expect(log.id, 'log_1');
    expect(log.createdAt, DateTime.utc(2026, 7, 20, 12));
    expect(log.endpoint, '/emails');
    expect(log.method, 'POST');
    expect(log.responseStatus, 200);
    expect(log.userAgent, 'dart_resend/2.0.0');
    expect(log.requestBody, <String, Object?>{'subject': 'Hello'});
    expect(log.responseBody, <String, Object?>{'id': 'email_1'});
    expect(
      ResendApiLog.fromJson(<String, Object?>{
        ..._detailLog,
        'user_agent': null,
        'request_body': null,
        'response_body': null,
      }).userAgent,
      isNull,
    );
  });

  // Verifies: logs resource lists and retrieves logs.
  test('logs resource lists and retrieves logs', () async {
    var call = 0;
    final LogsResource resource = LogsResource(
      mockTransport((http.Request request) async {
        call++;
        if (call == 1) {
          expect(request.url.path, '/v1/logs');
          expect(request.url.queryParameters, <String, String>{'limit': '1'});
          return jsonResponse(<String, Object?>{
            'object': 'list',
            'has_more': false,
            'data': <Object?>[_detailLog],
          });
        }
        expect(request.url.path, '/v1/logs/log%2F1');
        return jsonResponse(_detailLog);
      }),
    );

    expect(
      (await resource.list(
        pagination: PaginationOptions(limit: 1),
      )).data.data.single.id,
      'log_1',
    );
    expect((await resource.retrieve('log/1')).data.method, 'POST');
    expect(() => resource.retrieve(' '), throwsArgumentError);
  });
}

const Map<String, Object?> _detailLog = <String, Object?>{
  'object': 'log',
  'id': 'log_1',
  'created_at': '2026-07-20T12:00:00Z',
  'endpoint': '/emails',
  'method': 'POST',
  'response_status': 200,
  'user_agent': 'dart_resend/2.0.0',
  'request_body': <String, Object?>{'subject': 'Hello'},
  'response_body': <String, Object?>{'id': 'email_1'},
};
