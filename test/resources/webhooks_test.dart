import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/resources/webhooks.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../support/mock_transport.dart';

void main() {
  test('webhook requests serialize all documented events and statuses', () {
    final List<String> values = WebhookEventType.values
        .map((WebhookEventType event) => event.value)
        .toList();
    expect(values, <String>[
      'email.sent',
      'email.scheduled',
      'email.delivered',
      'email.delivery_delayed',
      'email.complained',
      'email.bounced',
      'email.opened',
      'email.clicked',
      'email.received',
      'email.failed',
      'email.suppressed',
      'contact.created',
      'contact.updated',
      'contact.deleted',
      'domain.created',
      'domain.updated',
      'domain.deleted',
    ]);
    expect(WebhookStatus.enabled.value, 'enabled');
    expect(WebhookStatus.disabled.value, 'disabled');

    final CreateWebhookRequest create = CreateWebhookRequest(
      endpoint: Uri.parse('https://example.com/webhook'),
      events: <WebhookEventType>[WebhookEventType.emailSent],
    );
    expect(create.toJson(), <String, Object?>{
      'endpoint': 'https://example.com/webhook',
      'events': <String>['email.sent'],
    });
    final UpdateWebhookRequest update = UpdateWebhookRequest(
      endpoint: Uri.parse('https://example.com/new'),
      events: <WebhookEventType>[WebhookEventType.emailDelivered],
      status: WebhookStatus.disabled,
    );
    expect(update.toJson(), <String, Object?>{
      'endpoint': 'https://example.com/new',
      'events': <String>['email.delivered'],
      'status': 'disabled',
    });
  });

  test('webhook request validation rejects unusable configurations', () {
    expect(
      () => CreateWebhookRequest(
        endpoint: Uri.parse('http://example.com'),
        events: WebhookEventType.values,
      ),
      throwsArgumentError,
    );
    expect(
      () => CreateWebhookRequest(
        endpoint: Uri.parse('/relative'),
        events: WebhookEventType.values,
      ),
      throwsArgumentError,
    );
    expect(
      () => CreateWebhookRequest(
        endpoint: Uri.parse('https://example.com'),
        events: <WebhookEventType>[],
      ),
      throwsArgumentError,
    );
    expect(() => UpdateWebhookRequest(), throwsArgumentError);
    expect(
      () => UpdateWebhookRequest(events: <WebhookEventType>[]),
      throwsArgumentError,
    );
  });

  test('webhook resource covers CRUD and paginated listing', () async {
    var call = 0;
    final WebhooksResource resource = WebhooksResource(
      mockTransport((http.Request request) async {
        call++;
        switch (call) {
          case 1:
            expect(request.method, 'POST');
            expect(request.url.path, '/v1/webhooks');
            return jsonResponse(<String, Object?>{
              'object': 'webhook',
              'id': 'hook_1',
              'signing_secret': 'whsec_secret',
            }, statusCode: 201);
          case 2:
            expect(request.url.queryParameters, <String, String>{'limit': '1'});
            return jsonResponse(<String, Object?>{
              'object': 'list',
              'has_more': false,
              'data': <Object?>[_webhookJson],
            });
          case 3:
            expect(request.method, 'GET');
            expect(request.url.path, '/v1/webhooks/hook%2F1');
            return jsonResponse(_webhookJson);
          case 4:
            expect(request.method, 'PATCH');
            expect(decodedBody(request), <String, Object?>{
              'status': 'disabled',
            });
            return jsonResponse(<String, Object?>{
              'object': 'webhook',
              'id': 'hook_1',
            });
          default:
            expect(request.method, 'DELETE');
            return jsonResponse(<String, Object?>{
              'object': 'webhook',
              'id': 'hook_1',
              'deleted': true,
            });
        }
      }),
    );

    final ResendWebhook created = (await resource.create(
      CreateWebhookRequest(
        endpoint: Uri.parse('https://example.com/webhook'),
        events: <WebhookEventType>[WebhookEventType.emailSent],
      ),
    )).data;
    expect(created.id, 'hook_1');
    expect(created.signingSecret, 'whsec_secret');
    expect(created.endpoint, isNull);
    expect(created.events, isNull);
    expect(created.status, isNull);
    expect(created.createdAt, isNull);

    final ResendWebhook listed = (await resource.list(
      pagination: PaginationOptions(limit: 1),
    )).data.data.single;
    expect(listed.endpoint, Uri.parse('https://example.com/webhook'));
    expect(listed.events, <String>['email.sent']);
    expect(listed.status, 'enabled');
    expect(listed.createdAt, DateTime.utc(2026, 7, 20, 12));
    expect(listed.signingSecret, isNull);
    expect((await resource.retrieve('hook/1')).data.id, 'hook_1');
    expect(
      (await resource.update(
        'hook_1',
        UpdateWebhookRequest(status: WebhookStatus.disabled),
      )).data.id,
      'hook_1',
    );
    expect((await resource.delete('hook_1')).data.deleted, isTrue);
    expect(() => resource.retrieve(' '), throwsArgumentError);
    expect(
      () => resource.update(
        ' ',
        UpdateWebhookRequest(status: WebhookStatus.enabled),
      ),
      throwsArgumentError,
    );
    expect(() => resource.delete(' '), throwsArgumentError);
  });
}

const Map<String, Object?> _webhookJson = <String, Object?>{
  'object': 'webhook',
  'id': 'hook_1',
  'endpoint': 'https://example.com/webhook',
  'events': <String>['email.sent'],
  'status': 'enabled',
  'created_at': '2026-07-20T12:00:00Z',
};
