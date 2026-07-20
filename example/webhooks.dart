import 'package:dart_resend/dart_resend.dart';

/// Creates a webhook and subscribes it to every documented event type.
Future<ResendResponse<ResendWebhook>> createWebhook(Resend resend) {
  return resend.webhooks.create(
    CreateWebhookRequest(
      endpoint: Uri.parse('https://example.com/webhooks/resend'),
      events: WebhookEventType.values,
    ),
  );
}

/// Lists webhook endpoints.
Future<ResendResponse<ResendPage<ResendWebhook>>> listWebhooks(Resend resend) {
  return resend.webhooks.list(pagination: PaginationOptions(limit: 25));
}

/// Retrieves a webhook and its signing secret.
Future<ResendResponse<ResendWebhook>> retrieveWebhook(
  Resend resend,
  String webhookId,
) {
  return resend.webhooks.retrieve(webhookId);
}

/// Changes a webhook's endpoint, subscriptions, and enabled status.
Future<ResendResponse<ResendId>> updateWebhook(
  Resend resend,
  String webhookId,
) {
  return resend.webhooks.update(
    webhookId,
    UpdateWebhookRequest(
      endpoint: Uri.parse('https://example.com/webhooks/resend-v2'),
      events: <WebhookEventType>[
        WebhookEventType.emailDelivered,
        WebhookEventType.emailBounced,
        WebhookEventType.emailReceived,
      ],
      status: WebhookStatus.enabled,
    ),
  );
}

/// Deletes a webhook endpoint.
Future<ResendResponse<ResendDeletion>> deleteWebhook(
  Resend resend,
  String webhookId,
) {
  return resend.webhooks.delete(webhookId);
}

/// Verifies an unmodified webhook body and its Standard Webhooks headers.
ResendWebhookEvent verifyWebhook({
  required String signingSecret,
  required String rawBody,
  required String svixId,
  required String svixTimestamp,
  required String svixSignature,
}) {
  final ResendWebhookVerifier verifier = ResendWebhookVerifier(
    signingSecret: signingSecret,
    tolerance: const Duration(minutes: 5),
  );
  return verifier.verify(
    payload: rawBody,
    id: svixId,
    timestamp: svixTimestamp,
    signature: svixSignature,
  );
}
