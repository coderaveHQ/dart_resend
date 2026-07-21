import 'dart:convert';

import '../core/json.dart';
import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';
import 'topics.dart';

/// A reference to a segment when creating or importing contacts.
final class ContactSegmentReference implements ResendRequest {
  /// Creates a segment reference.
  ContactSegmentReference(String id) : id = requireNonBlank(id, 'id');

  /// The segment ID.
  final String id;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => <String, Object?>{'id': id};
}

/// A topic subscription to assign to a contact.
final class ContactTopicSubscription implements ResendRequest {
  /// Creates a topic subscription.
  ContactTopicSubscription({required String id, required this.subscription})
    : id = requireNonBlank(id, 'id');

  /// The topic ID.
  final String id;

  /// The contact's subscription preference for the topic.
  final TopicSubscription subscription;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => <String, Object?>{
    'id': id,
    'subscription': subscription.value,
  };
}

/// Parameters for creating a global Resend contact.
final class CreateContactRequest implements ResendRequest {
  /// Creates contact parameters.
  CreateContactRequest({
    required String email,
    String? firstName,
    String? lastName,
    this.unsubscribed,
    Map<String, Object?>? properties,
    List<ContactSegmentReference> segments = const <ContactSegmentReference>[],
    List<ContactTopicSubscription> topics = const <ContactTopicSubscription>[],
  }) : email = requireNonBlank(email, 'email'),
       firstName = _optionalNonBlank(firstName, 'firstName'),
       lastName = _optionalNonBlank(lastName, 'lastName'),
       properties = properties == null
           ? null
           : _validatedProperties(properties),
       segments = _validatedSegments(segments),
       topics = _validatedTopics(topics);

  /// The contact's email address.
  final String email;

  /// The contact's first name.
  final String? firstName;

  /// The contact's last name.
  final String? lastName;

  /// Whether the contact is globally unsubscribed from broadcasts.
  final bool? unsubscribed;

  /// Custom property values keyed by an existing contact-property key.
  final JsonObject? properties;

  /// Segments to which the contact is added during creation.
  final List<ContactSegmentReference> segments;

  /// Initial topic subscriptions for the contact.
  final List<ContactTopicSubscription> topics;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'unsubscribed': unsubscribed,
    'properties': properties,
    if (segments.isNotEmpty)
      'segments': segments
          .map((ContactSegmentReference item) => item.toJson())
          .toList(growable: false),
    if (topics.isNotEmpty)
      'topics': topics
          .map((ContactTopicSubscription item) => item.toJson())
          .toList(growable: false),
  });
}

/// Parameters for updating a contact by ID or email address.
final class UpdateContactRequest implements ResendRequest {
  /// Creates contact-update parameters.
  UpdateContactRequest({
    String? firstName,
    String? lastName,
    this.unsubscribed,
    Map<String, Object?>? properties,
    this.clearFirstName = false,
    this.clearLastName = false,
  }) : firstName = _optionalNonBlank(firstName, 'firstName'),
       lastName = _optionalNonBlank(lastName, 'lastName'),
       properties = properties == null
           ? null
           : _validatedProperties(properties) {
    if (firstName != null && clearFirstName) {
      throw ArgumentError('firstName and clearFirstName cannot both be set.');
    }
    if (lastName != null && clearLastName) {
      throw ArgumentError('lastName and clearLastName cannot both be set.');
    }
    if (firstName == null &&
        lastName == null &&
        unsubscribed == null &&
        properties == null &&
        !clearFirstName &&
        !clearLastName) {
      throw ArgumentError('At least one contact field must be updated.');
    }
  }

  /// The replacement first name.
  final String? firstName;

  /// The replacement last name.
  final String? lastName;

  /// The replacement global subscription status.
  final bool? unsubscribed;

  /// Property changes. A null value removes that contact's property value.
  final JsonObject? properties;

  /// Whether to clear the contact's first name.
  final bool clearFirstName;

  /// Whether to clear the contact's last name.
  final bool clearLastName;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => Map<String, Object?>.unmodifiable(<String, Object?>{
    if (clearFirstName)
      'first_name': null
    else if (firstName != null)
      'first_name': firstName,
    if (clearLastName)
      'last_name': null
    else if (lastName != null)
      'last_name': lastName,
    if (unsubscribed != null) 'unsubscribed': unsubscribed,
    if (properties != null) 'properties': properties,
  });
}

