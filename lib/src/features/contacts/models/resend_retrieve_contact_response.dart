import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a retrieve contact request
class ResendRetrieveContactResponse {
  /// The ID of the contact
  final String contactId;

  /// The email of the contact
  final String email;

  /// The first name of the contact
  final String? firstName;

  /// The last name of the contact
  final String? lastName;

  /// The time of creation of the contact
  final DateTime createdAt;

  /// Indicator if the contact unsubscribed
  final bool unsubscribed;

  /// Constructor of ResendRetrieveContactResponse
  const ResendRetrieveContactResponse(
      {required this.contactId,
      required this.email,
      this.firstName,
      this.lastName,
      required this.createdAt,
      required this.unsubscribed});

  /// Factory method for creating a ResendRetrieveContactResponse instance from a JSON object
  factory ResendRetrieveContactResponse.fromJson(Json json) {
    return ResendRetrieveContactResponse(
        contactId: json['id'] as String,
        email: json['email'] as String,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        unsubscribed: json['unsubscribed'] as bool);
  }
}
