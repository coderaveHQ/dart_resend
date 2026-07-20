import '../core/json.dart';

/// A JSON object used by the Resend API.
typedef JsonObject = JsonMap;

/// Base class for immutable, forward-compatible Resend response models.
///
/// Typed getters expose documented fields while [json] preserves any fields
/// added by Resend before this package is updated.
abstract base class ResendModel {
  /// Creates a model from a decoded JSON object.
  ResendModel(JsonObject json) : json = immutableJsonMap(json);

  /// The complete immutable JSON object returned by Resend.
  final JsonObject json;

  /// Reads a required field and checks its runtime type.
  T field<T>(String key) {
    final Object? value = json[key];
    if (value is T) return value;
    throw FormatException(
      'Expected "$key" in $runtimeType to be $T, got ${value.runtimeType}.',
    );
  }

  /// Reads an optional field and checks its runtime type when present.
  T? optionalField<T>(String key) {
    final Object? value = json[key];
    if (value == null) return null;
    if (value is T) return value as T;
    throw FormatException(
      'Expected "$key" in $runtimeType to be $T, got ${value.runtimeType}.',
    );
  }

  /// Reads a required JSON object field.
  JsonObject objectField(String key) => _asObject(field<Object>(key), key);

  /// Reads an optional JSON object field.
  JsonObject? optionalObjectField(String key) {
    final Object? value = json[key];
    return value == null ? null : _asObject(value, key);
  }

  /// Reads a required list field and checks every element's runtime type.
  List<T> listField<T>(String key) {
    final Object value = field<Object>(key);
    if (value is! List<Object?>) {
      throw FormatException('Expected "$key" in $runtimeType to be a list.');
    }
    return List<T>.unmodifiable(
      value.map((Object? item) {
        if (item is T) return item;
        throw FormatException(
          'Expected every "$key" item in $runtimeType to be $T, '
          'got ${item.runtimeType}.',
        );
      }),
    );
  }

  /// Reads an optional list field and checks every element's runtime type.
  List<T>? optionalListField<T>(String key) {
    if (json[key] == null) return null;
    return listField<T>(key);
  }

  /// Reads an ISO-8601 timestamp.
  DateTime dateTimeField(String key) => DateTime.parse(field<String>(key));

  /// Reads an optional ISO-8601 timestamp.
  DateTime? optionalDateTimeField(String key) {
    final String? value = optionalField<String>(key);
    return value == null ? null : DateTime.parse(value);
  }

  @override
  String toString() => '$runtimeType($json)';
}

/// A standard response containing the ID of a resource.
final class ResendId extends ResendModel {
  /// Creates an ID response from JSON.
  ResendId.fromJson(super.json);

  /// The resource ID.
  String get id => field<String>('id');

  /// The resource object type when returned by the endpoint.
  String? get object => optionalField<String>('object');
}

/// A standard response indicating that a resource was deleted.
final class ResendDeletion extends ResendModel {
  /// Creates a deletion response from JSON.
  ResendDeletion.fromJson(super.json);

  /// The deleted resource ID when returned by the endpoint.
  String? get id => optionalField<String>('id');

  /// The resource object type when returned by the endpoint.
  String? get object => optionalField<String>('object');

  /// Whether deletion succeeded when returned by the endpoint.
  bool? get deleted => optionalField<bool>('deleted');
}

/// A cursor-paginated collection returned by Resend.
final class ResendPage<T> extends ResendModel {
  ResendPage._(super.json, this.data);

  /// Decodes a cursor-paginated response.
  factory ResendPage.fromJson(
    JsonObject json,
    T Function(JsonObject json) decodeItem,
  ) {
    final ResendModel reader = _RawModel(json);
    final List<Object?> encoded = reader.listField<Object?>('data');
    final List<T> data = List<T>.unmodifiable(
      encoded.map((Object? item) => decodeItem(_asObject(item, 'data'))),
    );
    return ResendPage<T>._(json, data);
  }

  /// The decoded resources in this page.
  final List<T> data;

  /// Whether another page is available.
  bool get hasMore => optionalField<bool>('has_more') ?? false;

  /// The response object type, normally `list`.
  String get object => optionalField<String>('object') ?? 'list';
}

/// A non-paginated `data` collection returned by a batch operation.
final class ResendCollection<T> extends ResendModel {
  ResendCollection._(super.json, this.data);

  /// Decodes a collection response.
  factory ResendCollection.fromJson(
    JsonObject json,
    T Function(JsonObject json) decodeItem,
  ) {
    final ResendModel reader = _RawModel(json);
    final List<Object?> encoded = reader.listField<Object?>('data');
    final List<T> data = List<T>.unmodifiable(
      encoded.map((Object? item) => decodeItem(_asObject(item, 'data'))),
    );
    return ResendCollection<T>._(json, data);
  }

  /// The decoded resources in this collection.
  final List<T> data;
}

final class _RawModel extends ResendModel {
  _RawModel(super.json);
}

JsonObject _asObject(Object? value, String key) {
  if (value is Map<String, Object?>) return immutableJsonMap(value);
  throw FormatException('Expected "$key" to be a JSON object.');
}
