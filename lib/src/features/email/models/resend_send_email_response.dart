import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a send email request
class ResendSendEmailResponse {
  /// The ID of the sent email
  final String emailId;

  /// Constructor of ResendSendEmailResponse
  const ResendSendEmailResponse({required this.emailId});

  /// Factory method for creating a ResendSendEmailResponse instance from a JSON object
  factory ResendSendEmailResponse.fromJson(Json json) {
    return ResendSendEmailResponse(emailId: json['id'] as String);
  }
}
