/// The region of the domain
enum ResendDomainRegion {
  /// US-East-1
  usEast1('us-east-1'),

  /// EU-West-1
  euWest1('eu-west-1'),

  /// SA-East-1
  saEast1('sa-east-1'),

  /// AP-North-East-1
  apNortheast1('ap-northeast-1');

  /// The ID of the region
  final String id;

  /// Constructor of ResendDomainRegion
  const ResendDomainRegion(this.id);

  /// Method for returning a domain region based on a provided value
  static ResendDomainRegion fromValue(String value) {
    return ResendDomainRegion.values.firstWhere((r) => r.id == value);
  }
}
