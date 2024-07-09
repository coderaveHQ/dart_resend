import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a delete audience request
class ResendDeleteAudienceResponse {
  /// The ID of the deleted audience
  final String id;

  /// Indicator if the audience got deleted
  final bool deleted;

  /// Constructor of ResendDeleteAudienceResponse
  const ResendDeleteAudienceResponse({required this.id, required this.deleted});

  /// Factory method for creating a ResendDeleteAudienceResponse instance from a JSON object
  factory ResendDeleteAudienceResponse.fromJson(Json json) {
    return ResendDeleteAudienceResponse(
        id: json['id'] as String, deleted: json['deleted'] as bool);
  }
}
