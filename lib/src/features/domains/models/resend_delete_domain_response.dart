import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a delete domain request
class ResendDeleteDomainResponse {
  /// The ID of the deleted domain
  final String domainId;

  /// Indicator if the domain got deleted
  final bool deleted;

  /// Constructor of ResendDeleteDomainResponse
  const ResendDeleteDomainResponse(
      {required this.domainId, required this.deleted});

  /// Factory method for creating a ResendDeleteDomainResponse instance from a JSON object
  factory ResendDeleteDomainResponse.fromJson(Json json) {
    return ResendDeleteDomainResponse(
        domainId: json['id'] as String, deleted: json['deleted'] as bool);
  }
}
