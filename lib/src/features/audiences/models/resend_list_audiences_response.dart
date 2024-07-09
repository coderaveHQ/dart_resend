import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a list audiences request
class ResendListAudiencesResponse {
  /// A list holding the audiences
  final List<ResendListAudiencesResponseAudience> audiences;

  /// Constructor of ResendListAudiencesResponse
  const ResendListAudiencesResponse({required this.audiences});

  /// Factory method for creating a ResendListAudiencesResponse instance from a JSON object
  factory ResendListAudiencesResponse.fromJson(Json json) {
    return ResendListAudiencesResponse(
        audiences: List<Json>.from(json['data'])
            .map((j) => ResendListAudiencesResponseAudience.fromJson(j))
            .toList());
  }
}

/// Class holding the data of an audience
class ResendListAudiencesResponseAudience {
  /// The ID of the audience
  final String id;

  /// The name of the audience
  final String name;

  /// The time of creation of the audience
  final DateTime createdAt;

  /// Constructor of ResendListAudiencesResponseAudience
  const ResendListAudiencesResponseAudience(
      {required this.id, required this.name, required this.createdAt});

  /// Factory method for creating a ResendListAudiencesResponseAudience instance from a JSON object
  factory ResendListAudiencesResponseAudience.fromJson(Json json) {
    return ResendListAudiencesResponseAudience(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String));
  }
}
