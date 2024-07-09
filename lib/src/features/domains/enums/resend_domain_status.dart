/// The status of the domain
enum ResendDomainStatus {
  /// not started
  notStarted('not-started'),

  /// pending
  pending('pending'),

  /// verified
  verified('verified'),

  /// failure
  failure('failure'),

  /// temporary failure
  temporaryFailure('temporary_failure');

  /// The ID of the status
  final String id;

  /// Constructor of ResendDomainStatus
  const ResendDomainStatus(this.id);

  /// Method for returning a domain status based on a provided value
  static ResendDomainStatus fromValue(String value) {
    return ResendDomainStatus.values.firstWhere((s) => s.id == value);
  }
}
