/// A JSON object with string keys and JSON-compatible values.
typedef JsonMap = Map<String, Object?>;

/// Returns a deeply immutable copy of [source].
///
/// Nested maps and lists are copied before being wrapped in unmodifiable
/// views. Values that cannot be represented in JSON cause an [ArgumentError].
JsonMap immutableJsonMap(JsonMap source) {
  return Map<String, Object?>.unmodifiable(
    source.map(
      (String key, Object? value) =>
          MapEntry<String, Object?>(key, immutableJsonValue(value)),
    ),
  );
}

/// Returns a deeply immutable copy of one JSON-compatible [value].
Object? immutableJsonValue(Object? value) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be finite');
    }
    return value;
  }
  if (value is Map<Object?, Object?>) {
    final JsonMap result = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      final Object? key = entry.key;
      if (key is! String) {
        throw ArgumentError.value(key, 'key', 'must be a string');
      }
      result[key] = immutableJsonValue(entry.value);
    }
    return Map<String, Object?>.unmodifiable(result);
  }
  if (value is List<Object?>) {
    return List<Object?>.unmodifiable(value.map(immutableJsonValue));
  }
  throw ArgumentError.value(value, 'value', 'must be a JSON-compatible value');
}

/// Typed, context-rich readers for values in a [JsonMap].
extension JsonMapReader on JsonMap {
  /// Reads a required string at [key].
  String requiredString(String key) => _requiredType<String>(key, 'a string');

  /// Reads an optional string at [key].
  String? optionalString(String key) => _optionalType<String>(key, 'a string');

  /// Reads a required integer at [key].
  int requiredInt(String key) => _requiredType<int>(key, 'an integer');

  /// Reads an optional integer at [key].
  int? optionalInt(String key) => _optionalType<int>(key, 'an integer');

  /// Reads a required number at [key].
  num requiredNum(String key) => _requiredType<num>(key, 'a number');

  /// Reads an optional number at [key].
  num? optionalNum(String key) => _optionalType<num>(key, 'a number');

  /// Reads a required boolean at [key].
  bool requiredBool(String key) => _requiredType<bool>(key, 'a boolean');

  /// Reads an optional boolean at [key].
  bool? optionalBool(String key) => _optionalType<bool>(key, 'a boolean');

  /// Reads a required, deeply immutable object at [key].
  JsonMap requiredMap(String key) {
    final Object value = _requiredValue(key);
    if (value is! Map<Object?, Object?>) {
      throw _wrongType(key, 'an object', value);
    }
    return _asJsonMap(key, value);
  }

  /// Reads an optional, deeply immutable object at [key].
  JsonMap? optionalMap(String key) {
    final Object? value = this[key];
    if (value == null) {
      return null;
    }
    if (value is! Map<Object?, Object?>) {
      throw _wrongType(key, 'an object', value);
    }
    return _asJsonMap(key, value);
  }

  /// Reads a required, deeply immutable array at [key].
  List<Object?> requiredList(String key) {
    final Object value = _requiredValue(key);
    if (value is! List<Object?>) {
      throw _wrongType(key, 'an array', value);
    }
    return List<Object?>.unmodifiable(value.map(immutableJsonValue));
  }

  /// Reads an optional, deeply immutable array at [key].
  List<Object?>? optionalList(String key) {
    final Object? value = this[key];
    if (value == null) {
      return null;
    }
    if (value is! List<Object?>) {
      throw _wrongType(key, 'an array', value);
    }
    return List<Object?>.unmodifiable(value.map(immutableJsonValue));
  }

  /// Reads a required array of strings at [key].
  List<String> requiredStringList(String key) {
    return _stringList(key, requiredList(key));
  }

  /// Reads an optional array of strings at [key].
  List<String>? optionalStringList(String key) {
    final List<Object?>? values = optionalList(key);
    return values == null ? null : _stringList(key, values);
  }

  /// Reads a required ISO-8601 timestamp at [key].
  DateTime requiredDateTime(String key) {
    return _parseDateTime(key, requiredString(key));
  }

  /// Reads an optional ISO-8601 timestamp at [key].
  DateTime? optionalDateTime(String key) {
    final String? value = optionalString(key);
    return value == null ? null : _parseDateTime(key, value);
  }

  Object _requiredValue(String key) {
    if (!containsKey(key)) {
      throw FormatException('Missing required JSON field "$key".');
    }
    final Object? value = this[key];
    if (value == null) {
      throw FormatException('JSON field "$key" must not be null.');
    }
    return value;
  }

  T _requiredType<T>(String key, String expected) {
    final Object value = _requiredValue(key);
    if (value is! T) {
      throw _wrongType(key, expected, value);
    }
    return value as T;
  }

  T? _optionalType<T>(String key, String expected) {
    final Object? value = this[key];
    if (value == null) {
      return null;
    }
    if (value is! T) {
      throw _wrongType(key, expected, value);
    }
    return value as T;
  }
}

JsonMap _asJsonMap(String key, Map<Object?, Object?> value) {
  final JsonMap result = <String, Object?>{};
  for (final MapEntry<Object?, Object?> entry in value.entries) {
    final Object? nestedKey = entry.key;
    if (nestedKey is! String) {
      throw FormatException(
        'JSON field "$key" contains a non-string object key.',
      );
    }
    result[nestedKey] = entry.value;
  }
  return immutableJsonMap(result);
}

List<String> _stringList(String key, List<Object?> values) {
  final List<String> result = <String>[];
  for (var index = 0; index < values.length; index++) {
    final Object? value = values[index];
    if (value is! String) {
      throw FormatException(
        'JSON field "$key[$index]" must be a string, '
        'but was ${_typeName(value)}.',
      );
    }
    result.add(value);
  }
  return List<String>.unmodifiable(result);
}

DateTime _parseDateTime(String key, String value) {
  final DateTime? result = DateTime.tryParse(value);
  if (result == null) {
    throw FormatException(
      'JSON field "$key" must be an ISO-8601 timestamp, but was "$value".',
    );
  }
  return result;
}

FormatException _wrongType(String key, String expected, Object? actual) {
  return FormatException(
    'JSON field "$key" must be $expected, but was ${_typeName(actual)}.',
  );
}

String _typeName(Object? value) =>
    value == null ? 'null' : value.runtimeType.toString();