/// Parameters for replacing a contact's topic subscriptions.
final class UpdateContactTopicsRequest {
  /// Creates topic-update parameters.
  UpdateContactTopicsRequest(List<ContactTopicSubscription> topics)
    : topics = _validatedTopics(requireNonEmpty(topics, 'topics'));

  /// Topic subscriptions to update.
  final List<ContactTopicSubscription> topics;

  /// Converts this update to Resend's top-level JSON-array wire format.
  List<JsonObject> toJson() => List<JsonObject>.unmodifiable(
    topics.map((ContactTopicSubscription item) => item.toJson()),
  );
}

/// A contact returned by Resend.
final class Contact extends ResendModel {
  /// Decodes a contact.
  Contact.fromJson(super.json);

  /// The contact ID.
  String get id => field<String>('id');

  /// The contact email address.
  String get email => field<String>('email');

  /// The contact first name, when set.
  String? get firstName => optionalField<String>('first_name');

  /// The contact last name, when set.
  String? get lastName => optionalField<String>('last_name');

  /// When the contact was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// Whether the contact is globally unsubscribed.
  bool get unsubscribed => field<bool>('unsubscribed');

  /// Custom property values returned for this contact.
  Map<String, ContactPropertyValue>? get properties {
    final JsonObject? encoded = optionalObjectField('properties');
    if (encoded == null) return null;
    return Map<String, ContactPropertyValue>.unmodifiable(
      encoded.map(
        (String key, Object? value) => MapEntry<String, ContactPropertyValue>(
          key,
          ContactPropertyValue.fromJson(_responseObject(value, 'properties')),
        ),
      ),
    );
  }

  /// The raw object discriminator, when returned by Resend.
  String? get object => optionalField<String>('object');
}

/// One custom property value returned for a contact.
final class ContactPropertyValue extends ResendModel {
  /// Decodes a contact property value.
  ContactPropertyValue.fromJson(super.json);

  /// The raw property type, preserved for forward compatibility.
  String get type => field<String>('type');

  /// The property's value.
  Object? get value => this.json['value'];
}

/// A segment returned for a contact-membership list.
final class ContactSegment extends ResendModel {
  /// Decodes a contact segment.
  ContactSegment.fromJson(super.json);

  /// The segment ID.
  String get id => field<String>('id');

  /// The segment name.
  String get name => field<String>('name');

  /// When the segment was created.
  DateTime get createdAt => dateTimeField('created_at');
}

/// The result of removing a contact from a segment.
final class ContactSegmentDeletion extends ResendModel {
  /// Decodes a contact-segment deletion.
  ContactSegmentDeletion.fromJson(super.json);

  /// The contact ID.
  String get contactId => field<String>('id');

  /// The segment ID.
  ///
  /// Resend currently returns this under the legacy `audienceId` key. The
  /// alternate spellings are accepted so a server-side migration is harmless.
  String get segmentId {
    final Object? value =
        this.json['segment_id'] ??
        this.json['audienceId'] ??
        this.json['audience_id'];
    if (value is String) return value;
    throw FormatException(
      'Expected a segment ID in ContactSegmentDeletion, got '
      '${value.runtimeType}.',
    );
  }

  /// Whether the membership was deleted.
  bool get deleted => field<bool>('deleted');
}

/// A topic and the selected subscription preference for a contact.
final class ContactTopic extends ResendModel {
  /// Decodes a contact topic.
  ContactTopic.fromJson(super.json);

  /// The topic ID.
  String get id => field<String>('id');

  /// The topic name.
  String get name => field<String>('name');

  /// The topic description, when set.
  String? get description => optionalField<String>('description');

  /// The raw subscription value, preserved for forward compatibility.
  String get subscription => field<String>('subscription');
}

/// How an import handles a contact whose email already exists.
enum ContactImportOnConflict implements ResendWireValue {
  /// Update the existing contact with values from the CSV row.
  upsert('upsert'),

  /// Leave the existing contact unchanged.
  skip('skip');

