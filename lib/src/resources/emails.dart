import 'dart:convert';

import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// Controls whether invalid entries reject an entire batch.
enum BatchValidationMode implements ResendWireValue {
  /// Reject the entire batch when any email is invalid.
  strict('strict'),

  /// Send valid emails and report invalid entries individually.
  permissive('permissive');

  const BatchValidationMode(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// Controls how inline images are represented in a received email's HTML.
enum ReceivedEmailHtmlFormat implements ResendWireValue {
  /// Replace inline images with Base64 data URIs.
  dataUri('data_uri'),

  /// Preserve the original `cid:` references.
  cid('cid');

  const ReceivedEmailHtmlFormat(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// A key/value tag attached to an email.
final class EmailTag implements ResendRequest {
  /// Creates and validates an email tag.
  EmailTag({required String name, required String value})
    : name = _tagPart(name, 'name'),
      value = _tagPart(value, 'value');

  /// Decodes a tag returned by Resend.
  factory EmailTag.fromJson(JsonObject json) {
    final ResendModel reader = _JsonReader(json);
    return EmailTag(
      name: reader.field<String>('name'),
      value: reader.field<String>('value'),
    );
  }

  /// The tag name.
  final String name;

  /// The tag value.
  final String value;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => <String, Object?>{'name': name, 'value': value};
}

/// A published template used to render an email.
final class EmailTemplate implements ResendRequest {
  /// Creates template parameters.
  EmailTemplate({required String id, Map<String, Object> variables = const {}})
    : id = requireNonBlank(id, 'id'),
      variables = _templateVariables(variables);

  /// The published template ID or alias.
  final String id;

  /// Values supplied to the template's variables.
  final Map<String, Object> variables;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => <String, Object?>{
    'id': id,
    if (variables.isNotEmpty) 'variables': variables,
  };
}

/// An attachment supplied while sending an email.
final class EmailAttachment implements ResendRequest {
  /// Creates an attachment from one validated content source.
  EmailAttachment._({
    this.content,
    this.path,
    this.filename,
    this.contentType,
    this.contentId,
  });

  /// Creates an attachment from raw bytes.
  factory EmailAttachment.bytes(
    List<int> bytes, {
    String? filename,
    String? contentType,
    String? contentId,
  }) {
    return EmailAttachment._(
      content: base64Encode(bytes),
      filename: _optionalNonBlank(filename, 'filename'),
      contentType: _optionalNonBlank(contentType, 'contentType'),
      contentId: _optionalNonBlank(contentId, 'contentId'),
    );
  }

  /// Creates an attachment from Base64-encoded [content].
  factory EmailAttachment.base64(
    String content, {
    String? filename,
    String? contentType,
    String? contentId,
  }) {
    if (content.isEmpty) {
      throw ArgumentError.value(content, 'content', 'Must not be empty.');
    }
    final String normalized;
    try {
      normalized = base64.normalize(content);
      base64Decode(normalized);
    } on FormatException catch (error) {
      throw ArgumentError.value(content, 'content', error.message);
    }
    return EmailAttachment._(
      content: normalized,
      filename: _optionalNonBlank(filename, 'filename'),
      contentType: _optionalNonBlank(contentType, 'contentType'),
      contentId: _optionalNonBlank(contentId, 'contentId'),
    );
  }

  /// Creates an attachment hosted at an HTTP(S) [path].
  factory EmailAttachment.remote(
    Uri path, {
    String? filename,
    String? contentType,
    String? contentId,
  }) {
    if (!path.hasScheme ||
        !path.hasAuthority ||
        (path.scheme != 'http' && path.scheme != 'https')) {
      throw ArgumentError.value(
        path,
        'path',
        'Must be an absolute HTTP or HTTPS URI.',
      );
    }
    return EmailAttachment._(
      path: path,
      filename: _optionalNonBlank(filename, 'filename'),
      contentType: _optionalNonBlank(contentType, 'contentType'),
      contentId: _optionalNonBlank(contentId, 'contentId'),
    );
  }

  /// Base64-encoded content, when this is an inline attachment.
  final String? content;

  /// Remote content URI, when this is a hosted attachment.
  final Uri? path;

  /// Filename presented to the recipient.
  final String? filename;

  /// Explicit MIME type.
  final String? contentType;

  /// Content ID used by an inline `cid:` reference.
  final String? contentId;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'content': content,
    'path': path?.toString(),
    'filename': filename,
    'content_type': contentType,
    'content_id': contentId,
  });
}

/// Shared validated payload state for single and batch email requests.
abstract base class _EmailRequest implements ResendRequest {
  /// Validates common addressing, content, scheduling, and metadata fields.
  _EmailRequest({
    required this.from,
    required List<String> to,
    required this.subject,
    required this.html,
    required this.text,
    required this.template,
    List<String>? cc,
    List<String>? bcc,
    List<String>? replyTo,
    Map<String, String>? headers,
    String? scheduledAt,
    List<EmailAttachment>? attachments,
    List<EmailTag>? tags,
    String? topicId,
  }) : to = _recipients(to, 'to', maximum: 50),
       cc = _optionalRecipients(cc, 'cc'),
       bcc = _optionalRecipients(bcc, 'bcc'),
       replyTo = _optionalRecipients(replyTo, 'replyTo'),
       headers = _headers(headers),
       scheduledAt = _optionalNonBlank(scheduledAt, 'scheduledAt'),
       attachments = _attachments(attachments),
       tags = _nonEmptyCopy(tags, 'tags'),
       topicId = _optionalNonBlank(topicId, 'topicId');

  final String? from;
  final List<String> to;
  final String? subject;
  final String? html;
  final String? text;
  final EmailTemplate? template;
  final List<String>? cc;
  final List<String>? bcc;
  final List<String>? replyTo;
  final Map<String, String>? headers;
  final String? scheduledAt;
  final List<EmailAttachment>? attachments;
  final List<EmailTag>? tags;
  final String? topicId;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'from': from,
    'to': to,
    'subject': subject,
    'html': html,
    'text': text,
    'template': template?.toJson(),
    'cc': cc,
    'bcc': bcc,
    'reply_to': replyTo,
    'headers': headers,
    'scheduled_at': scheduledAt,
    'attachments': attachments
        ?.map((EmailAttachment value) => value.toJson())
        .toList(growable: false),
    'tags': tags
        ?.map((EmailTag value) => value.toJson())
        .toList(growable: false),
    'topic_id': topicId,
  });
}

