import 'package:dart_resend/dart_resend.dart';

/// Creates a custom contact property.
Future<ResendResponse<ResendId>> createContactProperty(Resend resend) {
  return resend.contactProperties.create(
    CreateContactPropertyRequest(
      key: 'plan',
      type: ContactPropertyType.string,
      fallbackValue: 'free',
    ),
  );
}

/// Lists custom contact properties.
Future<ResendResponse<ResendPage<ContactProperty>>> listContactProperties(
  Resend resend,
) {
  return resend.contactProperties.list(
    pagination: PaginationOptions(limit: 25),
  );
}

/// Retrieves a custom contact property.
Future<ResendResponse<ContactProperty>> retrieveContactProperty(
  Resend resend,
  String propertyId,
) {
  return resend.contactProperties.retrieve(propertyId);
}

/// Changes or clears a contact property's fallback value.
Future<ResendResponse<ResendId>> updateContactProperty(
  Resend resend,
  String propertyId,
) {
  return resend.contactProperties.update(
    propertyId,
    UpdateContactPropertyRequest(fallbackValue: 'pro'),
  );
}

/// Deletes a custom contact property.
Future<ResendResponse<ResendDeletion>> deleteContactProperty(
  Resend resend,
  String propertyId,
) {
  return resend.contactProperties.delete(propertyId);
}
