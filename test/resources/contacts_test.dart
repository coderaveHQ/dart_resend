import 'dart:convert';

import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/core/transport.dart';
import 'package:dart_resend/src/resources/contacts.dart';
import 'package:dart_resend/src/resources/topics.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('contact request models', () {
    test('references serialize and validate IDs', () {
      final ContactSegmentReference segment = ContactSegmentReference(
        'segment_1',
      );
      final ContactTopicSubscription topic = ContactTopicSubscription(
        id: 'topic_1',
        subscription: TopicSubscription.optOut,
      );
      expect(segment.id, 'segment_1');
      expect(segment.toJson(), <String, Object?>{'id': 'segment_1'});
      expect(topic.id, 'topic_1');
      expect(topic.subscription, TopicSubscription.optOut);
      expect(topic.toJson(), <String, Object?>{
        'id': 'topic_1',
        'subscription': 'opt_out',
      });
      expect(() => ContactSegmentReference(' '), throwsArgumentError);
      expect(
        () => ContactTopicSubscription(
          id: ' ',
          subscription: TopicSubscription.optIn,
        ),
        throwsArgumentError,
      );
    });

    test('create serializes all fields and defensively copies collections', () {
      final Map<String, Object?> sourceProperties = <String, Object?>{
        'tier': 'gold',
        'score': 7.5,
        'nickname': null,
      };
      final List<ContactSegmentReference> sourceSegments =
          <ContactSegmentReference>[
            ContactSegmentReference('segment_1'),
            ContactSegmentReference('segment_2'),
          ];
      final List<ContactTopicSubscription> sourceTopics =
          <ContactTopicSubscription>[
            ContactTopicSubscription(
              id: 'topic_1',
              subscription: TopicSubscription.optIn,
            ),
            ContactTopicSubscription(
              id: 'topic_2',
              subscription: TopicSubscription.optOut,
            ),
          ];
      final CreateContactRequest request = CreateContactRequest(
        email: 'person@example.com',
        firstName: 'Pat',
        lastName: 'Example',
        unsubscribed: false,
        properties: sourceProperties,
        segments: sourceSegments,
        topics: sourceTopics,
      );
      sourceProperties.clear();
      sourceSegments.clear();
      sourceTopics.clear();

      expect(request.email, 'person@example.com');
      expect(request.firstName, 'Pat');
      expect(request.lastName, 'Example');
      expect(request.unsubscribed, isFalse);
      expect(request.properties, <String, Object?>{
        'tier': 'gold',
        'score': 7.5,
        'nickname': null,
      });
      expect(request.segments, hasLength(2));
      expect(request.topics, hasLength(2));
      expect(request.toJson(), <String, Object?>{
        'email': 'person@example.com',
        'first_name': 'Pat',
        'last_name': 'Example',
        'unsubscribed': false,
        'properties': <String, Object?>{
          'tier': 'gold',
          'score': 7.5,
          'nickname': null,
        },
        'segments': <Object?>[
          <String, Object?>{'id': 'segment_1'},
          <String, Object?>{'id': 'segment_2'},
        ],
        'topics': <Object?>[
          <String, Object?>{'id': 'topic_1', 'subscription': 'opt_in'},
          <String, Object?>{'id': 'topic_2', 'subscription': 'opt_out'},
        ],
      });
      expect(
        () => request.properties!['tier'] = 'changed',
        throwsUnsupportedError,
      );
      expect(
        () => request.segments.add(ContactSegmentReference('segment_3')),
        throwsUnsupportedError,
      );
      expect(
        () => request.topics.add(
          ContactTopicSubscription(
            id: 'topic_3',
            subscription: TopicSubscription.optIn,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('create omits absent fields and rejects malformed values', () {
      final CreateContactRequest minimal = CreateContactRequest(
        email: 'minimal@example.com',
      );
      expect(minimal.firstName, isNull);
      expect(minimal.lastName, isNull);
      expect(minimal.unsubscribed, isNull);
      expect(minimal.properties, isNull);
      expect(minimal.segments, isEmpty);
      expect(minimal.topics, isEmpty);
      expect(minimal.toJson(), <String, Object?>{
        'email': 'minimal@example.com',
      });

      expect(() => CreateContactRequest(email: ' '), throwsArgumentError);
      expect(
        () => CreateContactRequest(email: 'valid@example.com', firstName: ' '),
        throwsArgumentError,
      );
      expect(
        () => CreateContactRequest(email: 'valid@example.com', lastName: ' '),
        throwsArgumentError,
      );
      expect(
        () => CreateContactRequest(
          email: 'valid@example.com',
          properties: <String, Object?>{' ': 'value'},
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateContactRequest(
          email: 'valid@example.com',
          properties: <String, Object?>{'enabled': true},
        ),
        throwsArgumentError,
      );
      final ContactSegmentReference duplicateSegment = ContactSegmentReference(
        'segment_1',
      );
      expect(
        () => CreateContactRequest(
          email: 'valid@example.com',
          segments: <ContactSegmentReference>[
            duplicateSegment,
            duplicateSegment,
          ],
        ),
        throwsArgumentError,
      );
      final ContactTopicSubscription duplicateTopic = ContactTopicSubscription(
        id: 'topic_1',
        subscription: TopicSubscription.optIn,
      );
      expect(
        () => CreateContactRequest(
          email: 'valid@example.com',
          topics: <ContactTopicSubscription>[duplicateTopic, duplicateTopic],
        ),
        throwsArgumentError,
      );
    });

    test('update requires a field and serializes property changes', () {
      final UpdateContactRequest full = UpdateContactRequest(
        firstName: 'New',
        lastName: 'Name',
        unsubscribed: true,
        properties: <String, Object?>{'score': 9, 'nickname': null},
      );
      expect(full.firstName, 'New');
      expect(full.lastName, 'Name');
      expect(full.unsubscribed, isTrue);
      expect(full.properties, <String, Object?>{'score': 9, 'nickname': null});
      expect(full.clearFirstName, isFalse);
      expect(full.clearLastName, isFalse);
      expect(full.toJson(), <String, Object?>{
        'first_name': 'New',
        'last_name': 'Name',
        'unsubscribed': true,
        'properties': <String, Object?>{'score': 9, 'nickname': null},
      });
      expect(
        UpdateContactRequest(unsubscribed: false).toJson(),
        <String, Object?>{'unsubscribed': false},
      );
      final UpdateContactRequest clear = UpdateContactRequest(
        clearFirstName: true,
        clearLastName: true,
      );
      expect(clear.clearFirstName, isTrue);
      expect(clear.clearLastName, isTrue);
      expect(clear.toJson(), <String, Object?>{
        'first_name': null,
        'last_name': null,
      });
      expect(() => UpdateContactRequest(), throwsArgumentError);
      expect(() => UpdateContactRequest(firstName: ' '), throwsArgumentError);
      expect(() => UpdateContactRequest(lastName: ' '), throwsArgumentError);
      expect(
        () => UpdateContactRequest(
          properties: <String, Object?>{'enabled': <Object?>[]},
        ),
        throwsArgumentError,
      );
      expect(
        () => UpdateContactRequest(firstName: 'Name', clearFirstName: true),
        throwsArgumentError,
      );
      expect(
        () => UpdateContactRequest(lastName: 'Name', clearLastName: true),
        throwsArgumentError,
      );
    });

    test('topic update is non-empty, unique, and immutable', () {
      final List<ContactTopicSubscription> source = <ContactTopicSubscription>[
        ContactTopicSubscription(
          id: 'topic_1',
          subscription: TopicSubscription.optOut,
        ),
      ];
      final UpdateContactTopicsRequest request = UpdateContactTopicsRequest(
        source,
      );
      source.clear();
      expect(request.topics.single.id, 'topic_1');
      expect(request.toJson(), <Object?>[
        <String, Object?>{'id': 'topic_1', 'subscription': 'opt_out'},
      ]);
      expect(
        () => request.topics.add(
          ContactTopicSubscription(
            id: 'topic_2',
            subscription: TopicSubscription.optIn,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => UpdateContactTopicsRequest(const <ContactTopicSubscription>[]),
        throwsArgumentError,
      );
      final ContactTopicSubscription duplicate = ContactTopicSubscription(
        id: 'topic_1',
        subscription: TopicSubscription.optIn,
      );
      expect(
        () => UpdateContactTopicsRequest(<ContactTopicSubscription>[
          duplicate,
          duplicate,
        ]),
        throwsArgumentError,
      );
    });
  });

  group('contact import request models', () {
    test('serialize every documented enum value', () {
      expect(ContactImportOnConflict.upsert.value, 'upsert');
      expect(ContactImportOnConflict.skip.value, 'skip');
      expect(ContactImportStatus.queued.value, 'queued');
      expect(ContactImportStatus.inProgress.value, 'in_progress');
      expect(ContactImportStatus.completed.value, 'completed');
      expect(ContactImportStatus.failed.value, 'failed');
      expect(ContactImportPropertyType.string.value, 'string');
      expect(ContactImportPropertyType.number.value, 'number');
      expect(ContactImportPropertyType.boolean.value, 'boolean');
    });

    test('property mapping validates and conditionally includes its type', () {
      final ContactImportPropertyMapping typed = ContactImportPropertyMapping(
        column: 'Lifetime Value',
        type: ContactImportPropertyType.number,
      );
      expect(typed.column, 'Lifetime Value');
      expect(typed.type, ContactImportPropertyType.number);
      expect(typed.toJson(), <String, Object?>{
        'column': 'Lifetime Value',
        'type': 'number',
      });
      expect(
        ContactImportPropertyMapping(column: 'Company').toJson(),
        <String, Object?>{'column': 'Company'},
      );
      expect(
        () => ContactImportPropertyMapping(column: ' '),
        throwsArgumentError,
      );
    });

    test('column map serializes built-in and custom field mappings', () {
      final Map<String, ContactImportPropertyMapping> properties =
          <String, ContactImportPropertyMapping>{
            'company': ContactImportPropertyMapping(column: 'Company'),
            'active': ContactImportPropertyMapping(
              column: 'Is Active',
              type: ContactImportPropertyType.boolean,
            ),
          };
      final ContactImportColumnMap map = ContactImportColumnMap(
        email: 'Email Address',
        firstName: 'First Name',
        lastName: 'Last Name',
        unsubscribed: 'Unsubscribed',
        properties: properties,
      );
      properties.clear();
      expect(map.email, 'Email Address');
      expect(map.firstName, 'First Name');
      expect(map.lastName, 'Last Name');
      expect(map.unsubscribed, 'Unsubscribed');
      expect(map.properties, hasLength(2));
      expect(map.toJson(), <String, Object?>{
        'email': 'Email Address',
        'first_name': 'First Name',
        'last_name': 'Last Name',
        'unsubscribed': 'Unsubscribed',
        'properties': <String, Object?>{
          'company': <String, Object?>{'column': 'Company'},
          'active': <String, Object?>{'column': 'Is Active', 'type': 'boolean'},
        },
      });
      expect(
        () => map.properties['other'] = ContactImportPropertyMapping(
          column: 'Other',
        ),
        throwsUnsupportedError,
      );
      expect(ContactImportColumnMap(email: 'email').toJson(), <String, Object?>{
        'email': 'email',
      });
      expect(() => ContactImportColumnMap(), throwsArgumentError);
      expect(() => ContactImportColumnMap(email: ' '), throwsArgumentError);
      expect(
        () => ContactImportColumnMap(
          properties: <String, ContactImportPropertyMapping>{
            ' ': ContactImportPropertyMapping(column: 'Column'),
          },
        ),
        throwsArgumentError,
      );
    });

    test('CSV import request validates and freezes upload inputs', () {
      final List<int> bytes = utf8.encode('email\nperson@example.com\n');
      final List<ContactSegmentReference> segments = <ContactSegmentReference>[
        ContactSegmentReference('segment_1'),
      ];
      final List<ContactTopicSubscription> topics = <ContactTopicSubscription>[
        ContactTopicSubscription(
          id: 'topic_1',
          subscription: TopicSubscription.optIn,
        ),
      ];
      final CreateContactImportRequest request = CreateContactImportRequest(
        bytes: bytes,
        filename: 'contacts.csv',
        columnMap: ContactImportColumnMap(email: 'email'),
        onConflict: ContactImportOnConflict.upsert,
        segments: segments,
        topics: topics,
      );
      bytes[0] = 0;
      segments.clear();
      topics.clear();
      expect(utf8.decode(request.bytes), 'email\nperson@example.com\n');
      expect(request.filename, 'contacts.csv');
      expect(request.columnMap!.email, 'email');
      expect(request.onConflict, ContactImportOnConflict.upsert);
      expect(request.segments.single.id, 'segment_1');
      expect(request.topics.single.id, 'topic_1');
      expect(() => request.bytes.add(0), throwsUnsupportedError);
      expect(
        () => request.segments.add(ContactSegmentReference('segment_2')),
        throwsUnsupportedError,
      );
      expect(
        () => CreateContactImportRequest(bytes: <int>[], filename: 'x.csv'),
        throwsArgumentError,
      );
      expect(
        () => CreateContactImportRequest(bytes: <int>[256], filename: 'x.csv'),
        throwsRangeError,
      );
      expect(
        () => CreateContactImportRequest(bytes: <int>[1], filename: ' '),
        throwsArgumentError,
      );
      final ContactSegmentReference duplicateSegment = ContactSegmentReference(
        'segment_1',
      );
      expect(
        () => CreateContactImportRequest(
          bytes: <int>[1],
          filename: 'x.csv',
          segments: <ContactSegmentReference>[
            duplicateSegment,
            duplicateSegment,
          ],
        ),
        throwsArgumentError,
      );
      final ContactTopicSubscription duplicateTopic = ContactTopicSubscription(
        id: 'topic_1',
        subscription: TopicSubscription.optIn,
      );
      expect(
        () => CreateContactImportRequest(
          bytes: <int>[1],
          filename: 'x.csv',
          topics: <ContactTopicSubscription>[duplicateTopic, duplicateTopic],
        ),
        throwsArgumentError,
      );
    });
  });

  group('contact response models', () {
    test('Contact exposes typed fields and immutable properties', () {
      final Contact contact = Contact.fromJson(_contactJson('contact_1'));
      expect(contact.id, 'contact_1');
      expect(contact.email, 'person@example.com');
      expect(contact.firstName, 'Pat');
      expect(contact.lastName, 'Example');
      expect(contact.createdAt, DateTime.utc(2026, 7, 20, 10, 11, 12));
      expect(contact.unsubscribed, isFalse);
      expect(contact.properties!.keys, <String>['tier']);
      expect(contact.properties!['tier']!.type, 'future_type');
      expect(contact.properties!['tier']!.value, 'gold');
      expect(contact.object, 'contact');
      expect(
        () => contact.properties!['tier'] = ContactPropertyValue.fromJson(
          <String, Object?>{'type': 'string', 'value': 'changed'},
        ),
        throwsUnsupportedError,
      );

      final Contact minimal = Contact.fromJson(<String, Object?>{
        'id': 'contact_2',
        'email': 'minimal@example.com',
        'first_name': null,
        'last_name': null,
        'created_at': '2026-07-20T10:11:12.000Z',
        'unsubscribed': true,
      });
      expect(minimal.firstName, isNull);
      expect(minimal.lastName, isNull);
      expect(minimal.properties, isNull);
      expect(minimal.object, isNull);

      final Map<String, Object?> malformedJson = _contactJson(
        'contact_invalid',
      );
      malformedJson['properties'] = <String, Object?>{'tier': 'not_an_object'};
      expect(
        () => Contact.fromJson(malformedJson).properties,
        throwsFormatException,
      );
    });

    test('membership and topic models expose typed fields', () {
      final ContactSegment segment = ContactSegment.fromJson(
        _contactSegmentJson(),
      );
      expect(segment.id, 'segment_1');
      expect(segment.name, 'VIP');
      expect(segment.createdAt, DateTime.utc(2026, 7, 20, 10, 11, 12));

      final ContactSegmentDeletion deletion = ContactSegmentDeletion.fromJson(
        <String, Object?>{
          'id': 'contact_1',
          'audienceId': 'segment_1',
          'deleted': true,
        },
      );
      expect(deletion.contactId, 'contact_1');
      expect(deletion.segmentId, 'segment_1');
      expect(deletion.deleted, isTrue);
      expect(
        ContactSegmentDeletion.fromJson(<String, Object?>{
          'id': 'contact_2',
          'segment_id': 'segment_2',
          'deleted': true,
        }).segmentId,
        'segment_2',
      );
      expect(
        ContactSegmentDeletion.fromJson(<String, Object?>{
          'id': 'contact_3',
          'audience_id': 'segment_3',
          'deleted': true,
        }).segmentId,
        'segment_3',
      );
      expect(
        () => ContactSegmentDeletion.fromJson(<String, Object?>{
          'id': 'contact_4',
          'deleted': true,
        }).segmentId,
        throwsFormatException,
      );

      final ContactTopic topic = ContactTopic.fromJson(_contactTopicJson());
      expect(topic.id, 'topic_1');
      expect(topic.name, 'Product updates');
      expect(topic.description, 'News');
      expect(topic.subscription, 'future_subscription');
      final ContactTopic noDescription =
          ContactTopic.fromJson(<String, Object?>{
            'id': 'topic_2',
            'name': 'Security',
            'description': null,
            'subscription': 'opt_in',
          });
      expect(noDescription.description, isNull);
    });

    test('import models expose raw status, optional dates, and counts', () {
      final ContactImportCounts counts = ContactImportCounts.fromJson(
        <String, Object?>{
          'total': 10,
          'created': 4,
          'updated': 3,
          'skipped': 2,
          'failed': 1,
        },
      );
      expect(counts.total, 10);
      expect(counts.created, 4);
      expect(counts.updated, 3);
      expect(counts.skipped, 2);
      expect(counts.failed, 1);

      final ContactImport import = ContactImport.fromJson(
        _contactImportJson('import_1'),
      );
      expect(import.id, 'import_1');
      expect(import.status, 'future_status');
      expect(import.createdAt, DateTime.utc(2026, 7, 20, 10, 11, 12));
      expect(import.completedAt, DateTime.utc(2026, 7, 20, 10, 12, 13));
      expect(import.counts.total, 10);
      expect(import.object, 'contact_import');

      final ContactImport queued = ContactImport.fromJson(<String, Object?>{
        'id': 'import_2',
        'status': 'queued',
        'created_at': '2026-07-20T10:11:12.000Z',
        'counts': <String, Object?>{
          'total': 0,
          'created': 0,
          'updated': 0,
          'skipped': 0,
          'failed': 0,
        },
      });
      expect(queued.completedAt, isNull);
      expect(queued.counts.total, 0);
      expect(queued.object, isNull);
    });
  });

  test(
    'ContactsResource sends contact, membership, and topic operations',
    () async {
      final List<http.Request> requests = <http.Request>[];
      final MockClient client = MockClient((http.Request request) async {
        requests.add(request);
        final List<String> path = request.url.pathSegments;

        if (path.length == 2 && path.last == 'contacts') {
          if (request.method == 'POST') {
            expect(jsonDecode(request.body), <String, Object?>{
              'email': 'new@example.com',
              'first_name': 'New',
            });
            return _jsonResponse(<String, Object?>{
              'id': 'contact_created',
              'object': 'contact',
            }, 201);
          }
          expect(request.method, 'GET');
          expect(request.url.queryParameters, <String, String>{
            'limit': '20',
            'after': 'contact_cursor',
          });
          return _pageResponse(_contactJson('contact_list'), hasMore: true);
        }
        if (path.length == 4 && path[1] == 'segments') {
          expect(path, <String>['v1', 'segments', 'segment/a b', 'contacts']);
          expect(request.url.queryParameters, <String, String>{'limit': '10'});
          return _pageResponse(_contactJson('contact_segment_list'));
        }

        final String contactId = path[2];
        if (path.length == 3) {
          if (request.method == 'GET') {
            return _jsonResponse(_contactJson(contactId));
          }
          if (request.method == 'PATCH') {
            expect(jsonDecode(request.body), <String, Object?>{
              'unsubscribed': true,
            });
            return _jsonResponse(<String, Object?>{'id': contactId});
          }
          expect(request.method, 'DELETE');
          return _jsonResponse(<String, Object?>{
            'id': contactId,
            'object': 'contact',
            'deleted': true,
          });
        }
        if (path.last == 'topics') {
          if (request.method == 'GET') {
            expect(request.url.queryParameters, <String, String>{'limit': '5'});
            return _pageResponse(_contactTopicJson());
          }
          expect(request.method, 'PATCH');
          expect(jsonDecode(request.body), <Object?>[
            <String, Object?>{'id': 'topic_1', 'subscription': 'opt_out'},
          ]);
          return _jsonResponse(<String, Object?>{'id': contactId});
        }
        if (path.length == 4 && path.last == 'segments') {
          expect(request.method, 'GET');
          expect(request.url.queryParameters, <String, String>{'limit': '6'});
          return _pageResponse(_contactSegmentJson());
        }
        expect(path.length, 5);
        if (request.method == 'POST') {
          return _jsonResponse(<String, Object?>{'id': path.last});
        }
        expect(request.method, 'DELETE');
        return _jsonResponse(<String, Object?>{
          'id': contactId,
          'audienceId': path.last,
          'deleted': true,
        });
      });
      final ContactsResource contacts = ContactsResource(
        ResendTransport(
          apiKey: 're_test',
          client: client,
          baseUri: Uri.parse('https://api.example.test/v1/'),
        ),
      );

      final create = await contacts.create(
        CreateContactRequest(email: 'new@example.com', firstName: 'New'),
      );
      expect(create.statusCode, 201);
      expect(create.data.id, 'contact_created');
      expect(create.data.object, 'contact');

      final global = await contacts.list(
        pagination: PaginationOptions(limit: 20, after: 'contact_cursor'),
      );
      expect(global.data.hasMore, isTrue);
      expect(global.data.data.single.id, 'contact_list');

      final filtered = await contacts.list(
        segmentId: 'segment/a b',
        pagination: PaginationOptions(limit: 10),
      );
      expect(filtered.data.data.single.id, 'contact_segment_list');
      expect(requests[2].url.toString(), contains('segment%2Fa%20b'));

      const String email = 'person+folder@example.com';
      final retrieve = await contacts.retrieve(email);
      expect(retrieve.data.email, 'person@example.com');
      expect(requests[3].url.pathSegments.last, email);
      expect(requests[3].url.toString(), endsWith('/$email'));

      final update = await contacts.update(
        email,
        UpdateContactRequest(unsubscribed: true),
      );
      expect(update.data.id, email);

      final deletion = await contacts.delete(email);
      expect(deletion.data.id, email);
      expect(deletion.data.object, 'contact');
      expect(deletion.data.deleted, isTrue);

      final segments = await contacts.listSegments(
        email,
        pagination: PaginationOptions(limit: 6),
      );
      expect(segments.data.data.single.id, 'segment_1');

      final added = await contacts.addToSegment(email, 'segment/a b');
      expect(added.data.id, 'segment/a b');

      final removed = await contacts.removeFromSegment(email, 'segment/a b');
      expect(removed.data.contactId, email);
      expect(removed.data.segmentId, 'segment/a b');
      expect(removed.data.deleted, isTrue);

      final topics = await contacts.listTopics(
        email,
        pagination: PaginationOptions(limit: 5),
      );
      expect(topics.data.data.single.id, 'topic_1');

      final topicUpdate = await contacts.updateTopics(
        email,
        UpdateContactTopicsRequest(<ContactTopicSubscription>[
          ContactTopicSubscription(
            id: 'topic_1',
            subscription: TopicSubscription.optOut,
          ),
        ]),
      );
      expect(topicUpdate.data.id, email);
      expect(requests.map((http.Request item) => item.method), <String>[
        'POST',
        'GET',
        'GET',
        'GET',
        'PATCH',
        'DELETE',
        'GET',
        'POST',
        'DELETE',
        'GET',
        'PATCH',
      ]);
    },
  );

  test(
    'ContactImportsResource sends multipart create, list, and retrieve',
    () async {
      final List<http.Request> requests = <http.Request>[];
      var createCount = 0;
      final MockClient client = MockClient((http.Request request) async {
        requests.add(request);
        final List<String> path = request.url.pathSegments;
        expect(path.take(3), <String>['v1', 'contacts', 'imports']);

        if (request.method == 'POST') {
          createCount++;
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data'),
          );
          expect(request.body, contains('name="file"'));
          expect(request.body, contains('filename="contacts.csv"'));
          expect(request.body, contains('person@example.com'));
          if (createCount == 1) {
            expect(request.body, contains('name="column_map"'));
            expect(
              request.body,
              contains(
                jsonEncode(ContactImportColumnMap(email: 'Email').toJson()),
              ),
            );
            expect(request.body, contains('name="on_conflict"'));
            expect(request.body, contains('upsert'));
            expect(request.body, contains('name="segments"'));
            expect(
              request.body,
              contains(
                jsonEncode(<Object?>[
                  <String, Object?>{'id': 'segment_1'},
                ]),
              ),
            );
            expect(request.body, contains('name="topics"'));
            expect(request.body, contains('opt_in'));
          } else {
            expect(request.body, isNot(contains('name="column_map"')));
            expect(request.body, isNot(contains('name="on_conflict"')));
            expect(request.body, isNot(contains('name="segments"')));
            expect(request.body, isNot(contains('name="topics"')));
          }
          return _jsonResponse(<String, Object?>{
            'id': 'import_$createCount',
            'object': 'contact_import',
          }, 201);
        }
        if (path.length == 3) {
          expect(request.method, 'GET');
          expect(request.url.queryParameters, <String, String>{
            'limit': '30',
            'before': 'import_cursor',
            'status': 'in_progress',
          });
          return _pageResponse(
            _contactImportJson('import_list'),
            hasMore: true,
          );
        }
        expect(request.method, 'GET');
        expect(path.last, 'import/a b');
        return _jsonResponse(_contactImportJson('import/a b'));
      });
      final ContactsResource contacts = ContactsResource(
        ResendTransport(
          apiKey: 're_test',
          client: client,
          baseUri: Uri.parse('https://api.example.test/v1/'),
        ),
      );

      final CreateContactImportRequest full = CreateContactImportRequest(
        bytes: utf8.encode('Email\nperson@example.com\n'),
        filename: 'contacts.csv',
        columnMap: ContactImportColumnMap(email: 'Email'),
        onConflict: ContactImportOnConflict.upsert,
        segments: <ContactSegmentReference>[
          ContactSegmentReference('segment_1'),
        ],
        topics: <ContactTopicSubscription>[
          ContactTopicSubscription(
            id: 'topic_1',
            subscription: TopicSubscription.optIn,
          ),
        ],
      );
      final firstCreate = await contacts.imports.create(full);
      expect(firstCreate.statusCode, 201);
      expect(firstCreate.data.id, 'import_1');
      expect(firstCreate.data.object, 'contact_import');

      final secondCreate = await contacts.imports.create(
        CreateContactImportRequest(
          bytes: utf8.encode('Email\nperson@example.com\n'),
          filename: 'contacts.csv',
        ),
      );
      expect(secondCreate.data.id, 'import_2');

      final list = await contacts.imports.list(
        status: ContactImportStatus.inProgress,
        pagination: PaginationOptions(limit: 30, before: 'import_cursor'),
      );
      expect(list.data.hasMore, isTrue);
      expect(list.data.data.single.id, 'import_list');

      final retrieve = await contacts.imports.retrieve('import/a b');
      expect(retrieve.data.id, 'import/a b');
      expect(requests.last.url.pathSegments.last, 'import/a b');
      expect(requests.last.url.toString(), contains('import%2Fa%20b'));
      expect(requests.map((http.Request item) => item.method), <String>[
        'POST',
        'POST',
        'GET',
        'GET',
      ]);
    },
  );
}

Map<String, Object?> _contactJson(String id) => <String, Object?>{
  'id': id,
  'email': 'person@example.com',
  'first_name': 'Pat',
  'last_name': 'Example',
  'created_at': '2026-07-20T10:11:12.000Z',
  'unsubscribed': false,
  'properties': <String, Object?>{
    'tier': <String, Object?>{'type': 'future_type', 'value': 'gold'},
  },
  'object': 'contact',
};

Map<String, Object?> _contactSegmentJson() => <String, Object?>{
  'id': 'segment_1',
  'name': 'VIP',
  'created_at': '2026-07-20T10:11:12.000Z',
};

Map<String, Object?> _contactTopicJson() => <String, Object?>{
  'id': 'topic_1',
  'name': 'Product updates',
  'description': 'News',
  'subscription': 'future_subscription',
};

Map<String, Object?> _contactImportJson(String id) => <String, Object?>{
  'id': id,
  'status': 'future_status',
  'created_at': '2026-07-20T10:11:12.000Z',
  'completed_at': '2026-07-20T10:12:13.000Z',
  'counts': <String, Object?>{
    'total': 10,
    'created': 4,
    'updated': 3,
    'skipped': 2,
    'failed': 1,
  },
  'object': 'contact_import',
};

http.Response _pageResponse(Object item, {bool hasMore = false}) {
  return _jsonResponse(<String, Object?>{
    'object': 'list',
    'has_more': hasMore,
    'data': <Object?>[item],
  });
}

http.Response _jsonResponse(Object body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: <String, String>{'content-type': 'application/json'},
  );
}
