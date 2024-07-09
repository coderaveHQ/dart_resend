import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a add contact request
class ResendAddContactResponse {
  /// The id of the created contact
  final String contactId;

  /// Constructor of ResendAddContactResponse
  const ResendAddContactResponse({required this.contactId});

  /// Factory method for creating a ResendAddContactResponse instance from a JSON object
  factory ResendAddContactResponse.fromJson(Json json) {
    return ResendAddContactResponse(contactId: json['id'] as String);
  }
}
