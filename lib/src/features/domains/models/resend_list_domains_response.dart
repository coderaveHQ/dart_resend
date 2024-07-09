import 'package:dart_resend/src/features/domains/enums/resend_domain_region.dart';
import 'package:dart_resend/src/features/domains/enums/resend_domain_status.dart';
import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a list domains request
class ResendListDomainsResponse {
  /// A list holding the domains
  final List<ResendListDomainsResponseDomain> domains;

  /// Constructor of ResendListDomainsResponse
  const ResendListDomainsResponse({required this.domains});

  /// Factory method for creating a ResendListDomainsResponse instance from a JSON object
  factory ResendListDomainsResponse.fromJson(Json json) {
    return ResendListDomainsResponse(
        domains: List<Json>.from(json['data'])
            .map((j) => ResendListDomainsResponseDomain.fromJson(j))
            .toList());
  }
}

/// Class holding the data of a domain
class ResendListDomainsResponseDomain {
  /// The ID of the domain
  final String domainId;

  /// The name of the domain
  final String name;

  /// The status of the domain
  final ResendDomainStatus status;

  /// The time of creation of the domain
  final DateTime createdAt;

  /// The region of the domain
  final ResendDomainRegion region;

  /// Constructor of ResendListDomainsResponseDomain
  const ResendListDomainsResponseDomain(
      {required this.domainId,
      required this.name,
      required this.status,
      required this.createdAt,
      required this.region});

  /// Factory method for creating a ResendListDomainsResponseDomain instance from a JSON object
  factory ResendListDomainsResponseDomain.fromJson(Json json) {
    return ResendListDomainsResponseDomain(
        domainId: json['id'] as String,
        name: json['name'] as String,
        status: ResendDomainStatus.fromValue(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        region: ResendDomainRegion.fromValue(json['region'] as String));
  }
}
