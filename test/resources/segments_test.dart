import 'dart:convert';

import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/core/transport.dart';
import 'package:dart_resend/src/resources/segments.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('CreateSegmentRequest validates and serializes its name', () {
    final CreateSegmentRequest request = CreateSegmentRequest(name: 'VIP');
    expect(request.name, 'VIP');
    expect(request.toJson(), <String, Object?>{'name': 'VIP'});
    expect(() => CreateSegmentRequest(name: '  '), throwsArgumentError);
  });

  test('Segment exposes typed fields and immutable raw JSON', () {
    final Segment segment = Segment.fromJson(<String, Object?>{
      'id': 'segment_1',
      'name': 'VIP',
      'created_at': '2026-07-20T10:11:12.000Z',
      'object': 'segment',
      'future_field': 'preserved',
    });
    expect(segment.id, 'segment_1');
    expect(segment.name, 'VIP');
    expect(segment.createdAt, DateTime.utc(2026, 7, 20, 10, 11, 12));
    expect(segment.object, 'segment');
    expect(segment.json['future_field'], 'preserved');
    expect(() => segment.json['name'] = 'changed', throwsUnsupportedError);

    final Segment minimal = Segment.fromJson(<String, Object?>{
      'id': 'segment_2',
      'name': 'Minimal',
      'created_at': '2026-07-20T10:11:12.000Z',
    });
    expect(minimal.object, isNull);
  });

  test('SegmentsResource sends every documented operation', () async {
    final List<http.Request> requests = <http.Request>[];
    final MockClient client = MockClient((http.Request request) async {
      requests.add(request);
      final List<String> path = request.url.pathSegments;

      if (request.method == 'POST') {
        expect(path, <String>['v1', 'segments']);
        expect(jsonDecode(request.body), <String, Object?>{'name': 'VIP'});
        return _jsonResponse(<String, Object?>{
          'id': 'segment_created',
          'object': 'segment',
        }, 201);
      }
      if (request.method == 'GET' && path.length == 2) {
        expect(request.url.queryParameters, <String, String>{
          'limit': '50',
          'after': 'segment_cursor',
        });
        return _jsonResponse(<String, Object?>{
          'object': 'list',
          'has_more': true,
          'data': <Object?>[_segmentJson('segment_list')],
        });
      }
      if (request.method == 'GET' && path.last == 'contacts') {
        expect(path, <String>['v1', 'segments', 'segment/a b', 'contacts']);
        expect(request.url.queryParameters, <String, String>{'limit': '10'});
        return _jsonResponse(<String, Object?>{
          'object': 'list',
          'has_more': false,
          'data': <Object?>[_contactJson()],
        });
      }
      if (request.method == 'GET') {
        expect(path, <String>['v1', 'segments', 'segment/a b']);
        return _jsonResponse(_segmentJson('segment/a b'));
      }
      expect(request.method, 'DELETE');
      return _jsonResponse(<String, Object?>{
        'id': 'segment/a b',
        'object': 'segment',
        'deleted': true,
      });
    });
    final SegmentsResource segments = SegmentsResource(
      ResendTransport(
        apiKey: 're_test',
        client: client,
        baseUri: Uri.parse('https://api.example.test/v1/'),
      ),
    );

    final create = await segments.create(CreateSegmentRequest(name: 'VIP'));
    expect(create.statusCode, 201);
    expect(create.data.id, 'segment_created');
    expect(create.data.object, 'segment');

    final list = await segments.list(
      pagination: PaginationOptions(limit: 50, after: 'segment_cursor'),
    );
    expect(list.data.hasMore, isTrue);
    expect(list.data.data.single.id, 'segment_list');

    final retrieve = await segments.retrieve('segment/a b');
    expect(retrieve.data.id, 'segment/a b');
    expect(requests[2].url.pathSegments.last, 'segment/a b');
    expect(requests[2].url.toString(), contains('segment%2Fa%20b'));

    final contacts = await segments.listContacts(
      'segment/a b',
      pagination: PaginationOptions(limit: 10),
    );
    expect(contacts.data.hasMore, isFalse);
    expect(contacts.data.data.single.id, 'contact_1');
    expect(contacts.data.data.single.email, 'person@example.com');

    final deletion = await segments.delete('segment/a b');
    expect(deletion.data.id, 'segment/a b');
    expect(deletion.data.object, 'segment');
    expect(deletion.data.deleted, isTrue);
    expect(requests.map((http.Request item) => item.method), <String>[
      'POST',
      'GET',
      'GET',
      'GET',
      'DELETE',
    ]);
  });
}

Map<String, Object?> _segmentJson(String id) => <String, Object?>{
  'id': id,
  'name': 'VIP',
  'created_at': '2026-07-20T10:11:12.000Z',
  'object': 'segment',
};

Map<String, Object?> _contactJson() => <String, Object?>{
  'id': 'contact_1',
  'email': 'person@example.com',
  'first_name': 'Pat',
  'last_name': 'Example',
  'created_at': '2026-07-20T10:11:12.000Z',
  'unsubscribed': false,
  'properties': <String, Object?>{},
  'object': 'contact',
};

http.Response _jsonResponse(Object body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: <String, String>{'content-type': 'application/json'},
  );
}
