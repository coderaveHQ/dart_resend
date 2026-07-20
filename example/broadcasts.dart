import 'package:dart_resend/dart_resend.dart';

/// Creates a broadcast draft for a segment.
Future<ResendResponse<ResendId>> createBroadcastDraft(Resend resend) {
  return resend.broadcasts.create(
    CreateBroadcastRequest(
      segmentId: 'seg_customers',
      from: 'Acme <news@example.com>',
      subject: 'July product news',
      name: 'July newsletter',
      html: '<h1>What is new</h1>',
      text: 'What is new',
      replyTo: <String>['support@example.com'],
      previewText: 'The latest improvements from Acme.',
      topicId: 'topic_product_updates',
    ),
  );
}

/// Creates and schedules a broadcast in one operation.
Future<ResendResponse<ResendId>> createScheduledBroadcast(Resend resend) {
  return resend.broadcasts.create(
    CreateBroadcastRequest(
      segmentId: 'seg_customers',
      from: 'Acme <news@example.com>',
      subject: 'Tomorrow at Acme',
      text: 'A quick update.',
      send: true,
      scheduledAt: 'tomorrow at 9am',
    ),
  );
}

/// Lists broadcasts with cursor pagination.
Future<ResendResponse<ResendPage<Broadcast>>> listBroadcasts(Resend resend) {
  return resend.broadcasts.list(pagination: PaginationOptions(limit: 25));
}

/// Retrieves a broadcast.
Future<ResendResponse<Broadcast>> retrieveBroadcast(
  Resend resend,
  String broadcastId,
) {
  return resend.broadcasts.retrieve(broadcastId);
}

/// Updates a broadcast draft.
Future<ResendResponse<ResendId>> updateBroadcast(
  Resend resend,
  String broadcastId,
) {
  return resend.broadcasts.update(
    broadcastId,
    UpdateBroadcastRequest(
      name: 'July newsletter — final',
      subject: 'Everything new in July',
      previewText: 'See every improvement.',
      clearTopic: true,
    ),
  );
}

/// Sends a draft now or schedules its delivery.
Future<ResendResponse<ResendId>> sendBroadcast(
  Resend resend,
  String broadcastId,
) {
  return resend.broadcasts.send(broadcastId, scheduledAt: 'in 30 minutes');
}

/// Deletes a draft or cancels a scheduled broadcast.
Future<ResendResponse<ResendDeletion>> deleteBroadcast(
  Resend resend,
  String broadcastId,
) {
  return resend.broadcasts.delete(broadcastId);
}
