import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/core/transport.dart';
import 'package:dart_resend/src/models/base.dart';
import 'package:dart_resend/src/resources/emails.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Registers this file's test cases with the package:test runner.
void main() {
  // Covers: email requests.
  group('email requests', () {
    // Verifies: wire enums expose documented values.
    test('wire enums expose documented values', () {
      expect(
        BatchValidationMode.values
            .map((BatchValidationMode value) => value.value)
            .toList(),
        <String>['strict', 'permissive'],
      );
      expect(
        ReceivedEmailHtmlFormat.values
            .map((ReceivedEmailHtmlFormat value) => value.value)
            .toList(),
        <String>['data_uri', 'cid'],
      );
    });

    // Verifies: tags validate and serialize.
    test('tags validate and serialize', () {
      final EmailTag tag = EmailTag(name: 'campaign_id', value: 'welcome-1');
      expect(tag.name, 'campaign_id');
      expect(tag.value, 'welcome-1');
      expect(tag.toJson(), <String, Object?>{
        'name': 'campaign_id',
        'value': 'welcome-1',
      });

      final EmailTag decoded = EmailTag.fromJson(<String, Object?>{
        'name': 'source',
        'value': 'sdk',
      });
      expect(decoded.toJson(), <String, Object?>{
        'name': 'source',
        'value': 'sdk',
      });
      expect(
        () => EmailTag(name: 'not valid', value: 'ok'),
        throwsArgumentError,
      );
      expect(() => EmailTag(name: 'ok', value: 'x' * 257), throwsArgumentError);
    });

    // Verifies: templates validate variables and serialize.
    test('templates validate variables and serialize', () {
      final EmailTemplate template = EmailTemplate(
        id: 'welcome',
        variables: <String, Object>{
          'NAME': 'Ada',
          'COUNT': 3,
          'RATIO': 1.5,
          'MINUS': -9007199254740991,
        },
      );
      expect(template.id, 'welcome');
      expect(template.variables['NAME'], 'Ada');
      expect(template.toJson(), <String, Object?>{
        'id': 'welcome',
        'variables': <String, Object>{
          'NAME': 'Ada',
          'COUNT': 3,
          'RATIO': 1.5,
          'MINUS': -9007199254740991,
        },
      });
      expect(EmailTemplate(id: 'empty').toJson(), <String, Object?>{
        'id': 'empty',
      });
      expect(() => EmailTemplate(id: ' '), throwsArgumentError);
      expect(
        () => EmailTemplate(
          id: 'x',
          variables: <String, Object>{'invalid-key': 'value'},
        ),
        throwsArgumentError,
      );
      expect(
        () => EmailTemplate(
          id: 'x',
          variables: <String, Object>{'LONG': 'x' * 2001},
        ),
        throwsArgumentError,
      );
      expect(
        () => EmailTemplate(
          id: 'x',
          variables: <String, Object>{'HUGE': 9007199254740992},
        ),
        throwsArgumentError,
      );
      expect(
        () => EmailTemplate(
          id: 'x',
          variables: <String, Object>{'NAN': double.nan},
        ),
        throwsArgumentError,
      );
      expect(
        () => EmailTemplate(id: 'x', variables: <String, Object>{'BOOL': true}),
        throwsArgumentError,
      );
    });

    // Verifies: attachments support bytes, Base64, and remote content.
    test('attachments support bytes, Base64, and remote content', () {
      final EmailAttachment bytes = EmailAttachment.bytes(
        <int>[1, 2, 3],
        filename: 'data.bin',
        contentType: 'application/octet-stream',
        contentId: 'inline-data',
      );
      expect(bytes.content, 'AQID');
      expect(bytes.path, isNull);
      expect(bytes.filename, 'data.bin');
      expect(bytes.contentType, 'application/octet-stream');
      expect(bytes.contentId, 'inline-data');
      expect(bytes.toJson(), <String, Object?>{
        'content': 'AQID',
        'filename': 'data.bin',
        'content_type': 'application/octet-stream',
        'content_id': 'inline-data',
      });

      final EmailAttachment encoded = EmailAttachment.base64('YQ');
      expect(encoded.content, 'YQ==');
      expect(encoded.toJson(), <String, Object?>{'content': 'YQ=='});

      final EmailAttachment remote = EmailAttachment.remote(
        Uri.parse('https://cdn.example.com/file.pdf'),
        filename: 'invoice.pdf',
      );
      expect(remote.content, isNull);
      expect(remote.path, Uri.parse('https://cdn.example.com/file.pdf'));
      expect(remote.toJson(), <String, Object?>{
        'path': 'https://cdn.example.com/file.pdf',
        'filename': 'invoice.pdf',
      });

      expect(() => EmailAttachment.base64(''), throwsArgumentError);
      expect(() => EmailAttachment.base64('%%%'), throwsArgumentError);
      expect(
        () => EmailAttachment.remote(Uri.parse('/relative')),
        throwsArgumentError,
      );
      expect(
        () => EmailAttachment.remote(Uri.parse('ftp://example.com/file')),
        throwsArgumentError,
      );
      expect(
        () => EmailAttachment.bytes(<int>[1], filename: ' '),
        throwsArgumentError,
      );
    });

    // Verifies: raw send requests serialize all supported options.
    test('raw send requests serialize all supported options', () {
      final SendEmailRequest request = SendEmailRequest.raw(
        from: 'Acme <sender@example.com>',
        to: <String>['one@example.com', 'two@example.com'],
        subject: 'Hello',
        html: '<p>Hello</p>',
        text: '',
        cc: <String>['cc@example.com'],
        bcc: <String>['bcc@example.com'],
        replyTo: <String>['reply@example.com'],
        headers: <String, String>{'X-Trace': 'abc'},
        scheduledAt: 'tomorrow at 9am',
        attachments: <EmailAttachment>[
          EmailAttachment.bytes(<int>[65], filename: 'a.txt'),
        ],
        tags: <EmailTag>[EmailTag(name: 'kind', value: 'welcome')],
        topicId: 'topic_1',
      );

      expect(request.toJson(), <String, Object?>{
        'from': 'Acme <sender@example.com>',
        'to': <String>['one@example.com', 'two@example.com'],
        'subject': 'Hello',
        'html': '<p>Hello</p>',
        'text': '',
        'cc': <String>['cc@example.com'],
        'bcc': <String>['bcc@example.com'],
        'reply_to': <String>['reply@example.com'],
        'headers': <String, String>{'X-Trace': 'abc'},
        'scheduled_at': 'tomorrow at 9am',
        'attachments': <Object?>[
          <String, Object?>{'content': 'QQ==', 'filename': 'a.txt'},
        ],
        'tags': <Object?>[
          <String, Object?>{'name': 'kind', 'value': 'welcome'},
        ],
        'topic_id': 'topic_1',
      });
    });

    // Verifies: template send requests use conditional template defaults.
    test('template send requests use conditional template defaults', () {
      final SendEmailRequest minimal = SendEmailRequest.template(
        template: EmailTemplate(id: 'welcome'),
        to: <String>['user@example.com'],
      );
      expect(minimal.toJson(), <String, Object?>{
        'to': <String>['user@example.com'],
        'template': <String, Object?>{'id': 'welcome'},
      });

      final SendEmailRequest overrides = SendEmailRequest.template(
        template: EmailTemplate(
          id: 'welcome',
          variables: <String, Object>{'NAME': 'Ada'},
        ),
        to: <String>['user@example.com'],
        from: 'sender@example.com',
        subject: 'Override',
        replyTo: <String>['reply@example.com'],
        scheduledAt: '2026-08-01T10:00:00Z',
      );
      expect(overrides.toJson()['from'], 'sender@example.com');
      expect(overrides.toJson()['subject'], 'Override');
      expect(overrides.toJson()['html'], isNull);
      expect(overrides.toJson()['text'], isNull);
    });

    // Verifies: batch request variants exclude unsupported fields.
    test('batch request variants exclude unsupported fields', () {
      final BatchEmailRequest raw = BatchEmailRequest.raw(
        from: 'sender@example.com',
        to: <String>['one@example.com'],
        subject: 'Raw',
        text: 'Text',
        cc: <String>['cc@example.com'],
        bcc: <String>['bcc@example.com'],
        replyTo: <String>['reply@example.com'],
        headers: <String, String>{'X-Test': ''},
        tags: <EmailTag>[EmailTag(name: 'batch', value: 'one')],
        topicId: 'topic',
      );
      expect(raw.toJson()['text'], 'Text');
      expect(raw.toJson().containsKey('attachments'), isFalse);
      expect(raw.toJson().containsKey('scheduled_at'), isFalse);

      final BatchEmailRequest template = BatchEmailRequest.template(
        template: EmailTemplate(id: 'template'),
        to: <String>['two@example.com'],
        from: 'sender@example.com',
        subject: 'Template',
        cc: <String>['cc@example.com'],
        bcc: <String>['bcc@example.com'],
        replyTo: <String>['reply@example.com'],
        headers: <String, String>{'X-Test': 'yes'},
        tags: <EmailTag>[EmailTag(name: 'batch', value: 'two')],
        topicId: 'topic',
      );
      expect(template.toJson()['template'], <String, Object?>{
        'id': 'template',
      });
      expect(template.toJson()['html'], isNull);
    });

    // Verifies: send request validation rejects invalid combinations.
    test('send request validation rejects invalid combinations', () {
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: 'subject',
        ),
        throwsArgumentError,
      );
      expect(
        () => BatchEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: 'subject',
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: ' ',
          to: <String>['to@example.com'],
          subject: 'subject',
          text: 'body',
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: const <String>[],
          subject: 'subject',
          text: 'body',
        ),
        throwsRangeError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: List<String>.filled(51, 'to@example.com'),
          subject: 'subject',
          text: 'body',
        ),
        throwsRangeError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>[' '],
          subject: 'subject',
          text: 'body',
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: ' ',
          text: 'body',
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: 'subject',
          text: 'body',
          cc: const <String>[],
        ),
        throwsRangeError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: 'subject',
          text: 'body',
          headers: const <String, String>{},
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: 'subject',
          text: 'body',
          headers: <String, String>{' ': 'value'},
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: 'subject',
          text: 'body',
          tags: const <EmailTag>[],
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: 'subject',
          text: 'body',
          attachments: const <EmailAttachment>[],
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: 'subject',
          text: 'body',
          scheduledAt: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: 'subject',
          text: 'body',
          topicId: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => SendEmailRequest.template(
          template: EmailTemplate(id: 'template'),
          to: <String>['to@example.com'],
          from: ' ',
        ),
        throwsArgumentError,
      );
    });

    // Verifies: combined encoded attachment size is limited to 40 MB.
    test('combined encoded attachment size is limited to 40 MB', () {
      final Uint8List bytes = Uint8List(15 * 1024 * 1024 + 1);
      final EmailAttachment first = EmailAttachment.bytes(bytes);
      final EmailAttachment second = EmailAttachment.bytes(bytes);
      expect(
        () => SendEmailRequest.raw(
          from: 'sender@example.com',
          to: <String>['to@example.com'],
          subject: 'subject',
          text: 'body',
          attachments: <EmailAttachment>[first, second],
        ),
        throwsArgumentError,
      );
    });

    // Verifies: scheduled update validates and serializes.
    test('scheduled update validates and serializes', () {
      final UpdateEmailRequest request = UpdateEmailRequest(
        scheduledAt: 'tomorrow at 9am',
      );
      expect(request.scheduledAt, 'tomorrow at 9am');
      expect(request.toJson(), <String, Object?>{
        'scheduled_at': 'tomorrow at 9am',
      });
      expect(() => UpdateEmailRequest(scheduledAt: ' '), throwsArgumentError);
    });
  });

  // Covers: email models.
  group('email models', () {
    // Verifies: sent email exposes all current and future fields.
    test('sent email exposes all current and future fields', () {
      final SentEmail email = SentEmail.fromJson(_sentEmailJson());
      expect(email.object, 'email');
      expect(email.id, 'email_1');
      expect(email.messageId, '<message@example.com>');
      expect(email.to, <String>['to@example.com']);
      expect(email.from, 'sender@example.com');
      expect(email.createdAt, DateTime.parse('2026-07-20T10:00:00Z'));
      expect(email.subject, 'Hello');
      expect(email.html, '<p>Hello</p>');
      expect(email.text, 'Hello');
      expect(email.bcc, <String>['bcc@example.com']);
      expect(email.cc, <String>['cc@example.com']);
      expect(email.replyTo, <String>['reply@example.com']);
      expect(email.lastEvent, 'bounced');
      expect(email.scheduledAt, DateTime.parse('2026-07-21T10:00:00Z'));
      expect(email.topicId, 'topic_1');
      expect(email.tags!.single.toJson(), <String, Object?>{
        'name': 'kind',
        'value': 'test',
      });
      expect(email.bounce!.diagnosticCodes, <String>['smtp; 550 rejected']);
      expect(email.bounce!.message, 'Recipient not found');
      expect(email.bounce!.subType, 'NoEmail');
      expect(email.bounce!.type, 'Permanent');
      expect(email.json['future_field'], 'preserved');

      final SentEmail minimal = SentEmail.fromJson(
        _sentEmailJson(includeOptional: false),
      );
      expect(minimal.object, isNull);
      expect(minimal.html, isNull);
      expect(minimal.text, isNull);
      expect(minimal.bcc, isNull);
      expect(minimal.cc, isNull);
      expect(minimal.replyTo, isNull);
      expect(minimal.scheduledAt, isNull);
      expect(minimal.topicId, isNull);
      expect(minimal.tags, isNull);
      expect(minimal.bounce, isNull);
    });

    // Verifies: batch results expose successes and permissive errors.
    test('batch results expose successes and permissive errors', () {
      final BatchEmailResult result = BatchEmailResult.fromJson(
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'id': 'email_1'},
          ],
          'errors': <Object?>[
            <String, Object?>{'index': 1, 'message': 'Invalid recipient'},
          ],
        },
      );
      expect(result.data.single.id, 'email_1');
      expect(result.errors.single.index, 1);
      expect(result.errors.single.message, 'Invalid recipient');
      expect(
        BatchEmailResult.fromJson(<String, Object?>{
          'data': const <Object?>[],
        }).errors,
        isEmpty,
      );
      expect(
        () => BatchEmailResult.fromJson(<String, Object?>{
          'data': <Object?>[1],
        }).data,
        throwsFormatException,
      );
    });

    // Verifies: retrieved attachment exposes signed URL metadata.
    test('retrieved attachment exposes signed URL metadata', () {
      final RetrievedEmailAttachment attachment =
          RetrievedEmailAttachment.fromJson(_retrievedAttachmentJson());
      expect(attachment.object, 'attachment');
      expect(attachment.id, 'attachment_1');
      expect(attachment.filename, 'document.pdf');
      expect(attachment.size, 2048);
      expect(attachment.contentType, 'application/pdf');
      expect(attachment.contentDisposition, 'attachment');
      expect(attachment.contentId, 'document');
      expect(
        attachment.downloadUrl,
        Uri.parse('https://cdn.example.com/document.pdf'),
      );
      expect(attachment.expiresAt, DateTime.parse('2026-07-20T11:00:00Z'));
      final RetrievedEmailAttachment optional =
          RetrievedEmailAttachment.fromJson(<String, Object?>{
            ..._retrievedAttachmentJson(),
            'object': null,
            'filename': null,
            'content_disposition': null,
            'content_id': null,
          });
      expect(optional.object, isNull);
      expect(optional.filename, isNull);
      expect(optional.contentDisposition, isNull);
      expect(optional.contentId, isNull);
    });

    // Verifies: received email exposes raw and embedded attachment metadata.
    test('received email exposes raw and embedded attachment metadata', () {
      final ReceivedEmail email = ReceivedEmail.fromJson(_receivedEmailJson());
      expect(email.object, 'email');
      expect(email.id, 'received_1');
      expect(email.messageId, '<inbound@example.com>');
      expect(email.to, <String>['inbound@example.com']);
      expect(email.from, 'person@example.net');
      expect(email.subject, 'Inbound');
      expect(email.createdAt, DateTime.parse('2026-07-20T09:00:00Z'));
      expect(email.bcc, <String>[]);
      expect(email.cc, <String>['copy@example.com']);
      expect(email.replyTo, <String>['person@example.net']);
      expect(email.receivedFor, <String>['inbound@example.com']);
      expect(email.html, '<img src="cid:image">');
      expect(email.htmlFormat, 'cid');
      expect(email.text, 'Inbound');
      expect(email.headers, <String, Object?>{'from': 'Person <x@y.test>'});
      expect(
        email.raw!.downloadUrl,
        Uri.parse('https://cdn.example.com/raw.eml'),
      );
      expect(email.raw!.expiresAt, DateTime.parse('2026-07-20T10:00:00Z'));
      final InboundEmailAttachment attachment = email.attachments.single;
      expect(attachment.id, 'attachment_1');
      expect(attachment.filename, 'image.png');
      expect(attachment.size, 128);
      expect(attachment.contentType, 'image/png');
      expect(attachment.contentDisposition, 'inline');
      expect(attachment.contentId, 'image');

      final ReceivedEmail minimal = ReceivedEmail.fromJson(
        _receivedEmailJson(includeOptional: false),
      );
      expect(minimal.object, isNull);
      expect(minimal.subject, isNull);
      expect(minimal.bcc, isNull);
      expect(minimal.cc, isNull);
      expect(minimal.replyTo, isNull);
      expect(minimal.receivedFor, isNull);
      expect(minimal.html, isNull);
      expect(minimal.htmlFormat, isNull);
      expect(minimal.text, isNull);
      expect(minimal.headers, isNull);
      expect(minimal.raw, isNull);
      expect(minimal.attachments.single.filename, isNull);
      expect(minimal.attachments.single.contentDisposition, isNull);
      expect(minimal.attachments.single.contentId, isNull);
    });
  });

  // Covers: EmailsResource.
  group('EmailsResource', () {
    // Verifies: calls every sending, receiving, and attachment endpoint.
    test('calls every sending, receiving, and attachment endpoint', () async {
      final List<String> calls = <String>[];
      final EmailsResource emails = _emailsResource((
        http.Request request,
      ) async {
        calls.add('${request.method} ${request.url}');
        final String path = request.url.path;

        if (request.method == 'POST' && path == '/emails') {
          expect(request.headers['idempotency-key'], 'send-once');
          final Object? body = jsonDecode(request.body);
          expect(body, isA<Map<String, Object?>>());
          return _jsonResponse(<String, Object?>{'id': 'sent'});
        }
        if (request.method == 'POST' && path == '/emails/batch') {
          expect(request.headers['idempotency-key'], 'batch-once');
          expect(request.headers['x-batch-validation'], 'permissive');
          final Object? body = jsonDecode(request.body);
          expect(body, isA<List<Object?>>());
          return _jsonResponse(<String, Object?>{
            'data': <Object?>[
              <String, Object?>{'id': 'batch_1'},
            ],
            'errors': const <Object?>[],
          });
        }
        if (request.method == 'GET' && path == '/emails') {
          expect(request.url.queryParameters, <String, String>{
            'limit': '2',
            'after': 'email_0',
          });
          return _jsonResponse(<String, Object?>{
            'object': 'list',
            'has_more': false,
            'data': <Object?>[_sentEmailJson(includeOptional: false)],
          });
        }
        if (request.method == 'GET' && path == '/emails/email_1') {
          return _jsonResponse(_sentEmailJson());
        }
        if (request.method == 'PATCH' && path == '/emails/email_1') {
          expect(jsonDecode(request.body), <String, Object?>{
            'scheduled_at': 'tomorrow',
          });
          return _jsonResponse(<String, Object?>{
            'object': 'email',
            'id': 'email_1',
          });
        }
        if (request.method == 'POST' && path == '/emails/email_1/cancel') {
          return _jsonResponse(<String, Object?>{
            'object': 'email',
            'id': 'email_1',
          });
        }
        if (request.method == 'GET' && path == '/emails/email_1/attachments') {
          expect(request.url.queryParameters, <String, String>{'limit': '1'});
          return _attachmentPage();
        }
        if (request.method == 'GET' &&
            path == '/emails/email_1/attachments/attachment_1') {
          return _jsonResponse(_retrievedAttachmentJson());
        }
        if (request.method == 'GET' && path == '/emails/receiving') {
          return _jsonResponse(<String, Object?>{
            'object': 'list',
            'has_more': true,
            'data': <Object?>[_receivedEmailJson(includeOptional: false)],
          });
        }
        if (request.method == 'GET' && path == '/emails/receiving/received_1') {
          if (request.url.queryParameters.isNotEmpty) {
            expect(request.url.queryParameters, <String, String>{
              'html_format': 'cid',
            });
          }
          return _jsonResponse(_receivedEmailJson());
        }
        if (request.method == 'GET' &&
            path == '/emails/receiving/received_1/attachments') {
          return _attachmentPage();
        }
        if (request.method == 'GET' &&
            path == '/emails/receiving/received_1/attachments/attachment_1') {
          return _jsonResponse(_retrievedAttachmentJson());
        }
        return http.Response('not found', 404);
      });

      expect(
        (await emails.send(
          SendEmailRequest.raw(
            from: 'sender@example.com',
            to: <String>['to@example.com'],
            subject: 'subject',
            text: 'body',
          ),
          idempotencyKey: 'send-once',
        )).data.id,
        'sent',
      );
      expect(
        (await emails.sendBatch(
          <BatchEmailRequest>[
            BatchEmailRequest.raw(
              from: 'sender@example.com',
              to: <String>['to@example.com'],
              subject: 'subject',
              text: 'body',
            ),
          ],
          validation: BatchValidationMode.permissive,
          idempotencyKey: 'batch-once',
        )).data.data.single.id,
        'batch_1',
      );
      expect(
        (await emails.list(
          pagination: PaginationOptions(limit: 2, after: 'email_0'),
        )).data.data.single.id,
        'email_1',
      );
      expect((await emails.retrieve('email_1')).data.id, 'email_1');
      expect(
        (await emails.update(
          'email_1',
          UpdateEmailRequest(scheduledAt: 'tomorrow'),
        )).data.object,
        'email',
      );
      expect((await emails.cancel('email_1')).data.id, 'email_1');
      expect(
        (await emails.listSentAttachments(
          'email_1',
          pagination: PaginationOptions(limit: 1),
        )).data.data.single.id,
        'attachment_1',
      );
      expect(
        (await emails.retrieveSentAttachment(
          'email_1',
          'attachment_1',
        )).data.id,
        'attachment_1',
      );
      expect(
        (await emails.listReceived(
          pagination: PaginationOptions(limit: 1),
        )).data.data.single.id,
        'received_1',
      );
      expect(
        (await emails.retrieveReceived(
          'received_1',
          htmlFormat: ReceivedEmailHtmlFormat.cid,
        )).data.id,
        'received_1',
      );
      expect(
        (await emails.retrieveReceived('received_1')).data.id,
        'received_1',
      );
      expect(
        (await emails.listReceivedAttachments(
          'received_1',
        )).data.data.single.id,
        'attachment_1',
      );
      expect(
        (await emails.retrieveReceivedAttachment(
          'received_1',
          'attachment_1',
        )).data.id,
        'attachment_1',
      );
      expect(calls, hasLength(13));
    });

    // Verifies: validates batch size and idempotency key length locally.
    test('validates batch size and idempotency key length locally', () {
      final EmailsResource emails = _emailsResource(
        (http.Request request) async => _jsonResponse(<String, Object?>{}),
      );
      final BatchEmailRequest item = BatchEmailRequest.raw(
        from: 'sender@example.com',
        to: <String>['to@example.com'],
        subject: 'subject',
        text: 'body',
      );
      expect(
        () => emails.sendBatch(const <BatchEmailRequest>[]),
        throwsRangeError,
      );
      expect(
        () => emails.sendBatch(List<BatchEmailRequest>.filled(101, item)),
        throwsRangeError,
      );
      expect(
        () => emails.send(
          SendEmailRequest.raw(
            from: 'sender@example.com',
            to: <String>['to@example.com'],
            subject: 'subject',
            text: 'body',
          ),
          idempotencyKey: '',
        ),
        throwsRangeError,
      );
      expect(
        () => emails.sendBatch(<BatchEmailRequest>[
          item,
        ], idempotencyKey: 'x' * 257),
        throwsRangeError,
      );
    });
  });
}