/// Parameters for sending one email.
final class SendEmailRequest extends _EmailRequest {
  /// Creates a single-send payload after factory-specific validation.
  SendEmailRequest._({
    required super.from,
    required super.to,
    required super.subject,
    required super.html,
    required super.text,
    required super.template,
    super.cc,
    super.bcc,
    super.replyTo,
    super.headers,
    super.scheduledAt,
    super.attachments,
    super.tags,
    super.topicId,
  });

  /// Creates an email rendered from raw HTML, text, or both.
  factory SendEmailRequest.raw({
    required String from,
    required List<String> to,
    required String subject,
    String? html,
    String? text,
    List<String>? cc,
    List<String>? bcc,
    List<String>? replyTo,
    Map<String, String>? headers,
    String? scheduledAt,
    List<EmailAttachment>? attachments,
    List<EmailTag>? tags,
    String? topicId,
  }) {
    _requireContent(html, text);
    return SendEmailRequest._(
      from: requireNonBlank(from, 'from'),
      to: to,
      subject: requireNonBlank(subject, 'subject'),
      html: html,
      text: text,
      template: null,
      cc: cc,
      bcc: bcc,
      replyTo: replyTo,
      headers: headers,
      scheduledAt: scheduledAt,
      attachments: attachments,
      tags: tags,
      topicId: topicId,
    );
  }

  /// Creates an email rendered from a published [template].
  ///
  /// [from], [subject], and [replyTo] override the template defaults. Resend
  /// requires the payload to provide any value that the template omits.
  factory SendEmailRequest.template({
    required EmailTemplate template,
    required List<String> to,
    String? from,
    String? subject,
    List<String>? cc,
    List<String>? bcc,
    List<String>? replyTo,
    Map<String, String>? headers,
    String? scheduledAt,
    List<EmailAttachment>? attachments,
    List<EmailTag>? tags,
    String? topicId,
  }) {
    return SendEmailRequest._(
      from: _optionalNonBlank(from, 'from'),
      to: to,
      subject: _optionalNonBlank(subject, 'subject'),
      html: null,
      text: null,
      template: template,
      cc: cc,
      bcc: bcc,
      replyTo: replyTo,
      headers: headers,
      scheduledAt: scheduledAt,
      attachments: attachments,
      tags: tags,
      topicId: topicId,
    );
  }
}

