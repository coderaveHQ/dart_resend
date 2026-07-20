# Migrating from 1.x to 2.0

Version 2 is a ground-up redesign with no source-compatibility layer. The new
API favors explicit client ownership, typed requests and responses, exceptions,
and resource names that match the current Resend API.

## Requirements

- Upgrade to Dart 3.8 or newer.
- Import only `package:dart_resend/dart_resend.dart`; imports from `lib/src` were
  never public and are no longer compatible.
- Remove references to the old `ResendClient`, legacy feature clients,
  `ResendResult`, `ResendError`, and legacy response classes.

## Create and close a client

The 1.x singleton and its assertion-based initialization were removed.

Before:

```dart
final Resend instance = Resend.initialize(apiKey: apiKey);
final ResendClient resend = instance.client;

// Later:
instance.dispose();
```

After:

```dart
final Resend resend = Resend(apiKey: apiKey);
try {
  // Reuse this client for all calls made by the service.
} finally {
  resend.close();
}
```

Create independent clients when an application works with more than one API
key. If an `http.Client` is injected, it remains caller-owned unless
`closeClient: true` is passed.

API keys must remain in server-side environment variables or secret storage.
Do not ship them in browser, Flutter, mobile, or desktop binaries.

## Send an email

The singular `email` client is now the `emails` resource. Named method
parameters became validated request objects.

Before:

```dart
final ResendResult<ResendSendEmailResponse> result = await resend.email
    .sendEmail(
      from: 'Acme <onboarding@example.com>',
      to: <String>['ada@example.com'],
      subject: 'Welcome',
      text: 'Hello!',
    );
```

After:

```dart
final ResendResponse<ResendId> response = await resend.emails.send(
  SendEmailRequest.raw(
    from: 'Acme <onboarding@example.com>',
    to: <String>['ada@example.com'],
    subject: 'Welcome',
    text: 'Hello!',
  ),
);
final String emailId = response.data.id;
```

Template sends use `SendEmailRequest.template`. Batch sends use
`BatchEmailRequest.raw` or `.template`. Attachments use
`EmailAttachment.bytes`, `.base64`, or `.remote`; attachments and scheduling
remain unsupported by the Resend batch endpoint.

## Handle responses and failures

`ResendResult.fold` was removed. Successful calls return `ResendResponse<T>`;
failed calls throw.

```dart
try {
  final ResendResponse<SentEmail> response = await resend.emails.retrieve(id);
  final SentEmail email = response.data;
  final String? requestId = response.requestId;
  final ResendRateLimit? rateLimit = response.rateLimit;
} on ResendApiException catch (error) {
  // HTTP status, Resend error name, details, headers, and request ID.
} on ResendTimeoutException catch (error) {
  // The configured request timeout expired.
} on ResendNetworkException catch (error) {
  // The request could not reach Resend or read its response.
} on ResendDecodeException catch (error) {
  // A successful response did not match its documented JSON shape.
}
```

Invalid request values fail locally with `ArgumentError` or `RangeError` before
any HTTP request is sent. Calling a closed or unauthenticated client for an
authenticated resource fails with `StateError`.

## Paginate list operations

List methods now consistently return `ResendPage<T>` and accept
`PaginationOptions` where supported:

```dart
final ResendResponse<ResendPage<Contact>> page = await resend.contacts.list(
  pagination: PaginationOptions(limit: 100, after: previousCursor),
);

for (final Contact contact in page.data.data) {
  // Process the contact.
}
```

Use the final resource ID as the next `after` or `before` cursor while
`page.data.hasMore` is true. See the
[complete pagination example](example/pagination_and_errors.dart#L6).

## Replace Audiences with Contacts and Segments

Resend retired the Audiences resource. Version 2 intentionally has no
`resend.audiences` property.

- Create and manage global recipients through `resend.contacts`.
- Create recipient groups through `resend.segments`.
- Add or remove a contact with `contacts.addToSegment` and
  `contacts.removeFromSegment`.
- List group members with `segments.listContacts` or
  `contacts.list(segmentId: ...)`.
- Use topics for per-category opt-in or opt-out preferences.

Old audience IDs cannot simply be passed to a removed endpoint. Create or map a
segment and migrate memberships to that segment.

## Resource mapping

| 1.x concept | 2.0 API |
| --- | --- |
| `Resend.initialize(...).client` | `Resend(apiKey: ...)` |
| `dispose()` | `close()` |
| `resend.email` | `resend.emails` |
| `sendEmail(...)` | `emails.send(SendEmailRequest.raw(...))` |
| `sendBatchEmails(...)` | `emails.sendBatch(<BatchEmailRequest>[...])` |
| `ResendResult<T>` | `ResendResponse<T>` on success; exceptions on failure |
| `resend.audiences` | `resend.segments` plus global `resend.contacts` |
| Legacy positional/named payloads | Typed `Create*Request` and `Update*Request` objects |

The existing plural resource names remain, but their methods and model types
were redesigned. Follow the [complete example index](README.md#complete-feature-and-example-index)
for every current operation.

## Newly supported resources

Version 2 adds broadcasts, hosted templates, global contact
properties, contact CSV imports, topics, webhooks and verification, API logs,
automations and runs, custom events, private-beta suppressions, received email,
attachment APIs, domain claims, and OAuth 2.1/PKCE.

Suppressions remain a gated Resend private beta and only work for teams with
feature access.
