import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a list API keys request
class ResendListApiKeysResponse {
  /// A list holding the API keys
  final List<ResendListApiKeysResponseApiKey> apiKeys;

  /// Constructor of ResendListApiKeysResponse
  const ResendListApiKeysResponse({required this.apiKeys});

  /// Factory method for creating a ResendListApiKeysResponse instance from a JSON object
  factory ResendListApiKeysResponse.fromJson(Json json) {
    return ResendListApiKeysResponse(
        apiKeys: List<Json>.from(json['data'])
            .map((j) => ResendListApiKeysResponseApiKey.fromJson(j))
            .toList());
  }
}

/// Class holding the data of an API key
class ResendListApiKeysResponseApiKey {
  /// The ID of the API key
  final String apiKeyId;

  /// The name of the API key
  final String name;

  /// The time of creation of the API key
  final DateTime createdAt;

  /// Constructor of ResendListApiKeysResponseApiKey
  const ResendListApiKeysResponseApiKey(
      {required this.apiKeyId, required this.name, required this.createdAt});

  /// Factory method for creating a ResendListApiKeysResponseApiKey instance from a JSON object
  factory ResendListApiKeysResponseApiKey.fromJson(Json json) {
    return ResendListApiKeysResponseApiKey(
        apiKeyId: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String));
  }
}