/// Parameters for one item in a batch send.
///
/// Batch items support tags. Attachments and scheduling remain unsupported by
/// the Resend batch endpoint.
final class BatchEmailRequest extends _EmailRequest {
  /// Creates one batch item after factory-specific validation.
  BatchEmailRequest._({
    required super.from,
    required super.to,
    required super.subject,
    required super.html,
    required super.text,
    required super.template,
    super.cc,
    super.bcc,
    super.replyTo,
    super.headers,
    super.tags,
    super.topicId,
  });

  /// Creates a raw-content batch email.
  factory BatchEmailRequest.raw({
    required String from,
    required List<String> to,
    required String subject,
    String? html,
    String? text,
    List<String>? cc,
    List<String>? bcc,
    List<String>? replyTo,
    Map<String, String>? headers,
    List<EmailTag>? tags,
    String? topicId,
  }) {
    _requireContent(html, text);
    return BatchEmailRequest._(
      from: requireNonBlank(from, 'from'),
      to: to,
      subject: requireNonBlank(subject, 'subject'),
      html: html,
      text: text,
      template: null,
      cc: cc,
      bcc: bcc,
      replyTo: replyTo,
      headers: headers,
      tags: tags,
      topicId: topicId,
    );
  }

  /// Creates a template-based batch email.
  factory BatchEmailRequest.template({
    required EmailTemplate template,
    required List<String> to,
    String? from,
    String? subject,
    List<String>? cc,
    List<String>? bcc,
    List<String>? replyTo,
    Map<String, String>? headers,
    List<EmailTag>? tags,
    String? topicId,
  }) {
    return BatchEmailRequest._(
      from: _optionalNonBlank(from, 'from'),
      to: to,
      subject: _optionalNonBlank(subject, 'subject'),
      html: null,
      text: null,
      template: template,
      cc: cc,
      bcc: bcc,
      replyTo: replyTo,
      headers: headers,
      tags: tags,
      topicId: topicId,
    );
  }
}

/// Parameters for moving a scheduled email to a new time.
final class UpdateEmailRequest implements ResendRequest {
  /// Creates schedule-update parameters.
  UpdateEmailRequest({required String scheduledAt})
    : scheduledAt = requireNonBlank(scheduledAt, 'scheduledAt');

  /// ISO-8601 timestamp or supported natural-language schedule expression.
  final String scheduledAt;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => <String, Object?>{'scheduled_at': scheduledAt};
}

/// Details reported by a receiving server for a bounced email.
final class BounceDetails extends ResendModel {
  /// Decodes bounce details.
  BounceDetails.fromJson(super.json);

  /// SMTP diagnostic responses, when supplied.
  List<String>? get diagnosticCodes =>
      optionalListField<String>('diagnosticCode');

  /// Human-readable bounce message.
  String? get message => optionalField<String>('message');

  /// Provider-specific bounce subtype.
  String? get subType => optionalField<String>('subType');

  /// Broad bounce type such as `Permanent` or `Transient`.
  String? get type => optionalField<String>('type');
}

/// A sent email returned by retrieve or list operations.
final class SentEmail extends ResendModel {
  /// Decodes a sent email.
  SentEmail.fromJson(super.json);

  /// Resource type; list items may omit it.
  String? get object => optionalField<String>('object');

  /// Resend email ID.
  String get id => field<String>('id');

  /// RFC Message-ID used for email threading.
  String get messageId => field<String>('message_id');

  /// Recipient addresses.
  List<String> get to => listField<String>('to');

  /// Sender address, optionally including a display name.
  String get from => field<String>('from');

  /// When the email was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// Subject line.
  String get subject => field<String>('subject');

  /// HTML content when retained and returned.
  String? get html => optionalField<String>('html');

  /// Plain-text content when retained and returned.
  String? get text => optionalField<String>('text');

  /// Blind-carbon-copy recipients.
  List<String>? get bcc => optionalListField<String>('bcc');

  /// Carbon-copy recipients.
  List<String>? get cc => optionalListField<String>('cc');

