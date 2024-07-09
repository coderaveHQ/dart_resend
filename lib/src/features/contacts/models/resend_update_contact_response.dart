import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of an update contact request
class ResendUpdateContactResponse {
  /// The ID of the contact
  final String contactId;

  /// Constructor of ResendUpdateContactResponse
  const ResendUpdateContactResponse({required this.contactId});

  /// Factory method for creating a ResendUpdateContactResponse instance from a JSON object
  factory ResendUpdateContactResponse.fromJson(Json json) {
    return ResendUpdateContactResponse(contactId: json['id'] as String);
  }
}
