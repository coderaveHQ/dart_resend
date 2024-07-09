import 'package:dart_resend/src/utils/typedefs.dart';

/// A class for holding all information of an email that is intended to be sent as a batch emails request
class ResendEmailBatchParams {
  /// The email address this email will be sent from
  final String from;

  /// The email addresses this email will be sent to
  final List<String> to;

  /// The subject of the email
  final String subject;

  /// The email adddresses of `bcc`
  final List<String>? bcc;

  /// The email addresses of `cc`
  final List<String>? cc;

  /// The email addresses this email will reply to
  final List<String>? replyTo;

  /// The HTML content of the email
  final String? html;

  /// The text content of the email
  final String? text;

  /// The headers of the email
  final Json? headers;

  /// Constructor of ResendEmailBatchParams
  const ResendEmailBatchParams({
    required this.from,
    required this.to,
    required this.subject,
    this.bcc,
    this.cc,
    this.replyTo,
    this.html,
    this.text,
    this.headers,
  });

  /// Method to create a JSON object from the given data
  Json toJson() {
    return <String, dynamic>{
      'from': from,
      'to': to,
      'subject': subject,
      if (bcc != null && bcc!.isNotEmpty) 'bcc': bcc,
      if (cc != null && cc!.isNotEmpty) 'cc': cc,
      if (replyTo != null && replyTo!.isNotEmpty) 'reply_to': replyTo,
      if (html != null && html!.isNotEmpty) 'html': html,
      if (text != null && text!.isNotEmpty) 'text': text,
      if (headers != null && headers!.isNotEmpty) 'headers': headers
    };
  }
}
