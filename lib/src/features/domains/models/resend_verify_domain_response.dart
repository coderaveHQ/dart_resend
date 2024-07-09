import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a verify domain request
class ResendVerifyDomainResponse {
  /// The ID of the domain
  final String domainId;

  /// Constructor of ResendVerifyDomainResponse
  const ResendVerifyDomainResponse({required this.domainId});

  /// Factory method for creating a ResendVerifyDomainResponse instance from a JSON object
  factory ResendVerifyDomainResponse.fromJson(Json json) {
    return ResendVerifyDomainResponse(domainId: json['id'] as String);
  }
}
