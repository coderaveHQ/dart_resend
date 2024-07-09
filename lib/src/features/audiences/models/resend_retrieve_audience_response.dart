import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a retrieve audience request
class ResendRetrieveAudienceResponse {
  /// The ID of the audience
  final String id;

  /// The name of the audience
  final String name;

  /// The time of creation of the audience
  final DateTime createdAt;

  /// Constructor of ResendRetrieveAudienceResponse
  const ResendRetrieveAudienceResponse(
      {required this.id, required this.name, required this.createdAt});

  /// Factory method for creating a ResendRetrieveAudienceResponse instance from a JSON object
  factory ResendRetrieveAudienceResponse.fromJson(Json json) {
    return ResendRetrieveAudienceResponse(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String));
  }
}
