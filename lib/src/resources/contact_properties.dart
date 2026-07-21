import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// A supported custom contact-property type.
enum ContactPropertyType implements ResendWireValue {
  /// Text values.
  string('string'),

  /// Numeric values.
  number('number');

  const ContactPropertyType(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// Parameters for creating a custom contact property.
final class CreateContactPropertyRequest implements ResendRequest {
  /// Creates contact-property parameters.
  CreateContactPropertyRequest({
    required String key,
    required this.type,
    Object? fallbackValue,
  }) : key = _validatedKey(key),
       fallbackValue = _validatedFallback(fallbackValue, type);

  /// The property key used in contact property maps.
  ///
  /// Keys may contain ASCII letters, digits, and underscores and are limited
  /// to 50 characters by Resend.
  final String key;

  /// The value type accepted by this property.
  final ContactPropertyType type;

  /// The value returned when a contact has no explicit property value.
  final Object? fallbackValue;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'key': key,
    'type': type.value,
    'fallback_value': fallbackValue,
  });
}

/// Parameters for updating a custom contact property's fallback value.
final class UpdateContactPropertyRequest implements ResendRequest {
  /// Creates contact-property update parameters.
  ///
  /// Pass `null` to clear the existing fallback value.
  UpdateContactPropertyRequest({required Object? fallbackValue})
    : fallbackValue = _validatedUpdateFallback(fallbackValue);

  /// The replacement fallback value, or `null` to clear it.
  final Object? fallbackValue;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => <String, Object?>{'fallback_value': fallbackValue};
}

/// A custom contact property returned by Resend.
final class ContactProperty extends ResendModel {
  /// Decodes a contact property.
  ContactProperty.fromJson(super.json);

  /// The contact-property ID.
  String get id => field<String>('id');

  /// The key used in contact property maps.
  String get key => field<String>('key');

  /// The raw property type, preserved for forward compatibility.
  String get type => field<String>('type');

  /// The configured fallback value, or `null` when none is set.
  Object? get fallbackValue => json['fallback_value'];

  /// When the property was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// The raw object discriminator, when returned by Resend.
  String? get object => optionalField<String>('object');
}

/// Operations for managing custom contact properties.
final class ContactPropertiesResource {
  /// Creates a contact-properties resource client.
  ContactPropertiesResource(this._transport);

  /// Transport used to execute contact-property endpoint requests.
  final ResendTransport _transport;

  /// Creates a custom contact property.
  Future<ResendResponse<ResendId>> create(
    CreateContactPropertyRequest request,
  ) {
    return _transport.post<ResendId>(
      pathSegments: <String>['contact-properties'],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Lists custom contact properties using cursor pagination.
  Future<ResendResponse<ResendPage<ContactProperty>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<ContactProperty>>(
      pathSegments: <String>['contact-properties'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<ContactProperty>.fromJson(json, ContactProperty.fromJson),
    );
  }

  /// Retrieves a custom contact property by [id].
  Future<ResendResponse<ContactProperty>> retrieve(String id) {
    return _transport.get<ContactProperty>(
      pathSegments: <String>['contact-properties', requireNonBlank(id, 'id')],
      decode: ContactProperty.fromJson,
    );
  }

  /// Updates a custom contact property's fallback value.
  Future<ResendResponse<ResendId>> update(
    String id,
    UpdateContactPropertyRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>['contact-properties', requireNonBlank(id, 'id')],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Deletes a custom contact property by [id].
  Future<ResendResponse<ResendDeletion>> delete(String id) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>['contact-properties', requireNonBlank(id, 'id')],
      decode: ResendDeletion.fromJson,
    );
  }
}

/// Validates the API's identifier syntax for a contact-property key.
String _validatedKey(String value) {
  final String key = requireNonBlank(value, 'key');
  if (key.length > 50) {
    throw ArgumentError.value(value, 'key', 'Must be at most 50 characters.');
  }
  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(key)) {
    throw ArgumentError.value(
      value,
      'key',
      'May contain only ASCII letters, digits, and underscores.',
    );
  }
  return key;
}

/// Validates a create fallback against the property's declared [type].
Object? _validatedFallback(Object? value, ContactPropertyType type) {
  if (value == null ||
      (type == ContactPropertyType.string && value is String) ||
      (type == ContactPropertyType.number && value is num)) {
    return value;
  }
  throw ArgumentError.value(
    value,
    'fallbackValue',
    'Must match the selected contact-property type.',
  );
}

/// Validates an update fallback as null or a supported JSON scalar.
Object? _validatedUpdateFallback(Object? value) {
  if (value == null || value is String || value is num) {
    return value;
  }
  throw ArgumentError.value(
    value,
    'fallbackValue',
    'Must be a string, number, or null.',
  );
}
