import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/resources/suppressions.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../support/mock_transport.dart';

void main() {
  test('suppression models and batch selectors expose all data', () {
    expect(
      SuppressionOrigin.values.map((SuppressionOrigin value) => value.value),
      <String>['bounce', 'complaint', 'manual'],
    );
    final Suppression suppression = Suppression.fromJson(<String, Object?>{
      'id': 'sup_1',
      'email': 'person@example.com',
      'origin': 'manual',
      'source_id': 'email_1',
      'created_at': '2026-07-20T12:00:00Z',
    });
    expect(suppression.id, 'sup_1');
    expect(suppression.email, 'person@example.com');
    expect(suppression.origin, 'manual');
    expect(suppression.sourceId, 'email_1');
    expect(suppression.createdAt, DateTime.utc(2026, 7, 20, 12));
    expect(
      Suppression.fromJson(<String, Object?>{
        'id': 'sup_2',
        'email': 'other@example.com',
        'origin': 'bounce',
        'source_id': null,
        'created_at': '2026-07-20T12:00:00Z',
      }).sourceId,
      isNull,
    );

    final RemoveSuppressionsRequest byEmails =
        RemoveSuppressionsRequest.byEmails(<String>['a@example.com']);
    expect(byEmails.emails, <String>['a@example.com']);
    expect(byEmails.ids, isNull);
    expect(byEmails.toJson(), <String, Object?>{
      'emails': <String>['a@example.com'],
    });
    final RemoveSuppressionsRequest byIds = RemoveSuppressionsRequest.byIds(
      <String>['sup_1'],
    );
    expect(byIds.emails, isNull);
    expect(byIds.ids, <String>['sup_1']);
    expect(byIds.toJson(), <String, Object?>{
      'ids': <String>['sup_1'],
    });
  });

  test('batch selectors validate count and blank values', () {
    expect(
      () => RemoveSuppressionsRequest.byEmails(<String>[]),
      throwsRangeError,
    );
    expect(
      () => RemoveSuppressionsRequest.byIds(List<String>.filled(101, 'sup_1')),
      throwsRangeError,
    );
    expect(
      () => RemoveSuppressionsRequest.byEmails(<String>[' ']),
      throwsArgumentError,
    );
  });

  test('suppression resource supports single and batch operations', () async {
    var call = 0;
    final SuppressionsResource resource = SuppressionsResource(
      mockTransport((http.Request request) async {
        call++;
        switch (call) {
          case 1:
            expect(request.method, 'POST');
            expect(request.url.path, '/v1/suppressions');
            expect(decodedBody(request), <String, Object?>{
              'email': 'a@example.com',
            });
            return jsonResponse(<String, Object?>{
              'object': 'suppression',
              'id': 'sup_1',
            }, statusCode: 201);
          case 2:
            expect(request.url.path, '/v1/suppressions/batch/add');
            return jsonResponse(<String, Object?>{
              'data': <Object?>[
                <String, Object?>{'object': 'suppression', 'id': 'sup_2'},
              ],
            }, statusCode: 201);
          case 3:
            expect(request.method, 'GET');
            expect(request.url.path, '/v1/suppressions/a@example.com');
            return jsonResponse(_suppressionJson);
          case 4:
            expect(request.url.queryParameters, <String, String>{
              'limit': '1',
              'before': 'sup_2',
              'origin': 'manual',
            });
            return jsonResponse(<String, Object?>{
              'object': 'list',
              'has_more': false,
              'data': <Object?>[_suppressionJson],
            });
          case 5:
            expect(request.method, 'DELETE');
            return jsonResponse(<String, Object?>{
              'object': 'suppression',
              'id': 'sup_1',
              'deleted': true,
            });
          default:
            expect(request.url.path, '/v1/suppressions/batch/remove');
            expect(decodedBody(request), <String, Object?>{
              'ids': <String>['sup_2'],
            });
            return jsonResponse(<String, Object?>{
              'data': <Object?>[
                <String, Object?>{
                  'object': 'suppression',
                  'id': 'sup_2',
                  'deleted': true,
                },
              ],
            });
        }
      }),
    );

    expect((await resource.add('a@example.com')).data.id, 'sup_1');
    expect(
      (await resource.addBatch(<String>['b@example.com'])).data.data.single.id,
      'sup_2',
    );
    expect((await resource.retrieve('a@example.com')).data.id, 'sup_1');
    expect(
      (await resource.list(
        origin: SuppressionOrigin.manual,
        pagination: PaginationOptions(limit: 1, before: 'sup_2'),
      )).data.data.single.email,
      'a@example.com',
    );
    expect((await resource.remove('sup_1')).data.deleted, isTrue);
    expect(
      (await resource.removeBatch(
        RemoveSuppressionsRequest.byIds(<String>['sup_2']),
      )).data.data.single.deleted,
      isTrue,
    );

    expect(() => resource.add(' '), throwsArgumentError);
    expect(() => resource.addBatch(<String>[]), throwsRangeError);
    expect(
      () => resource.addBatch(List<String>.filled(101, 'a@example.com')),
      throwsRangeError,
    );
    expect(() => resource.retrieve(' '), throwsArgumentError);
    expect(() => resource.remove(' '), throwsArgumentError);
  });
}

const Map<String, Object?> _suppressionJson = <String, Object?>{
  'object': 'suppression',
  'id': 'sup_1',
  'email': 'a@example.com',
  'origin': 'manual',
  'source_id': null,
  'created_at': '2026-07-20T12:00:00Z',
};
