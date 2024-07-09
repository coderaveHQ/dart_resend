import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a retrieve email request
class ResendRetrieveEmailResponse {
  /// The ID of the email
  final String emailId;

  /// The email addresses this email was sent to
  final List<String> to;

  /// The email address the email came from
  final String from;

  /// The time of creation of this email
  final DateTime createdAt;

  /// The subject of this email
  final String subject;

  /// The HTML content of this email
  final String? html;

  /// The text content of this email
  final String? text;

  /// The email adddresses of `bcc`
  final List<String> bcc;

  /// The email addresses of `cc`
  final List<String> cc;

  /// The email addresses this email was intended to reply to
  final List<String> replyTo;

  /// The last event of this email (e.g. `delivered`)
  final String lastEvent;

  /// Constructor of ResendRetrieveEmailResponse
  const ResendRetrieveEmailResponse(
      {required this.emailId,
      required this.to,
      required this.from,
      required this.createdAt,
      required this.subject,
      this.html,
      this.text,
      required this.bcc,
      required this.cc,
      required this.replyTo,
      required this.lastEvent});

  /// Factory method for creating a ResendRetrieveEmailResponse instance from a JSON object
  factory ResendRetrieveEmailResponse.fromJson(Json json) {
    return ResendRetrieveEmailResponse(
        emailId: json['id'] as String,
        to: List<String>.from(json['to']),
        from: json['from'] as String,
        createdAt: DateTime.parse(json['created_at']),
        subject: json['subject'] as String,
        html: json['html'] as String?,
        text: json['text'] as String?,
        bcc: List<String>.from(json['bcc']),
        cc: List<String>.from(json['cc']),
        replyTo: List<String>.from(json['reply_to']),
        lastEvent: json['last_event'] as String);
  }
}