  /// Reply-to addresses.
  List<String>? get replyTo => optionalListField<String>('reply_to');

  /// Most recent delivery event, preserved as a forward-compatible string.
  String get lastEvent => field<String>('last_event');

  /// Scheduled delivery time, if the email is scheduled.
  DateTime? get scheduledAt => optionalDateTimeField('scheduled_at');

  /// Topic associated with the email.
  String? get topicId => optionalField<String>('topic_id');

  /// Tags associated with the email.
  List<EmailTag>? get tags =>
      _optionalModels<EmailTag>(this, 'tags', EmailTag.fromJson);

  /// Bounce details when Resend includes them in the response.
  BounceDetails? get bounce {
    final JsonObject? value = optionalObjectField('bounce');
    return value == null ? null : BounceDetails.fromJson(value);
  }
}

/// One successfully accepted email in a batch response.
final class BatchEmailSuccess extends ResendModel {
  /// Decodes a batch success.
  BatchEmailSuccess.fromJson(super.json);

  /// Resend email ID.
  String get id => field<String>('id');
}

/// One invalid email in a permissive batch response.
final class BatchEmailError extends ResendModel {
  /// Decodes a batch error.
  BatchEmailError.fromJson(super.json);

  /// Zero-based index of the invalid request.
  int get index => field<int>('index');

  /// Validation error message.
  String get message => field<String>('message');
}

/// Result of a strict or permissive batch send.
final class BatchEmailResult extends ResendModel {
  /// Decodes a batch result.
  BatchEmailResult.fromJson(super.json);

  /// Emails accepted for delivery.
  List<BatchEmailSuccess> get data =>
      _models<BatchEmailSuccess>(this, 'data', BatchEmailSuccess.fromJson);

  /// Invalid entries. This is empty for strict responses.
  List<BatchEmailError> get errors =>
      _optionalModels<BatchEmailError>(
        this,
        'errors',
        BatchEmailError.fromJson,
      ) ??
      const <BatchEmailError>[];
}

/// Attachment metadata returned by a dedicated attachment endpoint.
final class RetrievedEmailAttachment extends ResendModel {
  /// Decodes attachment metadata.
  RetrievedEmailAttachment.fromJson(super.json);

  /// Resource type when returned by a retrieve operation.
  String? get object => optionalField<String>('object');

  /// Attachment ID.
  String get id => field<String>('id');

  /// Original filename when present.
  String? get filename => optionalField<String>('filename');

  /// Attachment size in bytes.
  int get size => field<int>('size');

  /// MIME type.
  String get contentType => field<String>('content_type');

  /// Content disposition, currently `inline` or `attachment`, when supplied.
  String? get contentDisposition =>
      optionalField<String>('content_disposition');

  /// Content ID for inline attachments.
  String? get contentId => optionalField<String>('content_id');

  /// Temporary signed download URL.
  Uri get downloadUrl => Uri.parse(field<String>('download_url'));

  /// Expiration time of [downloadUrl].
  DateTime get expiresAt => dateTimeField('expires_at');
}

/// Attachment metadata embedded in a received-email response.
final class InboundEmailAttachment extends ResendModel {
  /// Decodes inbound attachment metadata.
  InboundEmailAttachment.fromJson(super.json);

  /// Attachment ID.
  String get id => field<String>('id');

  /// Original filename, when available.
  String? get filename => optionalField<String>('filename');

  /// Attachment size in bytes.
  int get size => field<int>('size');

  /// MIME type.
  String get contentType => field<String>('content_type');

  /// Raw content disposition, which may be absent.
  String? get contentDisposition =>
      optionalField<String>('content_disposition');

  /// Content ID for an inline attachment.
  String? get contentId => optionalField<String>('content_id');
}

/// Signed download information for an original received email.
final class RawReceivedEmail extends ResendModel {
  /// Decodes raw-email download metadata.
  RawReceivedEmail.fromJson(super.json);

  /// Temporary signed download URL for the original RFC 822 message.
  Uri get downloadUrl => Uri.parse(field<String>('download_url'));

  /// Expiration time of [downloadUrl].
  DateTime get expiresAt => dateTimeField('expires_at');
}

/// A received email returned by list or retrieve operations.
final class ReceivedEmail extends ResendModel {
  /// Decodes a received email.
  ReceivedEmail.fromJson(super.json);

