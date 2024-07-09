import 'package:dart_resend/src/features/domains/enums/resend_domain_status.dart';
import 'package:dart_resend/src/features/domains/models/resend_domain_record.dart';
import 'package:dart_resend/src/utils/typedefs.dart';

/// Response of a add domain request
class ResendAddDomainResponse {
  /// The ID of the domain
  final String domainId;

  /// The name of the domain
  final String name;

  /// The time of creation of the domain
  final DateTime createdAt;

  /// The status of the domain
  final ResendDomainStatus status;

  /// The records of the domain
  final List<ResendDomainRecord> records;

  /// Constructor of ResendAddContactResponse
  const ResendAddDomainResponse(
      {required this.domainId,
      required this.name,
      required this.createdAt,
      required this.status,
      required this.records});

  /// Factory method for creating a ResendAddDomainResponse instance from a JSON object
  factory ResendAddDomainResponse.fromJson(Json json) {
    return ResendAddDomainResponse(
        domainId: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        status: ResendDomainStatus.fromValue(json['status'] as String),
        records: List<Json>.from(json['records'])
            .map((j) => ResendDomainRecord.fromJson(j))
            .toList());
  }
}
