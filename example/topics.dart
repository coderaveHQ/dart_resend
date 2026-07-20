import 'package:dart_resend/dart_resend.dart';

/// Creates a subscription topic.
Future<ResendResponse<ResendId>> createTopic(Resend resend) {
  return resend.topics.create(
    CreateTopicRequest(
      name: 'Product updates',
      defaultSubscription: TopicSubscription.optIn,
      description: 'News about product improvements.',
      visibility: TopicVisibility.public,
    ),
  );
}

/// Lists subscription topics.
Future<ResendResponse<ResendPage<Topic>>> listTopics(Resend resend) {
  return resend.topics.list(pagination: PaginationOptions(limit: 25));
}

/// Retrieves a subscription topic.
Future<ResendResponse<Topic>> retrieveTopic(Resend resend, String topicId) {
  return resend.topics.retrieve(topicId);
}

/// Updates a subscription topic.
Future<ResendResponse<ResendId>> updateTopic(Resend resend, String topicId) {
  return resend.topics.update(
    topicId,
    UpdateTopicRequest(
      name: 'Platform updates',
      description: 'Important platform changes.',
      visibility: TopicVisibility.private,
    ),
  );
}

/// Deletes a subscription topic.
Future<ResendResponse<ResendDeletion>> deleteTopic(
  Resend resend,
  String topicId,
) {
  return resend.topics.delete(topicId);
}
