import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of an update domain request
class ResendUpdateDomainResponse {
  /// The ID of the domain
  final String domainId;

  /// Constructor of ResendUpdateDomainResponse
  const ResendUpdateDomainResponse({required this.domainId});

  /// Factory method for creating a ResendUpdateDomainResponse instance from a JSON object
  factory ResendUpdateDomainResponse.fromJson(Json json) {
    return ResendUpdateDomainResponse(domainId: json['id'] as String);
  }
}
