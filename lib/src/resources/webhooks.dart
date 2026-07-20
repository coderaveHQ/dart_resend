import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// A webhook event type supported by Resend.
enum WebhookEventType implements ResendWireValue {
  /// Email accepted by Resend.
  emailSent('email.sent'),

  /// Email scheduled for later delivery.
  emailScheduled('email.scheduled'),

  /// Email delivered to the recipient's mail server.
  emailDelivered('email.delivered'),

  /// Email delivery was delayed.
  emailDeliveryDelayed('email.delivery_delayed'),

  /// Recipient marked an email as spam.
  emailComplained('email.complained'),

  /// Email bounced.
  emailBounced('email.bounced'),

  /// Recipient opened an email.
  emailOpened('email.opened'),

  /// Recipient clicked an email link.
  emailClicked('email.clicked'),

  /// Resend received an inbound email.
  emailReceived('email.received'),

  /// Email sending failed.
  emailFailed('email.failed'),

  /// Email was suppressed before delivery.
  emailSuppressed('email.suppressed'),

  /// Contact created.
  contactCreated('contact.created'),

  /// Contact updated.
  contactUpdated('contact.updated'),

  /// Contact deleted.
  contactDeleted('contact.deleted'),

  /// Domain created.
  domainCreated('domain.created'),

  /// Domain updated.
  domainUpdated('domain.updated'),

  /// Domain deleted.
  domainDeleted('domain.deleted');

  const WebhookEventType(this.value);

  @override
  final String value;
}

/// Whether a webhook endpoint accepts deliveries.
enum WebhookStatus implements ResendWireValue {
  /// Webhook deliveries are enabled.
  enabled('enabled'),

  /// Webhook deliveries are disabled.
  disabled('disabled');

  const WebhookStatus(this.value);

  @override
  final String value;
}

/// Parameters for creating a webhook.
final class CreateWebhookRequest implements ResendRequest {
  /// Creates webhook parameters.
  CreateWebhookRequest({
    required Uri endpoint,
    required List<WebhookEventType> events,
  }) : endpoint = _validateEndpoint(endpoint),
       events = requireNonEmpty<WebhookEventType>(events, 'events');

  /// HTTPS endpoint that receives webhook requests.
  final Uri endpoint;

  /// Event types delivered to the endpoint.
  final List<WebhookEventType> events;

  @override
  JsonObject toJson() => <String, Object?>{
    'endpoint': endpoint.toString(),
    'events': events.map((WebhookEventType event) => event.value).toList(),
  };
}

/// Parameters for updating a webhook.
final class UpdateWebhookRequest implements ResendRequest {
  /// Creates webhook-update parameters.
  UpdateWebhookRequest({
    Uri? endpoint,
    List<WebhookEventType>? events,
    this.status,
  }) : endpoint = endpoint == null ? null : _validateEndpoint(endpoint),
       events = events == null
           ? null
           : requireNonEmpty<WebhookEventType>(events, 'events') {
    if (endpoint == null && events == null && status == null) {
      throw ArgumentError('At least one webhook field must be updated.');
    }
  }

  /// Updated HTTPS endpoint.
  final Uri? endpoint;

  /// Updated event subscriptions.
  final List<WebhookEventType>? events;

  /// Updated delivery status.
  final WebhookStatus? status;

  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'endpoint': endpoint?.toString(),
    'events': events?.map((WebhookEventType event) => event.value).toList(),
    'status': status?.value,
  });
}

/// A configured Resend webhook.
final class ResendWebhook extends ResendModel {
  /// Decodes a webhook.
  ResendWebhook.fromJson(super.json);

  /// Webhook ID.
  String get id => field<String>('id');

  /// Delivery endpoint when returned by retrieve/list operations.
  Uri? get endpoint {
    final String? value = optionalField<String>('endpoint');
    return value == null ? null : Uri.parse(value);
  }

  /// Raw subscribed event names.
  List<String>? get events => optionalListField<String>('events');

  /// Raw delivery status.
  String? get status => optionalField<String>('status');

  /// When the webhook was created.
  DateTime? get createdAt => optionalDateTimeField('created_at');

  /// Secret used to verify deliveries, returned by create/retrieve calls.
  String? get signingSecret => optionalField<String>('signing_secret');
}

/// Operations for configuring Resend webhooks.
final class WebhooksResource {
  /// Creates a webhooks resource client.
  WebhooksResource(this._transport);

  final ResendTransport _transport;

  /// Creates a webhook.
  Future<ResendResponse<ResendWebhook>> create(CreateWebhookRequest request) {
    return _transport.post<ResendWebhook>(
      pathSegments: <String>['webhooks'],
      body: request.toJson(),
      decode: ResendWebhook.fromJson,
    );
  }

  /// Lists webhooks.
  Future<ResendResponse<ResendPage<ResendWebhook>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<ResendWebhook>>(
      pathSegments: <String>['webhooks'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<ResendWebhook>.fromJson(json, ResendWebhook.fromJson),
    );
  }

  /// Retrieves a webhook by [id].
  Future<ResendResponse<ResendWebhook>> retrieve(String id) {
    return _transport.get<ResendWebhook>(
      pathSegments: <String>['webhooks', requireNonBlank(id, 'id')],
      decode: ResendWebhook.fromJson,
    );
  }

  /// Updates a webhook.
  Future<ResendResponse<ResendId>> update(
    String id,
    UpdateWebhookRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>['webhooks', requireNonBlank(id, 'id')],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Deletes a webhook.
  Future<ResendResponse<ResendDeletion>> delete(String id) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>['webhooks', requireNonBlank(id, 'id')],
      decode: ResendDeletion.fromJson,
    );
  }
}

Uri _validateEndpoint(Uri endpoint) {
  if (!endpoint.hasAuthority || endpoint.scheme != 'https') {
    throw ArgumentError.value(
      endpoint,
      'endpoint',
      'Must be an absolute HTTPS URI.',
    );
  }
  return endpoint;
}
