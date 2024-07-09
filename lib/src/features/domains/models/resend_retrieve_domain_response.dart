import 'package:dart_resend/src/features/domains/enums/resend_domain_region.dart';
import 'package:dart_resend/src/features/domains/enums/resend_domain_status.dart';
import 'package:dart_resend/src/features/domains/models/resend_domain_record.dart';
import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a retrieve domain request
class ResendRetrieveDomainResponse {
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

  /// The records of the domain
  final List<ResendDomainRecord> records;

  /// Constructor of ResendRetrieveDomainResponse
  const ResendRetrieveDomainResponse(
      {required this.domainId,
      required this.name,
      required this.status,
      required this.createdAt,
      required this.region,
      required this.records});

  /// Factory method for creating a ResendRetrieveDomainResponse instance from a JSON object
  factory ResendRetrieveDomainResponse.fromJson(Json json) {
    return ResendRetrieveDomainResponse(
        domainId: json['id'] as String,
        name: json['name'] as String,
        status: ResendDomainStatus.fromValue(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        region: ResendDomainRegion.fromValue(json['region']),
        records: List<Json>.from(json['records'])
            .map((j) => ResendDomainRecord.fromJson(j))
            .toList());
  }
}
