import 'package:dart_resend/src/features/domains/enums/resend_domain_status.dart';
import 'package:dart_resend/src/utils/typedefs.dart';

/// A class holding information about a domain record
class ResendDomainRecord {
  /// The ID of the record
  final String record;

  /// The name of the record
  final String name;

  /// The type of the record
  final String type;

  /// The ttl of the record
  final String ttl;

  /// The status of the record
  final ResendDomainStatus status;

  /// The value of the record
  final String value;

  /// The priority of the record
  final int? priority;

  /// Constructor of ResendDomainRecord
  const ResendDomainRecord(
      {required this.record,
      required this.name,
      required this.type,
      required this.ttl,
      required this.status,
      required this.value,
      this.priority});

  /// Factory method for creating a ResendDomainRecord instance from a JSON object
  factory ResendDomainRecord.fromJson(Json json) {
    return ResendDomainRecord(
        record: json['record'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        ttl: json['ttl'] as String,
        status: ResendDomainStatus.fromValue(json['status'] as String),
        value: json['value'] as String,
        priority: json['priority'] as int?);
  }
}
