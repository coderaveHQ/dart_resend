import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:dart_resend/src/features/email/models/resend_email_batch_params.dart';
import 'package:dart_resend/src/features/email/models/resend_email_attachment.dart';
import 'package:dart_resend/src/features/email/models/resend_email_tag.dart';
import 'package:dart_resend/src/features/email/models/resend_retrieve_email_response.dart';
import 'package:dart_resend/src/features/email/models/resend_send_batch_emails_response.dart';
import 'package:dart_resend/src/features/email/models/resend_send_email_response.dart';
import 'package:dart_resend/src/utils/resend_result.dart';
import 'package:dart_resend/src/utils/typedefs.dart';

/// The client for the Resend Email API
class ResendEmailClient {
  /// API Key for API authentication
  final String _apiKey;

  /// Base URI for the Resend E-Mail API
  final Uri _baseUri = Uri.parse('https://api.resend.com/emails');

  /// Constructor of ResendEmailClient
  ResendEmailClient({
    required String apiKey,
  }) : _apiKey = apiKey;

  /// Start sending emails through the Resend Email API.
  Future<ResendResult<ResendSendEmailResponse>> sendEmail(
      {
      /// Sender email address.
      /// To include a friendly name, use the format "Your Name <sender@domain.com>".
      required String from,

      /// Recipient email address. For multiple addresses, send as an array of strings. Max 50.
      required List<String> to,

      /// Email subject.
      required String subject,

      /// Bcc recipient email address. For multiple addresses, send as an array of strings.
      List<String>? bcc,

      /// Cc recipient email address. For multiple addresses, send as an array of strings.
      List<String>? cc,

      /// Reply-to email address. For multiple addresses, send as an array of strings.
      List<String>? replyTo,

      /// The HTML version of the message.
      String? html,

      /// The plain text version of the message.
      String? text,

      /// Custom headers to add to the email.
      Json? headers,

      /// Email attachments.
      List<ResendEmailAttachment>? attachments,

      /// Email tags.
      List<ResendEmailTag>? tags}) async {
    // Validation
    assert(from.isNotEmpty, 'E-Mail from can not be empty.');
    assert(to.isNotEmpty, 'E-Mail to can not be empty.');
    assert(subject.isNotEmpty, 'E-Mail subject can not be empty.');

    // Construct the request URI
    final Uri uri =
        Uri(scheme: _baseUri.scheme, host: _baseUri.host, path: _baseUri.path);

    // Send GET request to the API
    final http.Response response = await http.post(uri,
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(<String, dynamic>{
          'from': from,
          'to': to,
          'subject': subject,
          if (bcc != null && bcc.isNotEmpty) 'bcc': bcc,
          if (cc != null && cc.isNotEmpty) 'cc': cc,
          if (replyTo != null && replyTo.isNotEmpty) 'reply_to': replyTo,
          if (html != null && html.isNotEmpty) 'html': html,
          if (text != null && text.isNotEmpty) 'text': text,
          if (headers != null && headers.isNotEmpty) 'headers': headers,
          if (attachments != null && attachments.isNotEmpty)
            'attachments': attachments,
          if (tags != null && tags.isNotEmpty) 'tags': tags
        }));

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendSendEmailResponse result =
        ResendSendEmailResponse.fromJson(body);
    return ResendResult<ResendSendEmailResponse>.success(result);
  }

  /// Retrieve a single email.
  Future<ResendResult<ResendRetrieveEmailResponse>> retrieveEmail(

      /// The Email ID.
      String emailId) async {
    // Validation
    assert(emailId.isNotEmpty, 'The E-Mail ID can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$emailId');

    // Send GET request to the API
    final http.Response response = await http.get(uri,
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json'
        });

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendRetrieveEmailResponse result =
        ResendRetrieveEmailResponse.fromJson(body);
    return ResendResult<ResendRetrieveEmailResponse>.success(result);
  }

  /// Trigger up to 100 batch emails at once.
  Future<ResendResult<ResendSendBatchEmailsResponse>> sendBatchEmails(

      /// List of E-Mail parameters
      List<ResendEmailBatchParams> paramsList) async {
    // Validation
    assert(paramsList.isNotEmpty, 'The list can not be empty.');

    // Construct the request URI
    final Uri uri =
        Uri(scheme: _baseUri.scheme, host: _baseUri.host, path: _baseUri.path);

    // Send GET request to the API
    final http.Response response = await http.post(uri,
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(paramsList.map((p) => p.toJson()).toList()));

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendSendBatchEmailsResponse result =
        ResendSendBatchEmailsResponse.fromJson(body);
    return ResendResult<ResendSendBatchEmailsResponse>.success(result);
  }
}
