import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a list contacts request
class ResendListContactsResponse {
  /// A list holding the contacts
  final List<ResendListContactsResponseContact> contacts;

  /// Constructor of ResendListContactsResponse
  const ResendListContactsResponse({required this.contacts});

  /// Factory method for creating a ResendListContactsResponse instance from a JSON object
  factory ResendListContactsResponse.fromJson(Json json) {
    return ResendListContactsResponse(
        contacts: List<Json>.from(json['data'])
            .map((j) => ResendListContactsResponseContact.fromJson(j))
            .toList());
  }
}

/// Class holding the data of a contact
class ResendListContactsResponseContact {
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

  /// Constructor of ResendListAudiencesResponseAudience
  const ResendListContactsResponseContact(
      {required this.contactId,
      required this.email,
      this.firstName,
      this.lastName,
      required this.createdAt,
      required this.unsubscribed});

  /// Factory method for creating a ResendListContactsResponseContact instance from a JSON object
  factory ResendListContactsResponseContact.fromJson(Json json) {
    return ResendListContactsResponseContact(
        contactId: json['id'] as String,
        email: json['email'] as String,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        unsubscribed: json['unsubscribed'] as bool);
  }
}
