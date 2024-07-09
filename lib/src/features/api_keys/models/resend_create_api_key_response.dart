import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a create API key request
class ResendCreateApiKeyResponse {
  /// The id of the created API key
  final String apiKeyId;

  /// The token of the created API key
  final String token;

  /// Constructor of ResendCreateApiKeyResponse
  const ResendCreateApiKeyResponse(
      {required this.apiKeyId, required this.token});

  /// Factory method for creating a ResendCreateApiKeyResponse instance from a JSON object
  factory ResendCreateApiKeyResponse.fromJson(Json json) {
    return ResendCreateApiKeyResponse(
        apiKeyId: json['id'] as String, token: json['token'] as String);
  }
}