  const ContactImportOnConflict(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// A contact-import status accepted by the list filter.
enum ContactImportStatus implements ResendWireValue {
  /// Waiting to be processed.
  queued('queued'),

  /// Currently being processed.
  inProgress('in_progress'),

  /// Processing completed successfully.
  completed('completed'),

  /// Processing failed.
  failed('failed');

  const ContactImportStatus(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// The type used when mapping a CSV column to a custom property.
enum ContactImportPropertyType implements ResendWireValue {
  /// Text values.
  string('string'),

  /// Numeric values.
  number('number'),

  /// Boolean values.
  boolean('boolean');

  const ContactImportPropertyType(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// A CSV-column mapping for one custom contact property.
final class ContactImportPropertyMapping implements ResendRequest {
  /// Creates a custom-property column mapping.
  ContactImportPropertyMapping({required String column, this.type})
    : column = requireNonBlank(column, 'column');

  /// The CSV header containing the property value.
  final String column;

  /// How the CSV value is decoded. Resend defaults this when omitted.
  final ContactImportPropertyType? type;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() =>
      compactJson(<String, Object?>{'column': column, 'type': type?.value});
}

/// Maps CSV headers to built-in and custom contact fields.
final class ContactImportColumnMap implements ResendRequest {
  /// Creates a CSV column map.
  ContactImportColumnMap({
    String? email,
    String? firstName,
    String? lastName,
    String? unsubscribed,
    Map<String, ContactImportPropertyMapping> properties =
        const <String, ContactImportPropertyMapping>{},
  }) : email = _optionalNonBlank(email, 'email'),
       firstName = _optionalNonBlank(firstName, 'firstName'),
       lastName = _optionalNonBlank(lastName, 'lastName'),
       unsubscribed = _optionalNonBlank(unsubscribed, 'unsubscribed'),
       properties = _validatedPropertyMappings(properties) {
    if (email == null &&
        firstName == null &&
        lastName == null &&
        unsubscribed == null &&
        properties.isEmpty) {
      throw ArgumentError('A column map must contain at least one mapping.');
    }
  }

  /// CSV header containing the email address.
  final String? email;

  /// CSV header containing the first name.
  final String? firstName;

  /// CSV header containing the last name.
  final String? lastName;

  /// CSV header containing the global unsubscribe value.
  final String? unsubscribed;

  /// Custom property keys and their CSV-column mappings.
  final Map<String, ContactImportPropertyMapping> properties;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'unsubscribed': unsubscribed,
    if (properties.isNotEmpty)
      'properties': <String, Object?>{
        for (final MapEntry<String, ContactImportPropertyMapping> entry
            in properties.entries)
          entry.key: entry.value.toJson(),
      },
  });
}

/// Parameters for starting an asynchronous CSV contact import.
final class CreateContactImportRequest {
  /// Creates contact-import parameters.
  CreateContactImportRequest({
    required List<int> bytes,
    required String filename,
    this.columnMap,
    this.onConflict,
    List<ContactSegmentReference> segments = const <ContactSegmentReference>[],
    List<ContactTopicSubscription> topics = const <ContactTopicSubscription>[],
  }) : bytes = _validatedFileBytes(bytes),
       filename = requireNonBlank(filename, 'filename'),
       segments = _validatedSegments(segments),
       topics = _validatedTopics(topics);

  /// In-memory CSV file bytes.
  final List<int> bytes;

  /// Filename reported in the multipart upload.
  final String filename;

  /// Optional mapping from contact fields to CSV headers.
  final ContactImportColumnMap? columnMap;

  /// How existing contacts are handled.
  final ContactImportOnConflict? onConflict;

  /// Segments assigned to every imported contact.
  final List<ContactSegmentReference> segments;

  /// Topic subscriptions assigned to every imported contact.
  final List<ContactTopicSubscription> topics;

  /// Encodes non-file import options as multipart form fields.
  Map<String, String> _toMultipartFields() => <String, String>{
    if (columnMap != null) 'column_map': jsonEncode(columnMap!.toJson()),
    if (onConflict != null) 'on_conflict': onConflict!.value,
    if (segments.isNotEmpty)
      'segments': jsonEncode(
        segments
            .map((ContactSegmentReference item) => item.toJson())
            .toList(growable: false),
      ),
    if (topics.isNotEmpty)
      'topics': jsonEncode(
        topics
            .map((ContactTopicSubscription item) => item.toJson())
            .toList(growable: false),
      ),
  };
}

/// Row counts reported for a contact import.
final class ContactImportCounts extends ResendModel {
  /// Decodes contact-import counts.
  ContactImportCounts.fromJson(super.json);

  /// Total CSV rows considered.
  int get total => field<int>('total');

  /// Contacts created.
  int get created => field<int>('created');

  /// Existing contacts updated.
  int get updated => field<int>('updated');

  /// CSV rows skipped.
  int get skipped => field<int>('skipped');

  /// CSV rows that failed.
  int get failed => field<int>('failed');
}

/// An asynchronous CSV contact import.
final class ContactImport extends ResendModel {
  /// Decodes a contact import.
  ContactImport.fromJson(super.json);

  /// The contact-import ID.
  String get id => field<String>('id');

  /// The raw status value, preserved for forward compatibility.
  String get status => field<String>('status');

  /// When the import was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// When processing completed, if it has finished.
  DateTime? get completedAt => optionalDateTimeField('completed_at');

  /// Current row counts.
  ContactImportCounts get counts =>
      ContactImportCounts.fromJson(objectField('counts'));

  /// The raw object discriminator, when returned by Resend.
  String? get object => optionalField<String>('object');
}

/// Operations for asynchronous CSV contact imports.
final class ContactImportsResource {
  /// Creates a contact-import resource client.
  ContactImportsResource(this._transport);

  /// Transport used to execute contact-import endpoint requests.
  final ResendTransport _transport;

  /// Starts an asynchronous CSV contact import.
  Future<ResendResponse<ResendId>> create(CreateContactImportRequest request) {
    return _transport.multipartPost<ResendId>(
      pathSegments: <String>['contacts', 'imports'],
      bytes: request.bytes,
      filename: request.filename,
      fields: request._toMultipartFields(),
      decode: ResendId.fromJson,
    );
  }

  /// Lists contact imports.
  Future<ResendResponse<ResendPage<ContactImport>>> list({
    ContactImportStatus? status,
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<ContactImport>>(
      pathSegments: <String>['contacts', 'imports'],
      query: <String, String>{
        ...?pagination?.toQuery(),
        if (status != null) 'status': status.value,
      },
      decode: (JsonObject json) =>
          ResendPage<ContactImport>.fromJson(json, ContactImport.fromJson),
    );
  }

  /// Retrieves one contact import by [id].
  Future<ResendResponse<ContactImport>> retrieve(String id) {
    return _transport.get<ContactImport>(
      pathSegments: <String>['contacts', 'imports', requireNonBlank(id, 'id')],
      decode: ContactImport.fromJson,
    );
  }
}

/// Operations for global contacts, memberships, topics, and CSV imports.
final class ContactsResource {
  /// Creates a contacts resource client.
  ContactsResource(ResendTransport transport)
    : _transport = transport,
      imports = ContactImportsResource(transport);

  /// Transport shared by direct contacts and nested import operations.
  final ResendTransport _transport;

  /// Asynchronous CSV contact-import operations.
  final ContactImportsResource imports;

  /// Creates a global contact.
  Future<ResendResponse<ResendId>> create(CreateContactRequest request) {
    return _transport.post<ResendId>(
      pathSegments: <String>['contacts'],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Lists global contacts or contacts in [segmentId].
  ///
  /// Resend documents segment filtering at
  /// `GET /segments/{segment_id}/contacts`, so this method uses that route
  /// instead of the inconsistent `segment_id` query found in OpenAPI.
  Future<ResendResponse<ResendPage<Contact>>> list({
    String? segmentId,
    PaginationOptions? pagination,
  }) {
    final List<String> pathSegments = segmentId == null
        ? <String>['contacts']
        : <String>[
            'segments',
            requireNonBlank(segmentId, 'segmentId'),
            'contacts',
          ];
    return _transport.get<ResendPage<Contact>>(
      pathSegments: pathSegments,
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<Contact>.fromJson(json, Contact.fromJson),
    );
  }

  /// Retrieves a contact by ID or email address.
  Future<ResendResponse<Contact>> retrieve(String idOrEmail) {
    return _transport.get<Contact>(
      pathSegments: <String>[
        'contacts',
        requireNonBlank(idOrEmail, 'idOrEmail'),
      ],
      decode: Contact.fromJson,
    );
  }

  /// Updates a contact by ID or email address.
  Future<ResendResponse<ResendId>> update(
    String idOrEmail,
    UpdateContactRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>[
        'contacts',
        requireNonBlank(idOrEmail, 'idOrEmail'),
      ],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Deletes a contact by ID or email address.
  Future<ResendResponse<ResendDeletion>> delete(String idOrEmail) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>[
        'contacts',
        requireNonBlank(idOrEmail, 'idOrEmail'),
      ],
      decode: ResendDeletion.fromJson,
    );
  }

  /// Lists the segments to which a contact belongs.
  Future<ResendResponse<ResendPage<ContactSegment>>> listSegments(
    String idOrEmail, {
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<ContactSegment>>(
      pathSegments: <String>[
        'contacts',
        requireNonBlank(idOrEmail, 'idOrEmail'),
        'segments',
      ],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<ContactSegment>.fromJson(json, ContactSegment.fromJson),
    );
  }

  /// Adds a contact to a segment.
  Future<ResendResponse<ResendId>> addToSegment(
    String idOrEmail,
    String segmentId,
  ) {
    return _transport.post<ResendId>(
      pathSegments: <String>[
        'contacts',
        requireNonBlank(idOrEmail, 'idOrEmail'),
        'segments',
        requireNonBlank(segmentId, 'segmentId'),
      ],
      decode: ResendId.fromJson,
    );
  }

  /// Removes a contact from a segment.
  Future<ResendResponse<ContactSegmentDeletion>> removeFromSegment(
    String idOrEmail,
    String segmentId,
  ) {
    return _transport.delete<ContactSegmentDeletion>(
      pathSegments: <String>[
        'contacts',
        requireNonBlank(idOrEmail, 'idOrEmail'),
        'segments',
        requireNonBlank(segmentId, 'segmentId'),
      ],
      decode: ContactSegmentDeletion.fromJson,
    );
  }

  /// Lists a contact's topic subscriptions.
  Future<ResendResponse<ResendPage<ContactTopic>>> listTopics(
    String idOrEmail, {
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<ContactTopic>>(
      pathSegments: <String>[
        'contacts',
        requireNonBlank(idOrEmail, 'idOrEmail'),
        'topics',
      ],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<ContactTopic>.fromJson(json, ContactTopic.fromJson),
    );
  }

  /// Replaces topic subscription values for a contact.
  Future<ResendResponse<ResendId>> updateTopics(
    String idOrEmail,
    UpdateContactTopicsRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>[
        'contacts',
        requireNonBlank(idOrEmail, 'idOrEmail'),
        'topics',
      ],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }
}

/// Validates [value] when present while preserving null omission semantics.
String? _optionalNonBlank(String? value, String name) {
  return value == null ? null : requireNonBlank(value, name);
}

/// Validates custom contact-property names and JSON-compatible values.
JsonObject _validatedProperties(Map<String, Object?> values) {
  final JsonObject result = <String, Object?>{};
  for (final MapEntry<String, Object?> entry in values.entries) {
    final String key = requireNonBlank(entry.key, 'properties key');
    final Object? value = entry.value;
    if (value != null && value is! String && value is! num) {
      throw ArgumentError.value(
        value,
        'properties[$key]',
        'Must be a string, number, or null.',
      );
    }
    result[key] = value;
  }
  return immutableJsonMap(result);
}

/// Validates, copies, and freezes contact segment references.
List<ContactSegmentReference> _validatedSegments(
  List<ContactSegmentReference> values,
) {
  final Set<String> ids = <String>{};
  for (final ContactSegmentReference value in values) {
    if (!ids.add(value.id)) {
      throw ArgumentError.value(values, 'segments', 'IDs must be unique.');
    }
  }
  return List<ContactSegmentReference>.unmodifiable(values);
}

/// Validates, copies, and freezes contact topic subscriptions.
List<ContactTopicSubscription> _validatedTopics(
  List<ContactTopicSubscription> values,
) {
  final Set<String> ids = <String>{};
  for (final ContactTopicSubscription value in values) {
    if (!ids.add(value.id)) {
      throw ArgumentError.value(values, 'topics', 'IDs must be unique.');
    }
  }
  return List<ContactTopicSubscription>.unmodifiable(values);
}

/// Validates, copies, and freezes CSV column-to-property mappings.
Map<String, ContactImportPropertyMapping> _validatedPropertyMappings(
  Map<String, ContactImportPropertyMapping> values,
) {
  final Map<String, ContactImportPropertyMapping> result =
      <String, ContactImportPropertyMapping>{};
  for (final MapEntry<String, ContactImportPropertyMapping> entry
      in values.entries) {
    result[requireNonBlank(entry.key, 'properties key')] = entry.value;
  }
  return Map<String, ContactImportPropertyMapping>.unmodifiable(result);
}

/// Validates and freezes an import file within Resend's byte-size limit.
List<int> _validatedFileBytes(List<int> bytes) {
  if (bytes.isEmpty) {
    throw ArgumentError.value(bytes, 'bytes', 'Must not be empty.');
  }
  for (final int byte in bytes) {
    if (byte < 0 || byte > 255) {
      throw RangeError.range(byte, 0, 255, 'bytes');
    }
  }
  return List<int>.unmodifiable(bytes);
}

/// Validates and freezes one object nested in response [field].
JsonObject _responseObject(Object? value, String field) {
  if (value is JsonObject) return value;
  throw FormatException(
    'Expected every "$field" value to be a JSON object, got '
    '${value.runtimeType}.',
  );
}
