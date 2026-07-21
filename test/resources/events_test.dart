import 'dart:convert';

import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/core/transport.dart';
import 'package:dart_resend/src/resources/events.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Registers this file's test cases with the package:test runner.
void main() {
  // Covers: event request models.
  group('event request models', () {
    // Verifies: schema types serialize documented values.
    test('schema types serialize documented values', () {
      expect(
        EventSchemaType.values.map((EventSchemaType type) => type.value),
        <String>['string', 'number', 'boolean', 'date'],
      );
    });

    // Verifies: create request validates and freezes an optional schema.
    test('create request validates and freezes an optional schema', () {
      final Map<String, EventSchemaType> schema = <String, EventSchemaType>{
        'name': EventSchemaType.string,
        'amount': EventSchemaType.number,
        'active': EventSchemaType.boolean,
        'birthday': EventSchemaType.date,
      };
      final CreateEventRequest request = CreateEventRequest(
        name: 'user.created',
        schema: schema,
      );
      schema['later'] = EventSchemaType.string;

      expect(request.name, 'user.created');
      expect(request.schema, hasLength(4));
      expect(request.toJson(), <String, Object?>{
        'name': 'user.created',
        'schema': <String, Object?>{
          'name': 'string',
          'amount': 'number',
          'active': 'boolean',
          'birthday': 'date',
        },
      });
      expect(
        () => request.schema!['later'] = EventSchemaType.string,
        throwsUnsupportedError,
      );

      final CreateEventRequest minimal = CreateEventRequest(name: 'minimal');
      expect(minimal.schema, isNull);
      expect(minimal.toJson(), <String, Object?>{'name': 'minimal'});
      expect(() => CreateEventRequest(name: ' '), throwsArgumentError);
      expect(
        () => CreateEventRequest(
          name: 'event',
          schema: <String, EventSchemaType>{' ': EventSchemaType.string},
        ),
        throwsArgumentError,
      );
    });

    // Verifies: update request replaces or clears schema.
    test('update request replaces or clears schema', () {
      final UpdateEventRequest replacement = UpdateEventRequest(
        schema: <String, EventSchemaType>{'score': EventSchemaType.number},
      );
      expect(replacement.schema!['score'], EventSchemaType.number);
      expect(replacement.toJson(), <String, Object?>{
        'schema': <String, Object?>{'score': 'number'},
      });
      expect(
        () => replacement.schema!['other'] = EventSchemaType.string,
        throwsUnsupportedError,
      );

      final UpdateEventRequest clear = UpdateEventRequest(schema: null);
      expect(clear.schema, isNull);
      expect(clear.toJson(), <String, Object?>{'schema': null});
    });

    // Verifies: send request requires exactly one contact selector.
    test('send request requires exactly one contact selector', () {
      final Map<String, Object?> payload = <String, Object?>{
        'plan': 'pro',
        'nested': <Object?>[true],
      };
      final SendEventRequest contact = SendEventRequest.toContact(
        event: 'user.created',
        contactId: 'contact-id',
        payload: payload,
      );
      payload['plan'] = 'changed';

      expect(contact.event, 'user.created');
      expect(contact.contactId, 'contact-id');
      expect(contact.email, isNull);
      expect(contact.payload!['plan'], 'pro');
      expect(contact.toJson(), <String, Object?>{
        'event': 'user.created',
        'contact_id': 'contact-id',
        'payload': <String, Object?>{
          'plan': 'pro',
          'nested': <Object?>[true],
        },
      });
      expect(() => contact.payload!['new'] = true, throwsUnsupportedError);

      final SendEventRequest email = SendEventRequest.toEmail(
        event: 'user.created',
        email: 'person@example.com',
      );
      expect(email.contactId, isNull);
      expect(email.email, 'person@example.com');
      expect(email.payload, isNull);
      expect(email.toJson(), <String, Object?>{
        'event': 'user.created',
        'email': 'person@example.com',
      });

      final SendEventRequest direct = SendEventRequest(
        event: 'direct.event',
        contactId: 'direct-contact',
      );
      expect(direct.contactId, 'direct-contact');

      expect(() => SendEventRequest(event: 'event'), throwsArgumentError);
      expect(
        () => SendEventRequest(
          event: 'event',
          contactId: 'contact',
          email: 'person@example.com',
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEventRequest.toContact(event: ' ', contactId: 'contact'),
        throwsArgumentError,
      );
      expect(
        () => SendEventRequest.toContact(event: 'event', contactId: ' '),
        throwsArgumentError,
      );
      expect(
        () => SendEventRequest.toEmail(event: 'event', email: ' '),
        throwsArgumentError,
      );
    });
  });

  // Covers: event response models.
  group('event response models', () {
    // Verifies: exposes fields and preserves unknown schema strings.
    test('exposes fields and preserves unknown schema strings', () {
      final CustomEvent event = CustomEvent.fromJson(<String, Object?>{
        'id': 'event-id',
        'name': 'user.created',
        'schema': <String, Object?>{'name': 'string', 'future': 'future_type'},
        'created_at': '2026-07-20T10:00:00Z',
        'updated_at': '2026-07-20T11:00:00Z',
        'object': 'event',
        'future_field': true,
      });
      expect(event.id, 'event-id');
      expect(event.name, 'user.created');
      expect(event.schema, <String, String>{
        'name': 'string',
        'future': 'future_type',
      });
      expect(event.createdAt, DateTime.utc(2026, 7, 20, 10));
      expect(event.updatedAt, DateTime.utc(2026, 7, 20, 11));
      expect(event.object, 'event');
      expect(event.json['future_field'], isTrue);
      expect(() => event.schema!['new'] = 'string', throwsUnsupportedError);

      final CustomEvent minimal = CustomEvent.fromJson(<String, Object?>{
        'id': 'minimal',
        'name': 'minimal',
        'schema': null,
        'created_at': '2026-07-20T10:00:00Z',
        'updated_at': null,
      });
      expect(minimal.schema, isNull);
      expect(minimal.updatedAt, isNull);
      expect(minimal.object, isNull);

      final CustomEvent malformed = CustomEvent.fromJson(<String, Object?>{
        'id': 'malformed',
        'name': 'malformed',
        'schema': <String, Object?>{'value': true},
        'created_at': '2026-07-20T10:00:00Z',
        'updated_at': null,
      });
      expect(() => malformed.schema, throwsFormatException);
    });

    // Verifies: decodes sent event response.
    test('decodes sent event response', () {
      final SentEvent event = SentEvent.fromJson(<String, Object?>{
        'object': 'future_event_object',
        'event': 'user.created',
      });
      expect(event.object, 'future_event_object');
      expect(event.event, 'user.created');
    });
  });

  // Verifies: EventsResource sends every endpoint with encoded identifiers.
  test(
    'EventsResource sends every endpoint with encoded identifiers',
    () async {
      final List<http.Request> requests = <http.Request>[];
      final MockClient client = MockClient((http.Request request) async {
        requests.add(request);
        final int index = requests.length - 1;
        switch (index) {
          case 0:
            expect(request.method, 'POST');
            expect(request.url.pathSegments, <String>['v1', 'events']);
            expect(jsonDecode(request.body), <String, Object?>{
              'name': 'user.created',
              'schema': <String, Object?>{'plan': 'string'},
            });
            return _jsonResponse(<String, Object?>{
              'object': 'event',
              'id': 'event/a b',
            }, 201);
          case 1:
            expect(request.method, 'GET');
            expect(request.url.queryParameters, <String, String>{
              'limit': '20',
              'after': 'cursor',
            });
            return _jsonResponse(<String, Object?>{
              'object': 'list',
              'has_more': false,
              'data': <Object?>[_eventJson('event-list')],
            });
          case 2:
            expect(request.method, 'GET');
            expect(request.url.pathSegments.last, 'event/a b');
            expect(request.url.toString(), contains('event%2Fa%20b'));
            return _jsonResponse(_eventJson('event/a b'));
          case 3:
            expect(request.method, 'PATCH');
            expect(jsonDecode(request.body), <String, Object?>{'schema': null});
            return _jsonResponse(<String, Object?>{
              'object': 'event',
              'id': 'event/a b',
            });
          case 4:
            expect(request.method, 'DELETE');
            return _jsonResponse(<String, Object?>{
              'object': 'event',
              'id': 'event/a b',
              'deleted': true,
            });
          case 5:
            expect(request.method, 'POST');
            expect(request.url.pathSegments, <String>['v1', 'events', 'send']);
            expect(jsonDecode(request.body), <String, Object?>{
              'event': 'user.created',
              'email': 'person@example.com',
              'payload': <String, Object?>{'plan': 'pro'},
            });
            return _jsonResponse(<String, Object?>{
              'object': 'event',
              'event': 'user.created',
            });
          default:
            expect(request.url.queryParameters, isEmpty);
            return _jsonResponse(<String, Object?>{
              'object': 'list',
              'has_more': false,
              'data': <Object?>[],
            });
        }
      });
      final EventsResource events = EventsResource(
        ResendTransport(
          apiKey: 're_test',
          client: client,
          baseUri: Uri.parse('https://api.example.test/v1/'),
        ),
      );

      final create = await events.create(
        CreateEventRequest(
          name: 'user.created',
          schema: <String, EventSchemaType>{'plan': EventSchemaType.string},
        ),
      );
      expect(create.statusCode, 201);
      expect(create.data.id, 'event/a b');
      expect(create.data.object, 'event');

      final list = await events.list(
        pagination: PaginationOptions(limit: 20, after: 'cursor'),
      );
      expect(list.data.data.single.id, 'event-list');

      final retrieve = await events.retrieve('event/a b');
      expect(retrieve.data.id, 'event/a b');

      final update = await events.update(
        'event/a b',
        UpdateEventRequest(schema: null),
      );
      expect(update.data.id, 'event/a b');

      final deletion = await events.delete('event/a b');
      expect(deletion.data.id, 'event/a b');
      expect(deletion.data.object, 'event');
      expect(deletion.data.deleted, isTrue);

      final sent = await events.send(
        SendEventRequest.toEmail(
          event: 'user.created',
          email: 'person@example.com',
          payload: <String, Object?>{'plan': 'pro'},
        ),
      );
      expect(sent.data.event, 'user.created');

      final empty = await events.list();
      expect(empty.data.data, isEmpty);
      expect(requests, hasLength(7));
    },
  );
}

/// Builds a complete custom-event response fixture for [id].
Map<String, Object?> _eventJson(String id) => <String, Object?>{
  'object': 'event',
  'id': id,
  'name': 'user.created',
  'schema': <String, Object?>{'plan': 'string'},
  'created_at': '2026-07-20T10:00:00Z',
  'updated_at': null,
};

/// Encodes [body] as the JSON response returned by an event endpoint.
http.Response _jsonResponse(Object body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: <String, String>{'content-type': 'application/json'},
  );
}