  /// Resource type; list items may omit it.
  String? get object => optionalField<String>('object');

  /// Received-email ID.
  String get id => field<String>('id');

  /// RFC Message-ID used for threading.
  String get messageId => field<String>('message_id');

  /// Recipient addresses.
  List<String> get to => listField<String>('to');

  /// Sender address.
  String get from => field<String>('from');

  /// Subject, when one was supplied.
  String? get subject => optionalField<String>('subject');

  /// When the email was received.
  DateTime get createdAt => dateTimeField('created_at');

  /// Blind-carbon-copy recipients.
  List<String>? get bcc => optionalListField<String>('bcc');

  /// Carbon-copy recipients.
  List<String>? get cc => optionalListField<String>('cc');

  /// Reply-to addresses.
  List<String>? get replyTo => optionalListField<String>('reply_to');

  /// Team addresses for which Resend accepted this email.
  List<String>? get receivedFor => optionalListField<String>('received_for');

  /// HTML content. Its inline-image representation follows the requested
  /// [ReceivedEmailHtmlFormat].
  String? get html => optionalField<String>('html');

  /// Raw inline-image format echoed by retrieve operations, when supplied.
  String? get htmlFormat => optionalField<String>('html_format');

  /// Plain-text content.
  String? get text => optionalField<String>('text');

  /// Original email headers.
  JsonObject? get headers => optionalObjectField('headers');

  /// Raw-message download metadata.
  RawReceivedEmail? get raw {
    final JsonObject? value = optionalObjectField('raw');
    return value == null ? null : RawReceivedEmail.fromJson(value);
  }

  /// Embedded attachment metadata.
  List<InboundEmailAttachment> get attachments =>
      _models<InboundEmailAttachment>(
        this,
        'attachments',
        InboundEmailAttachment.fromJson,
      );
}

/// Sending, scheduling, receiving, and attachment operations for email.
final class EmailsResource {
  /// Creates an emails resource client.
  EmailsResource(this._transport);

  /// Transport used to execute email endpoint requests.
  final ResendTransport _transport;

  /// Sends one email.
  Future<ResendResponse<ResendId>> send(
    SendEmailRequest request, {
    String? idempotencyKey,
  }) {
    return _transport.post<ResendId>(
      pathSegments: <String>['emails'],
      body: request.toJson(),
      idempotencyKey: _idempotencyKey(idempotencyKey),
      decode: ResendId.fromJson,
    );
  }

  /// Sends between 1 and 100 emails in one API request.
  Future<ResendResponse<BatchEmailResult>> sendBatch(
    List<BatchEmailRequest> requests, {
    BatchValidationMode validation = BatchValidationMode.strict,
    String? idempotencyKey,
  }) {
    if (requests.isEmpty || requests.length > 100) {
      throw RangeError.range(requests.length, 1, 100, 'requests');
    }
    return _transport.post<BatchEmailResult>(
      pathSegments: <String>['emails', 'batch'],
      body: List<Object?>.unmodifiable(
        requests.map((BatchEmailRequest request) => request.toJson()),
      ),
      headers: <String, String>{'x-batch-validation': validation.value},
      idempotencyKey: _idempotencyKey(idempotencyKey),
      decode: BatchEmailResult.fromJson,
    );
  }

  /// Lists sent emails.
  Future<ResendResponse<ResendPage<SentEmail>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<SentEmail>>(
      pathSegments: <String>['emails'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<SentEmail>.fromJson(json, SentEmail.fromJson),
    );
  }

  /// Retrieves one sent email by [id].
  Future<ResendResponse<SentEmail>> retrieve(String id) {
    return _transport.get<SentEmail>(
      pathSegments: <String>['emails', requireNonBlank(id, 'id')],
      decode: SentEmail.fromJson,
    );
  }

