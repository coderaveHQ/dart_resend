/// The TLS of the domain
enum ResendDomainTls {
  /// opportunistic
  opportunistic('opportunistic'),

  /// enforced
  enforced('enforced');

  /// The ID of the TLS
  final String id;

  /// Constructor of ResendDomainTls
  const ResendDomainTls(this.id);

  /// Method for returning a domain TLS based on a provided value
  static ResendDomainTls fromValue(String value) {
    return ResendDomainTls.values.firstWhere((t) => t.id == value);
  }
}
