## 2.0.0

This release is a complete, intentionally breaking redesign. No 1.x
compatibility layer is included.

- Replace the global singleton and `ResendClient` with an instance-based,
  reusable `Resend` client and explicit `close()` lifecycle.
- Replace `ResendResult` and legacy error values with `ResendResponse<T>` and
  typed API, network, timeout, and decode exceptions.
- Add immutable, forward-compatible request and response models with local
  validation, raw JSON retention, response headers, request IDs, and parsed
  rate-limit metadata.
- Add cursor pagination across list endpoints.
- Add complete email support: raw and template sends, idempotency, scheduling,
  batch validation and tags, sent email history, received email,
  and sent/received attachment APIs.
- Add complete domain support, including sending and receiving capabilities,
  all current regions and DNS record types, tracking configuration, and domain
  ownership claims.
- Add API keys, broadcasts, hosted templates, global contacts,
  segments, topics, custom contact properties, and asynchronous CSV imports.
- Add webhook configuration and local Standard Webhooks signature verification.
- Add API logs, automation graphs and run diagnostics, custom event definitions
  and delivery, private-beta suppressions, and OAuth 2.1 with PKCE.
- Remove the retired Audiences resource; use global contacts and segments.
- Add complete feature-focused examples and migration documentation.
- Add a test workflow and enforce 100% code coverage.
- Raise the minimum Dart SDK version to 3.8.0.

## 1.0.1

- Add the missing `Content-Type` header.

## 1.0.0

- Initial release.
