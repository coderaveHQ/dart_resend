import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a batch emails request
class ResendSendBatchEmailsResponse {
  /// A list holding the emails
  final List<ResendSendBatchEmailsResponseEmail> emails;

  /// Constructor of ResendSendBatchEmailsResponse
  const ResendSendBatchEmailsResponse({required this.emails});

  /// Factory method for creating a ResendSendBatchEmailsResponse instance from a JSON object
  factory ResendSendBatchEmailsResponse.fromJson(Json json) {
    return ResendSendBatchEmailsResponse(
        emails: List<Json>.from(json['data'])
            .map((j) => ResendSendBatchEmailsResponseEmail.fromJson(j))
            .toList());
  }
}

/// Class holding the data of an email
class ResendSendBatchEmailsResponseEmail {
  /// The ID of the email
  final String emailId;

  /// Constructor of ResendSendBatchEmailsResponseEmail
  const ResendSendBatchEmailsResponseEmail({required this.emailId});

  /// Factory method for creating a ResendSendBatchEmailsResponseEmail instance from a JSON object
  factory ResendSendBatchEmailsResponseEmail.fromJson(Json json) {
    return ResendSendBatchEmailsResponseEmail(emailId: json['id'] as String);
  }
}
