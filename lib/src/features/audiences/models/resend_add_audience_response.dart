import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a add audience request
class ResendAddAudienceResponse {
  /// The id of the created audience
  final String audienceId;

  /// The name of the created audience
  final String name;

  /// Constructor of ResendAddAudienceResponse
  const ResendAddAudienceResponse(
      {required this.audienceId, required this.name});

  /// Factory method for creating a ResendAddAudienceResponse instance from a JSON object
  factory ResendAddAudienceResponse.fromJson(Json json) {
    return ResendAddAudienceResponse(
        audienceId: json['id'] as String, name: json['name'] as String);
  }
}
