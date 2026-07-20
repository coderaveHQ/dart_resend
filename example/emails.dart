import 'package:dart_resend/dart_resend.dart';

/// Sends raw HTML and text with recipients, headers, tags, and attachments.
Future<ResendResponse<ResendId>> sendRawEmail(Resend resend) {
  return resend.emails.send(
    SendEmailRequest.raw(
      from: 'Acme <onboarding@resend.dev>',
      to: <String>['delivered@resend.dev'],
      cc: <String>['team@example.com'],
      bcc: <String>['archive@example.com'],
      replyTo: <String>['support@example.com'],
      subject: 'Your receipt',
      html: '<img src="cid:logo">Thanks for your order.',
      text: 'Thanks for your order.',
      headers: <String, String>{'X-Entity-Ref-ID': 'order_123'},
      attachments: <EmailAttachment>[
        EmailAttachment.bytes(
          <int>[137, 80, 78, 71],
          filename: 'logo.png',
          contentType: 'image/png',
          contentId: 'logo',
        ),
        EmailAttachment.base64(
          'SGVsbG8=',
          filename: 'note.txt',
          contentType: 'text/plain',
        ),
        EmailAttachment.remote(
          Uri.parse('https://example.com/invoice.pdf'),
          filename: 'invoice.pdf',
        ),
      ],
      tags: <EmailTag>[EmailTag(name: 'category', value: 'receipt')],
      topicId: 'topic_transactional',
    ),
    idempotencyKey: 'order_123_receipt',
  );
}

/// Sends an email from a published template by ID or alias.
Future<ResendResponse<ResendId>> sendTemplateEmail(Resend resend) {
  return resend.emails.send(
    SendEmailRequest.template(
      template: EmailTemplate(
        id: 'welcome-email',
        variables: <String, Object>{'first_name': 'Ada'},
      ),
      to: <String>['delivered@resend.dev'],
    ),
    idempotencyKey: 'welcome_ada',
  );
}

/// Schedules an email for later delivery.
Future<ResendResponse<ResendId>> scheduleEmail(Resend resend) {
  return resend.emails.send(
    SendEmailRequest.raw(
      from: 'Acme <onboarding@resend.dev>',
      to: <String>['delivered@resend.dev'],
      subject: 'Scheduled update',
      text: 'This message was scheduled.',
      scheduledAt: 'in 1 hour',
    ),
  );
}

/// Sends a strict or permissive batch of up to 100 emails.
Future<ResendResponse<BatchEmailResult>> sendBatchEmails(Resend resend) {
  return resend.emails.sendBatch(
    <BatchEmailRequest>[
      BatchEmailRequest.raw(
        from: 'Acme <onboarding@resend.dev>',
        to: <String>['delivered@resend.dev'],
        subject: 'First batch message',
        text: 'Hello, Ada!',
      ),
      BatchEmailRequest.template(
        template: EmailTemplate(
          id: 'welcome-email',
          variables: <String, Object>{'first_name': 'Grace'},
        ),
        to: <String>['delivered@resend.dev'],
      ),
    ],
    validation: BatchValidationMode.permissive,
    idempotencyKey: 'welcome_batch_2026_07_20',
  );
}

/// Lists sent emails with cursor pagination.
Future<ResendResponse<ResendPage<SentEmail>>> listSentEmails(Resend resend) {
  return resend.emails.list(pagination: PaginationOptions(limit: 50));
}

/// Retrieves one sent email.
Future<ResendResponse<SentEmail>> retrieveSentEmail(
  Resend resend,
  String emailId,
) {
  return resend.emails.retrieve(emailId);
}

/// Moves a scheduled email to another delivery time.
Future<ResendResponse<ResendId>> rescheduleEmail(
  Resend resend,
  String emailId,
) {
  return resend.emails.update(
    emailId,
    UpdateEmailRequest(scheduledAt: 'in 2 hours'),
  );
}

/// Cancels a scheduled email.
Future<ResendResponse<ResendId>> cancelScheduledEmail(
  Resend resend,
  String emailId,
) {
  return resend.emails.cancel(emailId);
}

/// Lists the attachments of a sent email.
Future<ResendResponse<ResendPage<RetrievedEmailAttachment>>>
listSentEmailAttachments(Resend resend, String emailId) {
  return resend.emails.listSentAttachments(
    emailId,
    pagination: PaginationOptions(limit: 20),
  );
}

/// Retrieves a sent-email attachment and its temporary download URL.
Future<ResendResponse<RetrievedEmailAttachment>> retrieveSentEmailAttachment(
  Resend resend,
  String emailId,
  String attachmentId,
) {
  return resend.emails.retrieveSentAttachment(emailId, attachmentId);
}

/// Lists emails received by the authenticated team.
Future<ResendResponse<ResendPage<ReceivedEmail>>> listReceivedEmails(
  Resend resend,
) {
  return resend.emails.listReceived(pagination: PaginationOptions(limit: 50));
}

/// Retrieves a received email while preserving inline `cid:` image links.
Future<ResendResponse<ReceivedEmail>> retrieveReceivedEmail(
  Resend resend,
  String emailId,
) {
  return resend.emails.retrieveReceived(
    emailId,
    htmlFormat: ReceivedEmailHtmlFormat.cid,
  );
}

/// Lists the attachments of a received email.
Future<ResendResponse<ResendPage<RetrievedEmailAttachment>>>
listReceivedEmailAttachments(Resend resend, String emailId) {
  return resend.emails.listReceivedAttachments(
    emailId,
    pagination: PaginationOptions(limit: 20),
  );
}

/// Retrieves a received-email attachment and its temporary download URL.
Future<ResendResponse<RetrievedEmailAttachment>>
retrieveReceivedEmailAttachment(
  Resend resend,
  String emailId,
  String attachmentId,
) {
  return resend.emails.retrieveReceivedAttachment(emailId, attachmentId);
}
