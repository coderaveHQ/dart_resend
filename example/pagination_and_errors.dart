import 'dart:io';

import 'package:dart_resend/dart_resend.dart';

/// Iterates through every page of sent emails using `after` cursors.
Future<List<SentEmail>> listAllSentEmails(Resend resend) async {
  final List<SentEmail> emails = <SentEmail>[];
  String? after;
  do {
    final ResendResponse<ResendPage<SentEmail>> response = await resend.emails
        .list(pagination: PaginationOptions(limit: 100, after: after));
    emails.addAll(response.data.data);
    if (!response.data.hasMore || response.data.data.isEmpty) {
      break;
    }
    after = response.data.data.last.id;
  } while (true);
  return List<SentEmail>.unmodifiable(emails);
}

/// Reads request IDs, response headers, and parsed rate-limit metadata.
Future<void> inspectResponseMetadata(Resend resend) async {
  final ResendResponse<ResendPage<Domain>> response = await resend.domains.list(
    pagination: PaginationOptions(limit: 10),
  );
  stdout.writeln('HTTP ${response.statusCode}; request ${response.requestId}');
  stdout.writeln('Content type: ${response.header('content-type')}');
  stdout.writeln(
    'Rate limit: ${response.rateLimit?.remaining}/'
    '${response.rateLimit?.limit}, resets in '
    '${response.rateLimit?.resetAfter}',
  );
}

/// Handles API, timeout, network, and response-decoding failures separately.
Future<void> handleResendErrors(Resend resend) async {
  try {
    await resend.emails.retrieve('email_id');
  } on ResendApiException catch (error) {
    stderr.writeln(
      'API ${error.statusCode} ${error.name}: ${error.message}; '
      'request ${error.requestId}; details ${error.details}',
    );
  } on ResendTimeoutException catch (error) {
    stderr.writeln(
      '${error.method} ${error.uri} timed out at ${error.timeout}',
    );
  } on ResendNetworkException catch (error) {
    stderr.writeln('${error.method} ${error.uri} failed: ${error.cause}');
  } on ResendDecodeException catch (error) {
    stderr.writeln(
      'Could not decode HTTP ${error.statusCode}: ${error.responseBody}',
    );
  }
}

/// Creates a configured client and always releases its owned HTTP client.
Future<void> useConfiguredClient(String apiKey) async {
  final Resend resend = Resend(
    apiKey: apiKey,
    timeout: const Duration(seconds: 10),
    defaultHeaders: <String, String>{'X-Application': 'acme-backend'},
  );
  try {
    await resend.domains.list();
  } finally {
    resend.close();
  }
}
