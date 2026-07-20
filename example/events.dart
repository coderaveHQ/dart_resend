import 'package:dart_resend/dart_resend.dart';

/// Defines a custom event and its typed payload schema.
Future<ResendResponse<ResendId>> createCustomEvent(Resend resend) {
  return resend.events.create(
    CreateEventRequest(
      name: 'trial.started',
      schema: <String, EventSchemaType>{
        'plan': EventSchemaType.string,
        'seats': EventSchemaType.number,
        'converted': EventSchemaType.boolean,
        'started_at': EventSchemaType.date,
      },
    ),
  );
}

/// Lists custom event definitions.
Future<ResendResponse<ResendPage<CustomEvent>>> listCustomEvents(
  Resend resend,
) {
  return resend.events.list(pagination: PaginationOptions(limit: 25));
}

/// Retrieves a custom event definition by ID or name.
Future<ResendResponse<CustomEvent>> retrieveCustomEvent(
  Resend resend,
  String idOrName,
) {
  return resend.events.retrieve(idOrName);
}

/// Replaces a custom event's schema; pass `null` to remove it.
Future<ResendResponse<ResendId>> updateCustomEvent(
  Resend resend,
  String idOrName,
) {
  return resend.events.update(
    idOrName,
    UpdateEventRequest(
      schema: <String, EventSchemaType>{
        'plan': EventSchemaType.string,
        'seats': EventSchemaType.number,
      },
    ),
  );
}

/// Deletes a custom event definition by ID or name.
Future<ResendResponse<ResendDeletion>> deleteCustomEvent(
  Resend resend,
  String idOrName,
) {
  return resend.events.delete(idOrName);
}

/// Sends an event to an existing contact ID.
Future<ResendResponse<SentEvent>> sendEventToContact(
  Resend resend,
  String contactId,
) {
  return resend.events.send(
    SendEventRequest.toContact(
      event: 'trial.started',
      contactId: contactId,
      payload: <String, Object?>{'plan': 'pro', 'seats': 5},
    ),
  );
}

/// Sends an event to a contact selected by email address.
Future<ResendResponse<SentEvent>> sendEventToEmail(Resend resend) {
  return resend.events.send(
    SendEventRequest.toEmail(
      event: 'trial.started',
      email: 'ada@example.com',
      payload: <String, Object?>{'plan': 'pro', 'seats': 5},
    ),
  );
}
