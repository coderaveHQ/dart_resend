import '../core/json.dart';
import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// A documented property type in a custom-event schema.
enum EventSchemaType implements ResendWireValue {
  /// A text value.
  string('string'),

  /// A numeric value.
  number('number'),

  /// A true-or-false value.
  boolean('boolean'),

  /// An ISO-8601 date value.
  date('date');

  const EventSchemaType(this.value);

  @override
  final String value;
}

/// Parameters for defining a custom event.
final class CreateEventRequest implements ResendRequest {
  /// Creates custom-event parameters.
  CreateEventRequest({
    required String name,
    Map<String, EventSchemaType>? schema,
  }) : name = requireNonBlank(name, 'name'),
       schema = schema == null ? null : _validatedSchema(schema);

  /// Event name used by automation triggers.
  final String name;

  /// Optional immutable payload schema.
  final Map<String, EventSchemaType>? schema;

  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'name': name,
    'schema': schema == null ? null : _schemaJson(schema!),
  });
}

/// Parameters for replacing a custom event's schema.
final class UpdateEventRequest implements ResendRequest {
  /// Creates schema replacement parameters.
  ///
  /// A `null` [schema] removes the current schema.
  UpdateEventRequest({required Map<String, EventSchemaType>? schema})
    : schema = schema == null ? null : _validatedSchema(schema);

  /// Replacement schema, or `null` to clear it.
  final Map<String, EventSchemaType>? schema;

  @override
  JsonObject toJson() => immutableJsonMap(<String, Object?>{
    'schema': schema == null ? null : _schemaJson(schema!),
  });
}

/// Parameters for sending an event to matching automations.
final class SendEventRequest implements ResendRequest {
  /// Creates event-send parameters.
  ///
  /// Exactly one of [contactId] and [email] must be supplied.
  SendEventRequest({
    required String event,
    String? contactId,
    String? email,
    JsonObject? payload,
  }) : event = requireNonBlank(event, 'event'),
       contactId = _optionalNonBlank(contactId, 'contactId'),
       email = _optionalNonBlank(email, 'email'),
       payload = payload == null ? null : immutableJsonMap(payload) {
    if ((this.contactId == null) == (this.email == null)) {
      throw ArgumentError('Exactly one of contactId and email is required.');
    }
  }

  /// Creates parameters targeting an existing contact ID.
  factory SendEventRequest.toContact({
    required String event,
    required String contactId,
    JsonObject? payload,
  }) {
    return SendEventRequest(
      event: event,
      contactId: contactId,
      payload: payload,
    );
  }

  /// Creates parameters targeting a contact email address.
  factory SendEventRequest.toEmail({
    required String event,
    required String email,
    JsonObject? payload,
  }) {
    return SendEventRequest(event: event, email: email, payload: payload);
  }

  /// Custom event name.
  final String event;

  /// Existing contact ID, when targeting by ID.
  final String? contactId;

  /// Contact email address, when targeting by email.
  final String? email;

  /// Deeply immutable event payload.
  final JsonObject? payload;

  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'event': event,
    'contact_id': contactId,
    'email': email,
    'payload': payload,
  });
}

/// A custom event definition returned by Resend.
final class CustomEvent extends ResendModel {
  /// Decodes a custom event definition.
  CustomEvent.fromJson(super.json);

  /// Event definition ID.
  String get id => field<String>('id');

  /// Event name.
  String get name => field<String>('name');

  /// Raw schema strings, preserved for forward compatibility.
  Map<String, String>? get schema {
    final JsonObject? encoded = optionalObjectField('schema');
    if (encoded == null) return null;
    final Map<String, String> result = <String, String>{};
    for (final MapEntry<String, Object?> entry in encoded.entries) {
      final Object? value = entry.value;
      if (value is! String) {
        throw FormatException(
          'Expected schema value "${entry.key}" to be a string.',
        );
      }
      result[entry.key] = value;
    }
    return Map<String, String>.unmodifiable(result);
  }

  /// Creation timestamp.
  DateTime get createdAt => dateTimeField('created_at');

  /// Last update timestamp, when present.
  DateTime? get updatedAt => optionalDateTimeField('updated_at');

  /// Raw object discriminator, when returned.
  String? get object => optionalField<String>('object');
}

/// Response returned after an event is sent.
final class SentEvent extends ResendModel {
  /// Decodes an event-send response.
  SentEvent.fromJson(super.json);

  /// Raw object discriminator.
  String get object => field<String>('object');

  /// Name of the event that was accepted.
  String get event => field<String>('event');
}

/// Operations for defining and sending custom automation events.
final class EventsResource {
  /// Creates an events resource client.
  EventsResource(this._transport);

  final ResendTransport _transport;

  /// Creates a custom event definition.
  Future<ResendResponse<ResendId>> create(CreateEventRequest request) {
    return _transport.post<ResendId>(
      pathSegments: <String>['events'],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Lists custom event definitions.
  Future<ResendResponse<ResendPage<CustomEvent>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<CustomEvent>>(
      pathSegments: <String>['events'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<CustomEvent>.fromJson(json, CustomEvent.fromJson),
    );
  }

  /// Retrieves a custom event by ID or name.
  Future<ResendResponse<CustomEvent>> retrieve(String idOrName) {
    return _transport.get<CustomEvent>(
      pathSegments: <String>['events', requireNonBlank(idOrName, 'idOrName')],
      decode: CustomEvent.fromJson,
    );
  }

  /// Replaces the schema of a custom event selected by ID or name.
  Future<ResendResponse<ResendId>> update(
    String idOrName,
    UpdateEventRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>['events', requireNonBlank(idOrName, 'idOrName')],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Deletes a custom event selected by ID or name.
  Future<ResendResponse<ResendDeletion>> delete(String idOrName) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>['events', requireNonBlank(idOrName, 'idOrName')],
      decode: ResendDeletion.fromJson,
    );
  }

  /// Sends an event to trigger matching enabled automations.
  Future<ResendResponse<SentEvent>> send(SendEventRequest request) {
    return _transport.post<SentEvent>(
      pathSegments: <String>['events', 'send'],
      body: request.toJson(),
      decode: SentEvent.fromJson,
    );
  }
}

Map<String, EventSchemaType> _validatedSchema(
  Map<String, EventSchemaType> schema,
) {
  for (final String key in schema.keys) {
    requireNonBlank(key, 'schema key');
  }
  return Map<String, EventSchemaType>.unmodifiable(schema);
}

JsonObject _schemaJson(Map<String, EventSchemaType> schema) {
  return immutableJsonMap(<String, Object?>{
    for (final MapEntry<String, EventSchemaType> entry in schema.entries)
      entry.key: entry.value.value,
  });
}

String? _optionalNonBlank(String? value, String name) {
  return value == null ? null : requireNonBlank(value, name);
}