  /// Updates the delivery time of a scheduled email.
  Future<ResendResponse<ResendId>> update(
    String id,
    UpdateEmailRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>['emails', requireNonBlank(id, 'id')],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Cancels a scheduled email.
  Future<ResendResponse<ResendId>> cancel(String id) {
    return _transport.post<ResendId>(
      pathSegments: <String>['emails', requireNonBlank(id, 'id'), 'cancel'],
      decode: ResendId.fromJson,
    );
  }

  /// Lists attachments belonging to a sent email.
  Future<ResendResponse<ResendPage<RetrievedEmailAttachment>>>
  listSentAttachments(String emailId, {PaginationOptions? pagination}) {
    return _listAttachments(<String>[
      'emails',
      requireNonBlank(emailId, 'emailId'),
      'attachments',
    ], pagination);
  }

  /// Retrieves one attachment belonging to a sent email.
  Future<ResendResponse<RetrievedEmailAttachment>> retrieveSentAttachment(
    String emailId,
    String attachmentId,
  ) {
    return _retrieveAttachment(<String>[
      'emails',
      requireNonBlank(emailId, 'emailId'),
      'attachments',
      requireNonBlank(attachmentId, 'attachmentId'),
    ]);
  }

  /// Lists emails received by the authenticated team.
  Future<ResendResponse<ResendPage<ReceivedEmail>>> listReceived({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<ReceivedEmail>>(
      pathSegments: <String>['emails', 'receiving'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<ReceivedEmail>.fromJson(json, ReceivedEmail.fromJson),
    );
  }

  /// Retrieves one received email.
  Future<ResendResponse<ReceivedEmail>> retrieveReceived(
    String id, {
    ReceivedEmailHtmlFormat? htmlFormat,
  }) {
    return _transport.get<ReceivedEmail>(
      pathSegments: <String>['emails', 'receiving', requireNonBlank(id, 'id')],
      query: htmlFormat == null
          ? null
          : <String, String>{'html_format': htmlFormat.value},
      decode: ReceivedEmail.fromJson,
    );
  }

  /// Lists attachments belonging to a received email.
  Future<ResendResponse<ResendPage<RetrievedEmailAttachment>>>
  listReceivedAttachments(String emailId, {PaginationOptions? pagination}) {
    return _listAttachments(<String>[
      'emails',
      'receiving',
      requireNonBlank(emailId, 'emailId'),
      'attachments',
    ], pagination);
  }

  /// Retrieves one attachment belonging to a received email.
  Future<ResendResponse<RetrievedEmailAttachment>> retrieveReceivedAttachment(
    String emailId,
    String attachmentId,
  ) {
    return _retrieveAttachment(<String>[
      'emails',
      'receiving',
      requireNonBlank(emailId, 'emailId'),
      'attachments',
      requireNonBlank(attachmentId, 'attachmentId'),
    ]);
  }

  /// Lists attachments for an email in the selected sent/received collection.
  Future<ResendResponse<ResendPage<RetrievedEmailAttachment>>> _listAttachments(
    List<String> path,
    PaginationOptions? pagination,
  ) {
    return _transport.get<ResendPage<RetrievedEmailAttachment>>(
      pathSegments: path,
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<RetrievedEmailAttachment>.fromJson(
            json,
            RetrievedEmailAttachment.fromJson,
          ),
    );
  }

  /// Retrieves an attachment from the selected sent/received collection.
  Future<ResendResponse<RetrievedEmailAttachment>> _retrieveAttachment(
    List<String> path,
  ) {
    return _transport.get<RetrievedEmailAttachment>(
      pathSegments: path,
      decode: RetrievedEmailAttachment.fromJson,
    );
  }
}

/// Adapts nested raw JSON to the typed readers on [ResendModel].
final class _JsonReader extends ResendModel {
  /// Creates a reader over immutable nested [json].
  _JsonReader(super.json);
}

/// Validates one email-tag component against Resend's wire constraints.
String _tagPart(String value, String name) {
  if (!_tagPattern.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      name,
      'Must contain 1-256 ASCII letters, digits, underscores, or dashes.',
    );
  }
  return value;
}

/// Validates and freezes JSON-compatible template substitutions.
Map<String, Object> _templateVariables(Map<String, Object> values) {
  final Map<String, Object> result = <String, Object>{};
  for (final MapEntry<String, Object> entry in values.entries) {
    if (!_templateVariablePattern.hasMatch(entry.key)) {
      throw ArgumentError.value(
        entry.key,
        'variables',
        'Keys must contain 1-50 ASCII letters, digits, or underscores.',
      );
    }
    final Object value = entry.value;
    if (value is String) {
      if (value.length > 2000) {
        throw ArgumentError.value(
          value,
          'variables',
          'String values must not exceed 2000 characters.',
        );
      }
    } else if (value is num) {
      if (!value.isFinite || value.abs() > _maximumSafeInteger) {
        throw ArgumentError.value(
          value,
          'variables',
          'Numbers must be finite JavaScript-safe values.',
        );
      }
    } else {
      throw ArgumentError.value(
        value,
        'variables',
        'Values must be strings or numbers.',
      );
    }
    result[entry.key] = value;
  }
  return Map<String, Object>.unmodifiable(result);
}

/// Requires at least one raw HTML or plain-text body representation.
void _requireContent(String? html, String? text) {
  if (html == null && text == null) {
    throw ArgumentError('At least one of html or text must be provided.');
  }
}

/// Validates, copies, and freezes a required recipient list.
List<String> _recipients(List<String> values, String name, {int? maximum}) {
  if (values.isEmpty || (maximum != null && values.length > maximum)) {
    throw RangeError.range(values.length, 1, maximum, name);
  }
  return List<String>.unmodifiable(
    values.map((String value) => requireNonBlank(value, name)),
  );
}

/// Validates an optional recipient list while preserving omission.
List<String>? _optionalRecipients(List<String>? values, String name) {
  return values == null ? null : _recipients(values, name);
}

/// Validates [value] when present while preserving null omission semantics.
String? _optionalNonBlank(String? value, String name) {
  return value == null ? null : requireNonBlank(value, name);
}

/// Validates and freezes caller-provided email headers.
Map<String, String>? _headers(Map<String, String>? values) {
  if (values == null) return null;
  if (values.isEmpty) {
    throw ArgumentError.value(values, 'headers', 'Must not be empty.');
  }
  return Map<String, String>.unmodifiable(<String, String>{
    for (final MapEntry<String, String> entry in values.entries)
      requireNonBlank(entry.key, 'headers'): entry.value,
  });
}

/// Validates and freezes an optional non-empty list.
List<T>? _nonEmptyCopy<T>(List<T>? values, String name) {
  if (values == null) return null;
  return requireNonEmpty<T>(values, name);
}

/// Validates attachment count and combined encoded payload size.
List<EmailAttachment>? _attachments(List<EmailAttachment>? values) {
  final List<EmailAttachment>? result = _nonEmptyCopy(values, 'attachments');
  if (result == null) return null;
  // Resend's 40 MB limit applies to encoded inline content; remote
  // attachments without content therefore do not contribute to this sum.
  final int encodedBytes = result.fold<int>(
    0,
    (int total, EmailAttachment value) => total + (value.content?.length ?? 0),
  );
  if (encodedBytes > _maximumEncodedAttachmentBytes) {
    throw ArgumentError.value(
      values,
      'attachments',
      'Inline attachments must not exceed 40 MB after Base64 encoding.',
    );
  }
  return result;
}

/// Validates an optional idempotency key against the API length limit.
String? _idempotencyKey(String? value) {
  if (value == null) return null;
  if (value.isEmpty || value.length > 256) {
    throw RangeError.range(value.length, 1, 256, 'idempotencyKey');
  }
  return value;
}

/// Decodes and freezes a required array of response models.
List<T> _models<T>(
  ResendModel reader,
  String key,
  T Function(JsonObject json) decode,
) {
  return List<T>.unmodifiable(
    reader.listField<Object?>(key).map((Object? value) {
      if (value is! Map<String, Object?>) {
        throw FormatException('Expected every "$key" item to be an object.');
      }
      return decode(value);
    }),
  );
}

/// Decodes an optional model array while preserving an absent field.
List<T>? _optionalModels<T>(
  ResendModel reader,
  String key,
  T Function(JsonObject json) decode,
) {
  return reader.json[key] == null ? null : _models<T>(reader, key, decode);
}

/// Wire-safe character and length constraint for email tag components.
final RegExp _tagPattern = RegExp(r'^[A-Za-z0-9_-]{1,256}$');

/// Wire-safe identifier constraint for template variable names.
final RegExp _templateVariablePattern = RegExp(r'^[A-Za-z0-9_]{1,50}$');

/// Largest integer exactly representable by JavaScript JSON consumers.
const num _maximumSafeInteger = 9007199254740991;

/// Maximum combined Base64 payload accepted by Resend for attachments.
const int _maximumEncodedAttachmentBytes = 40 * 1024 * 1024;
