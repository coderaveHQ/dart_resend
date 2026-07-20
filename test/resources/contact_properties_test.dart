import 'dart:convert';

import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/core/transport.dart';
import 'package:dart_resend/src/resources/contact_properties.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('contact-property request models', () {
    test('serialize documented property types', () {
      expect(ContactPropertyType.string.value, 'string');
      expect(ContactPropertyType.number.value, 'number');
    });

    test('create validates the key and type-specific fallback', () {
      final CreateContactPropertyRequest text = CreateContactPropertyRequest(
        key: 'company_name_2',
        type: ContactPropertyType.string,
        fallbackValue: 'Unknown',
      );
      expect(text.key, 'company_name_2');
      expect(text.type, ContactPropertyType.string);
      expect(text.fallbackValue, 'Unknown');
      expect(text.toJson(), <String, Object?>{
        'key': 'company_name_2',
        'type': 'string',
        'fallback_value': 'Unknown',
      });

      final CreateContactPropertyRequest number = CreateContactPropertyRequest(
        key: 'lifetime_value',
        type: ContactPropertyType.number,
        fallbackValue: 12.5,
      );
      expect(number.fallbackValue, 12.5);
      expect(number.toJson()['fallback_value'], 12.5);
      expect(
        CreateContactPropertyRequest(
          key: 'nickname',
          type: ContactPropertyType.string,
        ).toJson(),
        <String, Object?>{'key': 'nickname', 'type': 'string'},
      );

      expect(
        () => CreateContactPropertyRequest(
          key: ' ',
          type: ContactPropertyType.string,
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateContactPropertyRequest(
          key: 'x' * 51,
          type: ContactPropertyType.string,
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateContactPropertyRequest(
          key: 'not-valid',
          type: ContactPropertyType.string,
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateContactPropertyRequest(
          key: 'company',
          type: ContactPropertyType.string,
          fallbackValue: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateContactPropertyRequest(
          key: 'score',
          type: ContactPropertyType.number,
          fallbackValue: 'high',
        ),
        throwsArgumentError,
      );
    });

    test('update includes explicit null and validates scalar fallbacks', () {
      final UpdateContactPropertyRequest clear = UpdateContactPropertyRequest(
        fallbackValue: null,
      );
      expect(clear.fallbackValue, isNull);
      expect(clear.toJson(), <String, Object?>{'fallback_value': null});

      final UpdateContactPropertyRequest text = UpdateContactPropertyRequest(
        fallbackValue: 'Unknown',
      );
      expect(text.fallbackValue, 'Unknown');
      final UpdateContactPropertyRequest number = UpdateContactPropertyRequest(
        fallbackValue: 7,
      );
      expect(number.fallbackValue, 7);
      expect(
        () => UpdateContactPropertyRequest(fallbackValue: true),
        throwsArgumentError,
      );
    });
  });

  test('ContactProperty exposes typed and forward-compatible fields', () {
    final ContactProperty property = ContactProperty.fromJson(<String, Object?>{
      'id': 'prop_1',
      'key': 'company',
      'type': 'future_type',
      'fallback_value': 'Unknown',
      'created_at': '2026-07-20T10:11:12.000Z',
      'object': 'contact_property',
      'future_field': <Object?>['preserved'],
    });
    expect(property.id, 'prop_1');
    expect(property.key, 'company');
    expect(property.type, 'future_type');
    expect(property.fallbackValue, 'Unknown');
    expect(property.createdAt, DateTime.utc(2026, 7, 20, 10, 11, 12));
    expect(property.object, 'contact_property');
    expect(property.json['future_field'], <Object?>['preserved']);
    expect(
      () => (property.json['future_field']! as List<Object?>).add('changed'),
      throwsUnsupportedError,
    );

    final ContactProperty minimal = ContactProperty.fromJson(<String, Object?>{
      'id': 'prop_2',
      'key': 'score',
      'type': 'number',
      'fallback_value': null,
      'created_at': '2026-07-20T10:11:12.000Z',
    });
    expect(minimal.fallbackValue, isNull);
    expect(minimal.object, isNull);
  });

  test('ContactPropertiesResource sends every documented operation', () async {
    final List<http.Request> requests = <http.Request>[];
    final MockClient client = MockClient((http.Request request) async {
      requests.add(request);
      final List<String> path = request.url.pathSegments;
      if (request.method == 'POST') {
        expect(path, <String>['v1', 'contact-properties']);
        expect(jsonDecode(request.body), <String, Object?>{
          'key': 'company',
          'type': 'string',
          'fallback_value': 'Unknown',
        });
        return _jsonResponse(<String, Object?>{
          'id': 'prop_created',
          'object': 'contact_property',
        }, 201);
      }
      if (request.method == 'GET' && path.length == 2) {
        expect(request.url.queryParameters, <String, String>{
          'limit': '15',
          'after': 'property_cursor',
        });
        return _jsonResponse(<String, Object?>{
          'object': 'list',
          'has_more': false,
          'data': <Object?>[_propertyJson('prop_list')],
        });
      }
      if (request.method == 'GET') {
        return _jsonResponse(_propertyJson('prop/a b'));
      }
      if (request.method == 'PATCH') {
        expect(jsonDecode(request.body), <String, Object?>{
          'fallback_value': null,
        });
        return _jsonResponse(<String, Object?>{'id': 'prop/a b'});
      }
      expect(request.method, 'DELETE');
      return _jsonResponse(<String, Object?>{
        'id': 'prop/a b',
        'object': 'contact_property',
        'deleted': true,
      });
    });
    final ContactPropertiesResource properties = ContactPropertiesResource(
      ResendTransport(
        apiKey: 're_test',
        client: client,
        baseUri: Uri.parse('https://api.example.test/v1/'),
      ),
    );

    final create = await properties.create(
      CreateContactPropertyRequest(
        key: 'company',
        type: ContactPropertyType.string,
        fallbackValue: 'Unknown',
      ),
    );
    expect(create.statusCode, 201);
    expect(create.data.id, 'prop_created');
    expect(create.data.object, 'contact_property');

    final list = await properties.list(
      pagination: PaginationOptions(limit: 15, after: 'property_cursor'),
    );
    expect(list.data.hasMore, isFalse);
    expect(list.data.data.single.id, 'prop_list');

    final retrieve = await properties.retrieve('prop/a b');
    expect(retrieve.data.id, 'prop/a b');
    expect(requests[2].url.pathSegments.last, 'prop/a b');
    expect(requests[2].url.toString(), contains('prop%2Fa%20b'));

    final update = await properties.update(
      'prop/a b',
      UpdateContactPropertyRequest(fallbackValue: null),
    );
    expect(update.data.id, 'prop/a b');

    final deletion = await properties.delete('prop/a b');
    expect(deletion.data.id, 'prop/a b');
    expect(deletion.data.object, 'contact_property');
    expect(deletion.data.deleted, isTrue);
    expect(requests.map((http.Request item) => item.method), <String>[
      'POST',
      'GET',
      'GET',
      'PATCH',
      'DELETE',
    ]);
  });
}

Map<String, Object?> _propertyJson(String id) => <String, Object?>{
  'id': id,
  'key': 'company',
  'type': 'string',
  'fallback_value': 'Unknown',
  'created_at': '2026-07-20T10:11:12.000Z',
  'object': 'contact_property',
};

http.Response _jsonResponse(Object body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: <String, String>{'content-type': 'application/json'},
  );
}
