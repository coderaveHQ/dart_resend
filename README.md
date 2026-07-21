# dart_resend

[![pub package](https://img.shields.io/pub/v/dart_resend.svg)](https://pub.dev/packages/dart_resend)
[![License](https://img.shields.io/github/license/coderaveHQ/dart_resend)](https://github.com/coderaveHQ/dart_resend/blob/production/LICENSE)

A production-ready, community-maintained Dart SDK for the complete Resend API.

The public surface tracks the [official Resend API reference](https://resend.com/docs/api-reference/introduction)
and its [canonical OpenAPI specification](https://github.com/resend/resend-openapi/blob/main/resend.yaml).

`dart_resend` 2.0 provides typed request and response models, cursor pagination,
request metadata, predictable exceptions, local validation, dependency-injected
HTTP transport, and first-class support for every current Resend resource.

Developed with 💙 and maintained by [coderave](https://coderave.dev)

## Important notes

- **Keep API keys on a trusted server.** Never embed a Resend API key in a web,
  Flutter, mobile, desktop, or other distributed client. Route those requests
  through your own authenticated backend.
- **2.0.0 is an intentional breaking redesign.** The singleton, `ResendClient`,
  `ResendResult`, legacy feature clients, and legacy response classes were
  removed. See the [migration guide](https://github.com/coderaveHQ/dart_resend/blob/production/MIGRATION.md).
- **Audiences were removed.** Resend's current API uses global
  [Contacts](#contacts-and-imports) and [Segments](#segments). The package no
  longer exposes the retired Audiences resource.
- **Suppressions are private beta.** The API is implemented, but calls only work
  for Resend teams with access to the gated feature.

## Install

```console
dart pub add dart_resend
```

The package requires Dart 3.8 or newer.

## Quick start

```dart
import 'package:dart_resend/dart_resend.dart';

Future<void> sendEmail(String apiKey) async {
  final Resend resend = Resend(apiKey: apiKey);
  try {
    final ResendResponse<ResendId> response = await resend.emails.send(
      SendEmailRequest.raw(
        from: 'Acme <onboarding@resend.dev>',
        to: <String>['delivered@resend.dev'],
        subject: 'Hello from dart_resend',
        html: '<strong>It works!</strong>',
        text: 'It works!',
      ),
    );
    print(response.data.id);
  } finally {
    resend.close();
  }
}
```

Run the complete quick start with an environment variable:

```console
RESEND_API_KEY=re_... dart run example/main.dart
```

See the [runnable example](example/main.dart#L6).

## Client lifecycle

Create one `Resend` instance per application or service and reuse it. Calling
`close()` releases the internally owned HTTP client and is safe to do more than
once. Calls made after closing fail with `StateError`.

When an `http.Client` is injected, it remains caller-owned by default. Set
`closeClient: true` if `Resend.close()` should close the injected client too.
The constructor also accepts a request `timeout`, `defaultHeaders`, and custom
`baseUri` for tests or compatible gateways. See
[`useConfiguredClient`](example/pagination_and_errors.dart#L58).

OAuth registration and token endpoints do not require an API key. Use
`Resend.unauthenticated()` for those calls and an authenticated `Resend` client
for team resources and OAuth grant management.

## Responses, pagination, and errors

Every network method returns `Future<ResendResponse<T>>`. The response contains
the decoded `data`, HTTP `statusCode`, immutable lowercase `headers`, Resend
`requestId`, and parsed `rateLimit` metadata. Response models also retain their
complete immutable payload in `json`, so newly added server fields remain
available before the SDK adds typed getters.

List operations accept `PaginationOptions(limit:, after:, before:)` and return
`ResendPage<T>`, whose `data` and `hasMore` fields drive cursor iteration.
`after` and `before` are mutually exclusive; limits must be between 1 and 100.
See [cursor iteration](example/pagination_and_errors.dart#L6) and
[response metadata](example/pagination_and_errors.dart#L22).

Failures are thrown as typed exceptions:

- `ResendApiException` for non-2xx API responses, including the status, error
  name, request ID, headers, parsed details, and raw body.
- `ResendTimeoutException` when the configured timeout expires.
- `ResendNetworkException` for other transport failures.
- `ResendDecodeException` when a successful response cannot be decoded.
- `ArgumentError`, `RangeError`, or `StateError` for invalid local usage.

See the [complete error-handling example](example/pagination_and_errors.dart#L36).

## Complete feature and example index

Every public Resend operation is demonstrated below. The linked files are part
of the analyzed package examples and use only the public library entrypoint.

### Emails

- [`emails.send` with raw HTML/text, recipients, headers, tags, inline bytes,
  Base64 and remote attachments, topic, and idempotency](example/emails.dart#L4)
- [`emails.send` with a published template and variables](example/emails.dart#L41)
- [`emails.send` with scheduled delivery](example/emails.dart#L55)
- [`emails.sendBatch` with raw and template emails, permissive validation,
  tags, and idempotency](example/emails.dart#L68)
- [`emails.list`](example/emails.dart#L91)
- [`emails.retrieve`](example/emails.dart#L96)
- [`emails.update` to reschedule](example/emails.dart#L104)
- [`emails.cancel`](example/emails.dart#L115)
- [`emails.listSentAttachments`](example/emails.dart#L123)
- [`emails.retrieveSentAttachment`](example/emails.dart#L132)
- [`emails.listReceived`](example/emails.dart#L141)
- [`emails.retrieveReceived` with inline-image format control](example/emails.dart#L148)
- [`emails.listReceivedAttachments`](example/emails.dart#L159)
- [`emails.retrieveReceivedAttachment`](example/emails.dart#L168)

Batch sends support tags but not attachments or `scheduled_at`. A batch may
contain 1–100 emails and can use strict all-or-nothing or permissive per-item
validation.

### Domains

- [`domains.create` with region, TLS, tracking, return path, and capabilities](example/domains.dart#L4)
- [`domains.list`](example/domains.dart#L23)
- [`domains.retrieve` and DNS records](example/domains.dart#L28)
- [`domains.update`](example/domains.dart#L33)
- [`domains.verify`](example/domains.dart#L50)
- [`domains.delete`](example/domains.dart#L55)
- [`domains.claim`](example/domains.dart#L63)
- [`domains.retrieveClaim`](example/domains.dart#L77)
- [`domains.verifyClaim`](example/domains.dart#L85)

Domain DNS models preserve unknown record kinds and types for forward
compatibility. A configured tracking subdomain can currently be replaced and
reverified, but not removed.

### API keys

- [`apiKeys.create` with sending-only and domain-restricted permissions](example/api_keys.dart#L4)
- [`apiKeys.list`](example/api_keys.dart#L15)
- [`apiKeys.delete`](example/api_keys.dart#L22)

The token returned by `apiKeys.create` is shown only once; store it in a secret
manager and never log it.

### Broadcasts

- [`broadcasts.create` as a draft](example/broadcasts.dart#L4)
- [`broadcasts.create` and schedule immediately](example/broadcasts.dart#L21)
- [`broadcasts.list`](example/broadcasts.dart#L35)
- [`broadcasts.retrieve`](example/broadcasts.dart#L40)
- [`broadcasts.update`, including clearing a topic](example/broadcasts.dart#L48)
- [`broadcasts.send` now or later](example/broadcasts.dart#L64)
- [`broadcasts.delete` or cancel](example/broadcasts.dart#L72)

### Templates

- [`templates.create` with string, number, boolean, object, and list variables](example/templates.dart#L4)
- [`templates.list`](example/templates.dart#L46)
- [`templates.retrieve` by ID or alias](example/templates.dart#L53)
- [`templates.update`](example/templates.dart#L61)
- [`templates.publish`](example/templates.dart#L76)
- [`templates.duplicate`](example/templates.dart#L84)
- [`templates.delete`](example/templates.dart#L92)
- [Send a published template](example/emails.dart#L41)

### Contacts and imports

- [`contacts.create` with custom properties, segments, and topics](example/contacts.dart#L6)
- [`contacts.list`](example/contacts.dart#L28)
- [`contacts.list` filtered by segment](example/contacts.dart#L33)
- [`contacts.retrieve` by ID or email](example/contacts.dart#L44)
- [`contacts.update`, clear names, and remove property values](example/contacts.dart#L52)
- [`contacts.delete` by ID or email](example/contacts.dart#L68)
- [`contacts.listSegments`](example/contacts.dart#L76)
- [`contacts.addToSegment`](example/contacts.dart#L87)
- [`contacts.removeFromSegment`](example/contacts.dart#L96)
- [`contacts.listTopics`](example/contacts.dart#L105)
- [`contacts.updateTopics` with opt-in and opt-out values](example/contacts.dart#L116)
- [`contacts.imports.create` with CSV mapping, conflict behavior, segments, and topics](example/contacts.dart#L136)
- [`contacts.imports.list` with status filtering](example/contacts.dart#L174)
- [`contacts.imports.retrieve` and row counts](example/contacts.dart#L184)

Contacts are global. Use segments for grouping and topics for granular contact
preferences; use `unsubscribed` for the global broadcast preference.

### Segments

- [`segments.create`](example/segments.dart#L4)
- [`segments.list`](example/segments.dart#L9)
- [`segments.retrieve`](example/segments.dart#L14)
- [`segments.listContacts`](example/segments.dart#L22)
- [`segments.delete`](example/segments.dart#L33)

### Topics

- [`topics.create` with default subscription and public/private visibility](example/topics.dart#L4)
- [`topics.list` with cursor pagination](example/topics.dart#L16)
- [`topics.retrieve`](example/topics.dart#L21)
- [`topics.update`, including visibility](example/topics.dart#L26)
- [`topics.delete`](example/topics.dart#L38)

### Contact properties

- [`contactProperties.create` with typed fallback values](example/contact_properties.dart#L4)
- [`contactProperties.list`](example/contact_properties.dart#L15)
- [`contactProperties.retrieve`](example/contact_properties.dart#L24)
- [`contactProperties.update` or clear a fallback](example/contact_properties.dart#L32)
- [`contactProperties.delete`](example/contact_properties.dart#L43)

### Webhooks

- [`webhooks.create` and every documented event type](example/webhooks.dart#L4)
- [`webhooks.list`](example/webhooks.dart#L14)
- [`webhooks.retrieve` and its signing secret](example/webhooks.dart#L19)
- [`webhooks.update`](example/webhooks.dart#L27)
- [`webhooks.delete`](example/webhooks.dart#L46)
- [Verify the raw payload and `svix-*` headers locally](example/webhooks.dart#L54)

Never parse and re-encode a webhook body before verification. Verification uses
the raw request body and throws `ResendWebhookVerificationException` for an
invalid signature, timestamp, or payload.

### API logs

- [`logs.list`](example/logs.dart#L4)
- [`logs.retrieve` with request and response bodies](example/logs.dart#L9)

### Automations and runs

- [Every condition operator plus `all` and `any` groups](example/automations.dart#L4)
- [Forward-compatible custom automation steps](example/automations.dart#L63)
- [`automations.create` with trigger, wait, condition, email, delay, contact
  update, segment, contact-delete, variables, and every branch type](example/automations.dart#L72)
- [`automations.list` with status filtering](example/automations.dart#L154)
- [`automations.retrieve` and its graph](example/automations.dart#L162)
- [`automations.update`](example/automations.dart#L170)
- [`automations.stop`](example/automations.dart#L184)
- [`automations.delete`](example/automations.dart#L192)
- [`automations.runs.list` with status filtering](example/automations.dart#L200)
- [`automations.runs.retrieve` with step diagnostics](example/automations.dart#L215)

Automation graph builders validate the trigger, unique keys, endpoints,
reachability, connection branches, and duplicate connections before sending.

### Custom events

- [`events.create` with every schema type](example/events.dart#L4)
- [`events.list`](example/events.dart#L19)
- [`events.retrieve` by ID or name](example/events.dart#L26)
- [`events.update` or clear the schema](example/events.dart#L34)
- [`events.delete` by ID or name](example/events.dart#L50)
- [`events.send` to a contact ID](example/events.dart#L58)
- [`events.send` to an email address](example/events.dart#L72)

### Suppressions (private beta)

These calls require private-beta access on the authenticated Resend team:

- [`suppressions.add`](example/suppressions.dart#L6)
- [`suppressions.addBatch`](example/suppressions.dart#L11)
- [`suppressions.retrieve` by ID or email](example/suppressions.dart#L21)
- [`suppressions.list` with origin filtering](example/suppressions.dart#L29)
- [`suppressions.remove`](example/suppressions.dart#L39)
- [`suppressions.removeBatch` by email](example/suppressions.dart#L47)
- [`suppressions.removeBatch` by ID](example/suppressions.dart#L58)

### OAuth 2.1 and PKCE

- [`Resend.unauthenticated` and `oauth.register`](example/oauth.dart#L4)
- [`OAuthPkcePair.generate` and `oauth.authorizationUri`](example/oauth.dart#L26)
- [`OAuthPkcePair.fromVerifier`](example/oauth.dart#L44)
- [`oauth.exchangeCode`](example/oauth.dart#L49)
- [`oauth.refresh`](example/oauth.dart#L64)
- [`oauth.revokeToken`](example/oauth.dart#L77)
- [Create a `Resend` client from an OAuth access token](example/oauth.dart#L91)
- [`oauth.listGrants` with team authentication](example/oauth.dart#L96)
- [`oauth.revokeGrant` with team authentication](example/oauth.dart#L101)

Use a cryptographically random `state`, bind it to the browser session, and
store the PKCE verifier securely until the callback. OAuth access and refresh
tokens are secrets and must remain server-side. Authorization URLs default to
`https://api.resend.com/oauth/authorize`; override `authorizationBaseUri` only
for an intentional compatible service or test environment.

## Version 2 migration

Version 2 deliberately does not include compatibility shims for the old API.
Read [MIGRATION.md](https://github.com/coderaveHQ/dart_resend/blob/production/MIGRATION.md) for old-to-new call mappings, the new exception
model, and the Audiences-to-Segments migration.

## Contributing

See [CONTRIBUTING.md](https://github.com/coderaveHQ/dart_resend/blob/production/CONTRIBUTING.md) for package development, tests, coverage,
documentation, and pull-request requirements.
