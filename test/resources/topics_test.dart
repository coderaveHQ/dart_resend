import 'dart:convert';

import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/core/transport.dart';
import 'package:dart_resend/src/resources/topics.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('topic request models', () {
    test('serialize documented enum values', () {
      expect(TopicSubscription.optIn.value, 'opt_in');
      expect(TopicSubscription.optOut.value, 'opt_out');
      expect(TopicVisibility.public.value, 'public');
      expect(TopicVisibility.private.value, 'private');
    });

    test('create request validates and omits absent optional fields', () {
      final CreateTopicRequest full = CreateTopicRequest(
        name: 'Product updates',
        defaultSubscription: TopicSubscription.optIn,
        description: 'Release and product news',
        visibility: TopicVisibility.public,
      );
      expect(full.name, 'Product updates');
      expect(full.defaultSubscription, TopicSubscription.optIn);
      expect(full.description, 'Release and product news');
      expect(full.visibility, TopicVisibility.public);
      expect(full.toJson(), <String, Object?>{
        'name': 'Product updates',
        'default_subscription': 'opt_in',
        'description': 'Release and product news',
        'visibility': 'public',
      });

      expect(
        CreateTopicRequest(
          name: 'Security',
          defaultSubscription: TopicSubscription.optOut,
        ).toJson(),
        <String, Object?>{
          'name': 'Security',
          'default_subscription': 'opt_out',
        },
      );
      expect(
        () => CreateTopicRequest(
          name: ' ',
          defaultSubscription: TopicSubscription.optIn,
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateTopicRequest(
          name: 'x' * 51,
          defaultSubscription: TopicSubscription.optIn,
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateTopicRequest(
          name: 'Valid',
          defaultSubscription: TopicSubscription.optIn,
          description: 'x' * 201,
        ),
        throwsArgumentError,
      );
      expect(
        CreateTopicRequest(
          name: 'Valid',
          defaultSubscription: TopicSubscription.optIn,
          description: '',
        ).toJson()['description'],
        '',
      );
    });

    test('update request requires and validates a change', () {
      final UpdateTopicRequest full = UpdateTopicRequest(
        name: 'Announcements',
        description: 'Important announcements',
        visibility: TopicVisibility.private,
      );
      expect(full.name, 'Announcements');
      expect(full.description, 'Important announcements');
      expect(full.visibility, TopicVisibility.private);
      expect(full.toJson(), <String, Object?>{
        'name': 'Announcements',
        'description': 'Important announcements',
        'visibility': 'private',
      });
      expect(UpdateTopicRequest(description: '').toJson(), <String, Object?>{
        'description': '',
      });
      expect(
        UpdateTopicRequest(visibility: TopicVisibility.public).toJson(),
        <String, Object?>{'visibility': 'public'},
      );
      expect(() => UpdateTopicRequest(), throwsArgumentError);
      expect(() => UpdateTopicRequest(name: ' '), throwsArgumentError);
      expect(
        () => UpdateTopicRequest(description: 'x' * 201),
        throwsArgumentError,
      );
    });
  });

  test('Topic exposes typed fields and preserves unknown response values', () {
    final Topic topic = Topic.fromJson(<String, Object?>{
      'id': 'topic_1',
      'name': 'News',
      'description': 'Company news',
      'default_subscription': 'future_default',
      'visibility': 'future_visibility',
      'created_at': '2026-07-20T10:11:12.000Z',
      'object': 'topic',
      'future_field': true,
    });

    expect(topic.id, 'topic_1');
    expect(topic.name, 'News');
    expect(topic.description, 'Company news');
    expect(topic.defaultSubscription, 'future_default');
    expect(topic.visibility, 'future_visibility');
    expect(topic.createdAt, DateTime.utc(2026, 7, 20, 10, 11, 12));
    expect(topic.object, 'topic');
    expect(topic.json['future_field'], isTrue);
    expect(() => topic.json['name'] = 'changed', throwsUnsupportedError);

    final Topic minimal = Topic.fromJson(<String, Object?>{
      'id': 'topic_2',
      'name': 'Minimal',
      'default_subscription': 'opt_in',
      'visibility': 'public',
      'created_at': '2026-07-20T10:11:12.000Z',
    });
    expect(minimal.description, isNull);
    expect(minimal.object, isNull);
  });

  test('TopicsResource sends every documented operation', () async {
    final List<http.Request> requests = <http.Request>[];
    final MockClient client = MockClient((http.Request request) async {
      requests.add(request);
      final List<String> path = request.url.pathSegments;

      if (request.method == 'POST') {
        expect(path, <String>['v1', 'topics']);
        expect(jsonDecode(request.body), <String, Object?>{
          'name': 'Product updates',
          'default_subscription': 'opt_in',
          'description': 'News',
          'visibility': 'public',
        });
        return _jsonResponse(<String, Object?>{
          'id': 'topic_created',
          'object': 'topic',
        }, 201);
      }
      if (request.method == 'GET' && path.length == 2) {
        expect(request.url.queryParameters, <String, String>{'limit': '25'});
        return _jsonResponse(<String, Object?>{
          'object': 'list',
          'has_more': true,
          'data': <Object?>[_topicJson('topic_list')],
        });
      }
      if (request.method == 'GET') {
        return _jsonResponse(_topicJson('topic/a b'));
      }
      if (request.method == 'PATCH') {
        expect(jsonDecode(request.body), <String, Object?>{
          'name': 'Announcements',
          'description': '',
          'visibility': 'private',
        });
        return _jsonResponse(<String, Object?>{'id': 'topic/a b'});
      }
      expect(request.method, 'DELETE');
      return _jsonResponse(<String, Object?>{
        'id': 'topic/a b',
        'object': 'topic',
        'deleted': true,
      });
    });
    final TopicsResource topics = TopicsResource(
      ResendTransport(
        apiKey: 're_test',
        client: client,
        baseUri: Uri.parse('https://api.example.test/v1/'),
      ),
    );

    final create = await topics.create(
      CreateTopicRequest(
        name: 'Product updates',
        defaultSubscription: TopicSubscription.optIn,
        description: 'News',
        visibility: TopicVisibility.public,
      ),
    );
    expect(create.statusCode, 201);
    expect(create.data.id, 'topic_created');
    expect(create.data.object, 'topic');

    final list = await topics.list(pagination: PaginationOptions(limit: 25));
    expect(list.data.hasMore, isTrue);
    expect(list.data.object, 'list');
    expect(list.data.data.single.id, 'topic_list');

    final retrieve = await topics.retrieve('topic/a b');
    expect(retrieve.data.id, 'topic/a b');
    expect(requests[2].url.pathSegments.last, 'topic/a b');
    expect(requests[2].url.toString(), contains('topic%2Fa%20b'));

    final update = await topics.update(
      'topic/a b',
      UpdateTopicRequest(
        name: 'Announcements',
        description: '',
        visibility: TopicVisibility.private,
      ),
    );
    expect(update.data.id, 'topic/a b');

    final deletion = await topics.delete('topic/a b');
    expect(deletion.data.id, 'topic/a b');
    expect(deletion.data.object, 'topic');
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

Map<String, Object?> _topicJson(String id) => <String, Object?>{
  'id': id,
  'name': 'Product updates',
  'description': 'News',
  'default_subscription': 'opt_in',
  'visibility': 'public',
  'created_at': '2026-07-20T10:11:12.000Z',
  'object': 'topic',
};

http.Response _jsonResponse(Object body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: <String, String>{'content-type': 'application/json'},
  );
}
