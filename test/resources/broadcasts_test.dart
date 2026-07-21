import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/resources/broadcasts.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../support/mock_transport.dart';

/// Registers this file's test cases with the package:test runner.
void main() {
  // Verifies: broadcast create and update requests serialize every field.
  test('broadcast create and update requests serialize every field', () {
    final CreateBroadcastRequest create = CreateBroadcastRequest(
      segmentId: 'segment_1',
      from: 'Acme <hello@example.com>',
      subject: 'News',
      name: 'July news',
      html: '<p>News</p>',
      text: 'News',
      replyTo: <String>['reply@example.com'],
      previewText: 'Preview',
      topicId: 'topic_1',
      send: true,
      scheduledAt: 'in 2 hours',
    );
    expect(create.toJson(), <String, Object?>{
      'segment_id': 'segment_1',
      'from': 'Acme <hello@example.com>',
      'subject': 'News',
      'name': 'July news',
      'html': '<p>News</p>',
      'text': 'News',
      'reply_to': <String>['reply@example.com'],
      'preview_text': 'Preview',
      'topic_id': 'topic_1',
      'send': true,
      'scheduled_at': 'in 2 hours',
    });
    final UpdateBroadcastRequest update = UpdateBroadcastRequest(
      name: 'Updated',
      segmentId: 'segment_2',
      from: 'news@example.com',
      subject: 'Updated news',
      html: '<p>Updated</p>',
      text: 'Updated',
      replyTo: <String>['reply@example.com'],
      previewText: 'Updated preview',
      topicId: 'topic_2',
    );
    expect(update.toJson()['topic_id'], 'topic_2');
    expect(UpdateBroadcastRequest(clearTopic: true).toJson(), <String, Object?>{
      'topic_id': null,
    });
  });

  // Verifies: broadcast requests reject conflicting and incomplete parameters.
  test('broadcast requests reject conflicting and incomplete parameters', () {
    expect(
      () => CreateBroadcastRequest(
        segmentId: 'segment',
        from: 'hello@example.com',
        subject: 'No content',
      ),
      throwsArgumentError,
    );
    expect(
      () => CreateBroadcastRequest(
        segmentId: 'segment',
        from: 'hello@example.com',
        subject: 'Scheduled draft',
        text: 'Text',
        scheduledAt: 'tomorrow',
      ),
      throwsArgumentError,
    );
    expect(
      () => CreateBroadcastRequest(
        segmentId: ' ',
        from: 'hello@example.com',
        subject: 'Bad',
        text: 'Text',
      ),
      throwsArgumentError,
    );
    expect(() => UpdateBroadcastRequest(), throwsArgumentError);
    expect(
      () => UpdateBroadcastRequest(topicId: 'topic', clearTopic: true),
      throwsArgumentError,
    );
  });

  // Verifies: broadcast models expose every response field.
  test('broadcast models expose every response field', () {
    final Broadcast broadcast = Broadcast.fromJson(_broadcastJson);
    expect(broadcast.id, 'broadcast_1');
    expect(broadcast.name, 'July news');
    expect(broadcast.segmentId, 'segment_1');
    expect(broadcast.from, 'hello@example.com');
    expect(broadcast.subject, 'News');
    expect(broadcast.replyTo, <String>['reply@example.com']);
    expect(broadcast.previewText, 'Preview');
    expect(broadcast.html, '<p>News</p>');
    expect(broadcast.text, 'News');
    expect(broadcast.status, 'sent');
    expect(broadcast.createdAt, DateTime.utc(2026, 7, 20, 10));
    expect(broadcast.scheduledAt, DateTime.utc(2026, 7, 20, 11));
    expect(broadcast.sentAt, DateTime.utc(2026, 7, 20, 11));
    expect(broadcast.topicId, 'topic_1');

    final Broadcast summary = Broadcast.fromJson(<String, Object?>{
      'id': 'broadcast_2',
      'status': 'draft',
      'created_at': '2026-07-20T10:00:00Z',
    });
    expect(summary.name, isNull);
    expect(summary.segmentId, isNull);
    expect(summary.from, isNull);
    expect(summary.subject, isNull);
    expect(summary.replyTo, isNull);
    expect(summary.previewText, isNull);
    expect(summary.html, isNull);
    expect(summary.text, isNull);
    expect(summary.scheduledAt, isNull);
    expect(summary.sentAt, isNull);
    expect(summary.topicId, isNull);
  });

  // Verifies: broadcasts resource covers every endpoint.
  test('broadcasts resource covers every endpoint', () async {
    var call = 0;
    final BroadcastsResource resource = BroadcastsResource(
      mockTransport((http.Request request) async {
        call++;
        switch (call) {
          case 1:
            expect(request.method, 'POST');
            expect(request.url.path, '/v1/broadcasts');
            return jsonResponse(<String, Object?>{
              'id': 'broadcast_1',
            }, statusCode: 201);
          case 2:
            expect(request.url.queryParameters, <String, String>{'limit': '1'});
            return jsonResponse(<String, Object?>{
              'object': 'list',
              'has_more': false,
              'data': <Object?>[_broadcastJson],
            });
          case 3:
            expect(request.url.path, '/v1/broadcasts/broadcast%2F1');
            return jsonResponse(_broadcastJson);
          case 4:
            expect(request.method, 'PATCH');
            expect(decodedBody(request), <String, Object?>{'name': 'Updated'});
            return jsonResponse(<String, Object?>{'id': 'broadcast_1'});
          case 5:
            expect(request.method, 'DELETE');
            return jsonResponse(<String, Object?>{
              'object': 'broadcast',
              'id': 'broadcast_1',
              'deleted': true,
            });
          default:
            expect(request.url.path, '/v1/broadcasts/broadcast_1/send');
            expect(decodedBody(request), <String, Object?>{
              'scheduled_at': 'tomorrow',
            });
            return jsonResponse(<String, Object?>{'id': 'broadcast_1'});
        }
      }),
    );

    expect(
      (await resource.create(
        CreateBroadcastRequest(
          segmentId: 'segment_1',
          from: 'hello@example.com',
          subject: 'News',
          text: 'News',
        ),
      )).data.id,
      'broadcast_1',
    );
    expect(
      (await resource.list(
        pagination: PaginationOptions(limit: 1),
      )).data.data.single.id,
      'broadcast_1',
    );
    expect((await resource.retrieve('broadcast/1')).data.subject, 'News');
    expect(
      (await resource.update(
        'broadcast_1',
        UpdateBroadcastRequest(name: 'Updated'),
      )).data.id,
      'broadcast_1',
    );
    expect((await resource.delete('broadcast_1')).data.deleted, isTrue);
    expect(
      (await resource.send('broadcast_1', scheduledAt: 'tomorrow')).data.id,
      'broadcast_1',
    );
    expect(() => resource.retrieve(' '), throwsArgumentError);
    expect(
      () => resource.update(' ', UpdateBroadcastRequest(name: 'x')),
      throwsArgumentError,
    );
    expect(() => resource.delete(' '), throwsArgumentError);
    expect(() => resource.send(' '), throwsArgumentError);
  });
}

const Map<String, Object?> _broadcastJson = <String, Object?>{
  'id': 'broadcast_1',
  'name': 'July news',
  'segment_id': 'segment_1',
  'from': 'hello@example.com',
  'subject': 'News',
  'reply_to': <String>['reply@example.com'],
  'preview_text': 'Preview',
  'html': '<p>News</p>',
  'text': 'News',
  'status': 'sent',
  'created_at': '2026-07-20T10:00:00Z',
  'scheduled_at': '2026-07-20T11:00:00Z',
  'sent_at': '2026-07-20T11:00:00Z',
  'topic_id': 'topic_1',
};
