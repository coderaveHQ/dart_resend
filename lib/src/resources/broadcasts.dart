import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// Parameters for creating a Resend broadcast.
final class CreateBroadcastRequest implements ResendRequest {
  /// Creates broadcast parameters.
  CreateBroadcastRequest({
    required String segmentId,
    required String from,
    required String subject,
    this.name,
    this.html,
    this.text,
    List<String>? replyTo,
    this.previewText,
    this.topicId,
    this.send = false,
    this.scheduledAt,
  }) : segmentId = requireNonBlank(segmentId, 'segmentId'),
       from = requireNonBlank(from, 'from'),
       subject = requireNonBlank(subject, 'subject'),
       replyTo = replyTo == null ? null : List<String>.unmodifiable(replyTo) {
    if (html == null && text == null) {
      throw ArgumentError('Either html or text must be provided.');
    }
    if (scheduledAt != null && !send) {
      throw ArgumentError('scheduledAt requires send to be true.');
    }
  }

  /// Target segment ID.
  final String segmentId;

  /// Sender address.
  final String from;

  /// Email subject.
  final String subject;

  /// Optional dashboard name.
  final String? name;

  /// HTML message body.
  final String? html;

  /// Plain-text message body.
  final String? text;

  /// Reply-to addresses.
  final List<String>? replyTo;

  /// Inbox preview text.
  final String? previewText;

  /// Topic used to respect contact preferences.
  final String? topicId;

  /// Whether to send instead of leaving the broadcast as a draft.
  final bool send;

  /// Optional scheduled send time or relative expression.
  final String? scheduledAt;

  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'segment_id': segmentId,
    'from': from,
    'subject': subject,
    'name': name,
    'html': html,
    'text': text,
    'reply_to': replyTo,
    'preview_text': previewText,
    'topic_id': topicId,
    'send': send,
    'scheduled_at': scheduledAt,
  });
}

/// Parameters for updating a draft broadcast.
final class UpdateBroadcastRequest implements ResendRequest {
  /// Creates broadcast-update parameters.
  UpdateBroadcastRequest({
    this.name,
    this.segmentId,
    this.from,
    this.subject,
    this.html,
    this.text,
    List<String>? replyTo,
    this.previewText,
    this.topicId,
    this.clearTopic = false,
  }) : replyTo = replyTo == null ? null : List<String>.unmodifiable(replyTo) {
    if (topicId != null && clearTopic) {
      throw ArgumentError('topicId and clearTopic cannot both be provided.');
    }
    if (<Object?>[
          name,
          segmentId,
          from,
          subject,
          html,
          text,
          replyTo,
          previewText,
          topicId,
        ].every((Object? value) => value == null) &&
        !clearTopic) {
      throw ArgumentError('At least one broadcast field must be updated.');
    }
  }

  /// Updated dashboard name.
  final String? name;

  /// Updated target segment ID.
  final String? segmentId;

  /// Updated sender.
  final String? from;

  /// Updated subject.
  final String? subject;

  /// Updated HTML body.
  final String? html;

  /// Updated plain-text body.
  final String? text;

  /// Updated reply-to addresses.
  final List<String>? replyTo;

  /// Updated inbox preview text.
  final String? previewText;

  /// Updated topic ID.
  final String? topicId;

  /// Whether to remove the currently assigned topic.
  final bool clearTopic;

  @override
  JsonObject toJson() {
    final JsonObject json = compactJson(<String, Object?>{
      'name': name,
      'segment_id': segmentId,
      'from': from,
      'subject': subject,
      'html': html,
      'text': text,
      'reply_to': replyTo,
      'preview_text': previewText,
      'topic_id': topicId,
    });
    return clearTopic
        ? Map<String, Object?>.unmodifiable(<String, Object?>{
            ...json,
            'topic_id': null,
          })
        : json;
  }
}

/// A Resend broadcast or broadcast list item.
final class Broadcast extends ResendModel {
  /// Decodes a broadcast.
  Broadcast.fromJson(super.json);

  /// Broadcast ID.
  String get id => field<String>('id');

  /// Dashboard name.
  String? get name => optionalField<String>('name');

  /// Target segment ID.
  String? get segmentId => optionalField<String>('segment_id');

  /// Sender returned by a retrieve operation.
  String? get from => optionalField<String>('from');

  /// Subject returned by a retrieve operation.
  String? get subject => optionalField<String>('subject');

  /// Reply-to addresses.
  List<String>? get replyTo => optionalListField<String>('reply_to');

  /// Inbox preview text.
  String? get previewText => optionalField<String>('preview_text');

  /// HTML body.
  String? get html => optionalField<String>('html');

  /// Plain-text body.
  String? get text => optionalField<String>('text');

  /// Raw broadcast status.
  String get status => field<String>('status');

  /// When the broadcast was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// Scheduled delivery time, if scheduled.
  DateTime? get scheduledAt => optionalDateTimeField('scheduled_at');

  /// Actual send time, if sent.
  DateTime? get sentAt => optionalDateTimeField('sent_at');

  /// Topic used for contact preferences.
  String? get topicId => optionalField<String>('topic_id');
}

/// Operations for Resend broadcasts.
final class BroadcastsResource {
  /// Creates a broadcasts resource client.
  BroadcastsResource(this._transport);

  final ResendTransport _transport;

  /// Creates, sends, or schedules a broadcast.
  Future<ResendResponse<ResendId>> create(CreateBroadcastRequest request) {
    return _transport.post<ResendId>(
      pathSegments: <String>['broadcasts'],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Lists broadcasts.
  Future<ResendResponse<ResendPage<Broadcast>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<Broadcast>>(
      pathSegments: <String>['broadcasts'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<Broadcast>.fromJson(json, Broadcast.fromJson),
    );
  }

  /// Retrieves a broadcast by [id].
  Future<ResendResponse<Broadcast>> retrieve(String id) {
    return _transport.get<Broadcast>(
      pathSegments: <String>['broadcasts', requireNonBlank(id, 'id')],
      decode: Broadcast.fromJson,
    );
  }

  /// Updates a draft broadcast.
  Future<ResendResponse<ResendId>> update(
    String id,
    UpdateBroadcastRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>['broadcasts', requireNonBlank(id, 'id')],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Deletes a draft or cancels a scheduled broadcast.
  Future<ResendResponse<ResendDeletion>> delete(String id) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>['broadcasts', requireNonBlank(id, 'id')],
      decode: ResendDeletion.fromJson,
    );
  }

  /// Sends a draft now or at [scheduledAt].
  Future<ResendResponse<ResendId>> send(String id, {String? scheduledAt}) {
    return _transport.post<ResendId>(
      pathSegments: <String>['broadcasts', requireNonBlank(id, 'id'), 'send'],
      body: compactJson(<String, Object?>{'scheduled_at': scheduledAt}),
      decode: ResendId.fromJson,
    );
  }
}
