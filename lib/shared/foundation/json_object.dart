import 'dart:convert';

/// Validates an untrusted JSON object before domain deserialization.
Map<String, Object?> jsonObject(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('Expected a JSON object with string keys.');
  }
  return value;
}

/// Keeps the JSON decoder's dynamic return type at this boundary.
Map<String, Object?> decodeJsonObject(String source) =>
    jsonObject(jsonDecode(source));

/// Reads an optional, typed JSON field; malformed values fail in release too.
T? optionalJsonValue<T extends Object>(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! T) {
    throw FormatException('Invalid JSON field: $key.');
  }
  return value;
}
