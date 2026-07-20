import 'dart:io';

import 'package:dart_resend/dart_resend.dart';

/// Sends one test email using the API key in `RESEND_API_KEY`.
Future<void> main() async {
  final String? apiKey = Platform.environment['RESEND_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('Set RESEND_API_KEY before running this example.');
    exitCode = 64;
    return;
  }

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
    stdout.writeln('Queued email ${response.data.id}.');
  } on ResendApiException catch (error) {
    stderr.writeln(
      'Resend rejected the request: ${error.message} '
      '(request ${error.requestId ?? 'unknown'}).',
    );
  } finally {
    resend.close();
  }
}
