import 'base.dart';

/// A request that can be serialized for the Resend API.
abstract interface class ResendRequest {
  /// Converts this request to its wire-format JSON object.
  JsonObject toJson();
}

/// Builds a JSON object while omitting entries whose value is `null`.
JsonObject compactJson(JsonObject values) {
  return Map<String, Object?>.unmodifiable(
    Map<String, Object?>.of(values)
      ..removeWhere((String key, Object? value) => value == null),
  );
}

/// Validates and returns a required non-blank string.
String requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Must not be blank.');
  }
  return value;
}

/// Validates and returns a non-empty list.
List<T> requireNonEmpty<T>(List<T> values, String name) {
  if (values.isEmpty) {
    throw ArgumentError.value(values, name, 'Must not be empty.');
  }
  return List<T>.unmodifiable(values);
}

/// Returns an enum-like value's documented Resend wire representation.
abstract interface class ResendWireValue {
  /// The value sent to Resend.
  String get value;
}
