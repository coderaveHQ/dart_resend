import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a delete contact request
class ResendDeleteContactResponse {
  /// The ID of the deleted contact
  final String contactId;

  /// Indicator if the contact got deleted
  final bool deleted;

  /// Constructor of ResendDeleteContactResponse
  const ResendDeleteContactResponse(
      {required this.contactId, required this.deleted});

  /// Factory method for creating a ResendDeleteContactResponse instance from a JSON object
  factory ResendDeleteContactResponse.fromJson(Json json) {
    return ResendDeleteContactResponse(
        contactId: json['contact'] as String, deleted: json['deleted'] as bool);
  }
}
