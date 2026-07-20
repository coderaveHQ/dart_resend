import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_resend/src/resources/webhook_verifier.dart';
import 'package:test/test.dart';

void main() {
  const String encodedSecret = 'c2VjcmV0LWtleQ==';
  const String secret = 'whsec_$encodedSecret';
  final DateTime now = DateTime.fromMillisecondsSinceEpoch(
    1_750_000_000 * 1000,
    isUtc: true,
  );
  const String timestamp = '1750000000';
  const String id = 'msg_123';
  const String payload =
      '{"type":"email.delivered","created_at":"2026-07-20T12:00:00Z",'
      '"data":{"email_id":"email_1"}}';

  test('verifies a signed webhook and exposes immutable event data', () {
    final String signature = _signature(
      secret: encodedSecret,
      id: id,
      timestamp: timestamp,
      payload: payload,
    );
    final ResendWebhookEvent event =
        ResendWebhookVerifier(signingSecret: secret).verify(
          payload: payload,
          id: id,
          timestamp: timestamp,
          signature: 'bad v2,ignored not-a-signature v1,%%% $signature',
          now: now,
        );
    expect(event.type, 'email.delivered');
    expect(event.createdAt, DateTime.utc(2026, 7, 20, 12));
    expect(event.data['email_id'], 'email_1');
    expect(() => event.data['new'] = true, throwsUnsupportedError);
  });

  test('accepts an unprefixed secret and rotated signatures', () {
    final String signature = _signature(
      secret: encodedSecret,
      id: id,
      timestamp: timestamp,
      payload: payload,
    );
    expect(
      ResendWebhookVerifier(signingSecret: encodedSecret)
          .verify(
            payload: payload,
            id: id,
            timestamp: timestamp,
            signature: 'v1,AAAA $signature',
            now: now,
          )
          .type,
      'email.delivered',
    );
  });

  test('rejects invalid signatures and timestamps', () {
    final ResendWebhookVerifier verifier = ResendWebhookVerifier(
      signingSecret: secret,
    );
    expect(
      () => verifier.verify(
        payload: payload,
        id: id,
        timestamp: timestamp,
        signature: 'v1,AAAA',
        now: now,
      ),
      throwsA(isA<ResendWebhookVerificationException>()),
    );
    expect(
      () => verifier.verify(
        payload: payload,
        id: id,
        timestamp: 'not-a-number',
        signature: 'v1,AAAA',
        now: now,
      ),
      throwsA(isA<ResendWebhookVerificationException>()),
    );
    expect(
      () => verifier.verify(
        payload: payload,
        id: id,
        timestamp: '1749999000',
        signature: 'v1,AAAA',
        now: now,
      ),
      throwsA(isA<ResendWebhookVerificationException>()),
    );
    expect(
      () => verifier.verify(
        payload: payload,
        id: ' ',
        timestamp: timestamp,
        signature: 'v1,AAAA',
        now: now,
      ),
      throwsArgumentError,
    );
    expect(
      () => verifier.verify(
        payload: payload,
        id: id,
        timestamp: timestamp,
        signature: ' ',
        now: now,
      ),
      throwsArgumentError,
    );
  });

  test('rejects malformed signed JSON after authenticating it', () {
    for (final String invalidPayload in <String>['not-json', '[]']) {
      final String signature = _signature(
        secret: encodedSecret,
        id: id,
        timestamp: timestamp,
        payload: invalidPayload,
      );
      expect(
        () => ResendWebhookVerifier(signingSecret: secret).verify(
          payload: invalidPayload,
          id: id,
          timestamp: timestamp,
          signature: signature,
          now: now,
        ),
        throwsA(isA<ResendWebhookVerificationException>()),
      );
    }
  });

  test('validates verifier construction and exception formatting', () {
    expect(
      () => ResendWebhookVerifier(signingSecret: ' '),
      throwsArgumentError,
    );
    expect(
      () => ResendWebhookVerifier(signingSecret: 'not base64!'),
      throwsArgumentError,
    );
    expect(
      () => ResendWebhookVerifier(
        signingSecret: secret,
        tolerance: const Duration(seconds: -1),
      ),
      throwsArgumentError,
    );
    expect(
      const ResendWebhookVerificationException('bad').toString(),
      'ResendWebhookVerificationException: bad',
    );
  });
}

String _signature({
  required String secret,
  required String id,
  required String timestamp,
  required String payload,
}) {
  final List<int> key = base64.decode(secret);
  final Digest digest = Hmac(
    sha256,
    key,
  ).convert(utf8.encode('$id.$timestamp.$payload'));
  return 'v1,${base64.encode(digest.bytes)}';
}
