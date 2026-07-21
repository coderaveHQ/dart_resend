import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/base.dart';
import '../models/request.dart';

/// A verified webhook event sent by Resend.
final class ResendWebhookEvent extends ResendModel {
  /// Decodes a verified event from JSON.
  ResendWebhookEvent.fromJson(super.json);

  /// The event type, such as `email.delivered` or `contact.created`.
  String get type => field<String>('type');

  /// When the event occurred.
  DateTime get createdAt => dateTimeField('created_at');

  /// Event-specific payload data.
  JsonObject get data => objectField('data');
}

/// Thrown when a Resend webhook cannot be authenticated or decoded.
final class ResendWebhookVerificationException implements Exception {
  /// Creates a verification exception.
  const ResendWebhookVerificationException(this.message);

  /// Human-readable failure description.
  final String message;

  /// Returns a diagnostic representation of this value.
  @override
  String toString() => 'ResendWebhookVerificationException: $message';
}

/// Authenticates Standard Webhooks/Svix signatures used by Resend.
final class ResendWebhookVerifier {
  /// Creates a verifier for [signingSecret].
  ///
  /// [tolerance] limits replay attacks by rejecting old or future messages.
  ResendWebhookVerifier({
    required String signingSecret,
    this.tolerance = const Duration(minutes: 5),
  }) : _key = _decodeSecret(signingSecret) {
    if (tolerance.isNegative) {
      throw ArgumentError.value(
        tolerance,
        'tolerance',
        'Must not be negative.',
      );
    }
  }

  /// Decoded HMAC key material derived from the configured signing secret.
  final List<int> _key;

  /// Maximum accepted difference between local time and the signed timestamp.
  final Duration tolerance;

  /// Verifies the raw [payload] and returns the decoded webhook event.
  ///
  /// Pass the unmodified values of the `svix-id`, `svix-timestamp`, and
  /// `svix-signature` request headers. Parsing and re-encoding [payload] before
  /// this call invalidates the signature.
  ResendWebhookEvent verify({
    required String payload,
    required String id,
    required String timestamp,
    required String signature,
    DateTime? now,
  }) {
    requireNonBlank(id, 'id');
    requireNonBlank(signature, 'signature');
    final int? seconds = int.tryParse(timestamp);
    if (seconds == null) {
      throw const ResendWebhookVerificationException(
        'The webhook timestamp is invalid.',
      );
    }

    // Authenticate the timestamp before computing the HMAC to reject replayed
    // payloads outside the configured acceptance window.
    final DateTime signedAt = DateTime.fromMillisecondsSinceEpoch(
      seconds * Duration.millisecondsPerSecond,
      isUtc: true,
    );
    final Duration age = (now ?? DateTime.now().toUtc()).difference(signedAt);
    if (age.abs() > tolerance) {
      throw const ResendWebhookVerificationException(
        'The webhook timestamp is outside the accepted tolerance.',
      );
    }

    // Standard Webhooks signs the exact ID, timestamp, and raw payload bytes.
    final Digest expected = Hmac(
      sha256,
      _key,
    ).convert(utf8.encode('$id.$timestamp.$payload'));
    if (!_matchesAnySignature(signature, expected.bytes)) {
      throw const ResendWebhookVerificationException(
        'The webhook signature is invalid.',
      );
    }

    try {
      final Object? decoded = jsonDecode(payload);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Webhook payload must be a JSON object.');
      }
      return ResendWebhookEvent.fromJson(decoded);
    } on FormatException catch (error) {
      throw ResendWebhookVerificationException(
        'The signed webhook payload is invalid JSON: ${error.message}',
      );
    }
  }
}

/// Decodes a Standard Webhooks secret with or without its `whsec_` prefix.
List<int> _decodeSecret(String secret) {
  final String value = requireNonBlank(secret, 'signingSecret');
  final String encoded = value.startsWith('whsec_')
      ? value.substring(6)
      : value;
  try {
    return List<int>.unmodifiable(base64.decode(base64.normalize(encoded)));
  } on FormatException {
    throw ArgumentError.value(
      secret,
      'signingSecret',
      'Must contain a valid Base64 Standard Webhooks secret.',
    );
  }
}

/// Checks every version-1 candidate to support signing-key rotation.
bool _matchesAnySignature(String header, List<int> expected) {
  var matched = false;
  for (final String candidate in header.split(RegExp(r'\s+'))) {
    final int separator = candidate.indexOf(',');
    if (separator < 0 || candidate.substring(0, separator) != 'v1') continue;
    try {
      final List<int> actual = base64.decode(
        base64.normalize(candidate.substring(separator + 1)),
      );
      matched = _constantTimeEquals(actual, expected) || matched;
    } on FormatException {
      // Ignore malformed candidates so rotated valid signatures can match.
    }
  }
  return matched;
}

/// Compares signature bytes without data-dependent early termination.
bool _constantTimeEquals(List<int> left, List<int> right) {
  var difference = left.length ^ right.length;
  final int length = left.length < right.length ? left.length : right.length;
  for (var index = 0; index < length; index++) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