/// Creates an email resource whose transport delegates to [handler].
EmailsResource _emailsResource(
  Future<http.Response> Function(http.Request request) handler,
) {
  return EmailsResource(
    ResendTransport(
      apiKey: 're_test',
      client: MockClient(handler),
      baseUri: Uri.parse('https://api.example.test'),
    ),
  );
}

/// Encodes [json] as a successful email endpoint response.
http.Response _jsonResponse(JsonObject json) {
  return http.Response(
    jsonEncode(json),
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

/// Builds a paginated email-attachment response fixture.
http.Response _attachmentPage() {
  return _jsonResponse(<String, Object?>{
    'object': 'list',
    'has_more': false,
    'data': <Object?>[_retrievedAttachmentJson()],
  });
}

/// Builds a sent-email fixture with optionally omitted detail fields.
JsonObject _sentEmailJson({bool includeOptional = true}) {
  return <String, Object?>{
    if (includeOptional) 'object': 'email',
    'id': 'email_1',
    'message_id': '<message@example.com>',
    'to': <String>['to@example.com'],
    'from': 'sender@example.com',
    'created_at': '2026-07-20T10:00:00Z',
    'subject': 'Hello',
    'last_event': 'bounced',
    if (includeOptional) ...<String, Object?>{
      'html': '<p>Hello</p>',
      'text': 'Hello',
      'bcc': <String>['bcc@example.com'],
      'cc': <String>['cc@example.com'],
      'reply_to': <String>['reply@example.com'],
      'scheduled_at': '2026-07-21T10:00:00Z',
      'topic_id': 'topic_1',
      'tags': <Object?>[
        <String, Object?>{'name': 'kind', 'value': 'test'},
      ],
      'bounce': <String, Object?>{
        'diagnosticCode': <String>['smtp; 550 rejected'],
        'message': 'Recipient not found',
        'subType': 'NoEmail',
        'type': 'Permanent',
      },
      'future_field': 'preserved',
    },
  };
}

/// Builds a retrieved email-attachment response fixture.
JsonObject _retrievedAttachmentJson() {
  return <String, Object?>{
    'object': 'attachment',
    'id': 'attachment_1',
    'filename': 'document.pdf',
    'size': 2048,
    'content_type': 'application/pdf',
    'content_disposition': 'attachment',
    'content_id': 'document',
    'download_url': 'https://cdn.example.com/document.pdf',
    'expires_at': '2026-07-20T11:00:00Z',
  };
}

/// Builds a received-email fixture with optionally omitted detail fields.
JsonObject _receivedEmailJson({bool includeOptional = true}) {
  return <String, Object?>{
    if (includeOptional) 'object': 'email',
    'id': 'received_1',
    'message_id': '<inbound@example.com>',
    'to': <String>['inbound@example.com'],
    'from': 'person@example.net',
    'created_at': '2026-07-20T09:00:00Z',
    if (includeOptional) ...<String, Object?>{
      'subject': 'Inbound',
      'bcc': <String>[],
      'cc': <String>['copy@example.com'],
      'reply_to': <String>['person@example.net'],
      'received_for': <String>['inbound@example.com'],
      'html': '<img src="cid:image">',
      'html_format': 'cid',
      'text': 'Inbound',
      'headers': <String, Object?>{'from': 'Person <x@y.test>'},
      'raw': <String, Object?>{
        'download_url': 'https://cdn.example.com/raw.eml',
        'expires_at': '2026-07-20T10:00:00Z',
      },
    },
    'attachments': <Object?>[
      <String, Object?>{
        'id': 'attachment_1',
        'filename': includeOptional ? 'image.png' : null,
        'size': 128,
        'content_type': 'image/png',
        'content_disposition': includeOptional ? 'inline' : null,
        'content_id': includeOptional ? 'image' : null,
      },
    ],
  };
}
