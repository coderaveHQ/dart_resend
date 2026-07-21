import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// Resend infrastructure region used by a domain.
enum DomainRegion implements ResendWireValue {
  /// Northern Virginia, United States.
  usEast1('us-east-1'),

  /// Ireland, European Union.
  euWest1('eu-west-1'),

  /// São Paulo, Brazil.
  saEast1('sa-east-1'),

  /// Tokyo, Japan.
  apNortheast1('ap-northeast-1');

  const DomainRegion(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// TLS policy used when delivering mail from a domain.
enum DomainTls implements ResendWireValue {
  /// Prefer TLS while allowing fallback to an unencrypted connection.
  opportunistic('opportunistic'),

  /// Require TLS and fail delivery if it cannot be negotiated.
  enforced('enforced');

  const DomainTls(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// Whether a domain capability is active.
enum DomainCapabilityStatus implements ResendWireValue {
  /// The capability is active.
  enabled('enabled'),

  /// The capability is inactive.
  disabled('disabled');

  const DomainCapabilityStatus(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// A documented purpose assigned to a domain DNS record.
enum DomainRecordKind implements ResendWireValue {
  /// Sender Policy Framework record.
  spf('SPF'),

  /// DomainKeys Identified Mail record.
  dkim('DKIM'),

  /// Inbound email routing record.
  receiving('Receiving'),

  /// Click/open tracking record.
  tracking('Tracking'),

  /// Certification Authority Authorization record for tracking.
  trackingCaa('TrackingCAA');

  const DomainRecordKind(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// A documented DNS record type returned for a domain.
enum DomainDnsType implements ResendWireValue {
  /// Mail exchange record.
  mx('MX'),

  /// Text record.
  txt('TXT'),

  /// Canonical-name record.
  cname('CNAME'),

  /// Certification Authority Authorization record.
  caa('CAA');

  const DomainDnsType(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// Sending/receiving capability changes for a domain.
final class DomainCapabilitiesRequest implements ResendRequest {
  /// Creates a partial capabilities request.
  DomainCapabilitiesRequest({this.sending, this.receiving}) {
    if (sending == null && receiving == null) {
      throw ArgumentError('At least one capability must be provided.');
    }
    if (sending == DomainCapabilityStatus.disabled &&
        receiving == DomainCapabilityStatus.disabled) {
      throw ArgumentError('At least one domain capability must be enabled.');
    }
  }

  /// Sending capability update.
  final DomainCapabilityStatus? sending;

  /// Receiving capability update.
  final DomainCapabilityStatus? receiving;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'sending': sending?.value,
    'receiving': receiving?.value,
  });
}

/// Parameters for creating a sending and/or receiving domain.
final class CreateDomainRequest implements ResendRequest {
  /// Creates domain parameters.
  CreateDomainRequest({
    required String name,
    this.region,
    String? customReturnPath,
    this.openTracking,
    this.clickTracking,
    this.tls,
    this.capabilities,
    String? trackingSubdomain,
  }) : name = requireNonBlank(name, 'name'),
       customReturnPath = _optionalNonBlank(
         customReturnPath,
         'customReturnPath',
       ),
       trackingSubdomain = _optionalNonBlank(
         trackingSubdomain,
         'trackingSubdomain',
       );

  /// Domain name.
  final String name;

  /// Region in which the domain is hosted.
  final DomainRegion? region;

  /// Subdomain used for the Return-Path address.
  final String? customReturnPath;

  /// Whether open tracking is enabled.
  final bool? openTracking;

  /// Whether click tracking is enabled.
  final bool? clickTracking;

  /// TLS delivery policy.
  final DomainTls? tls;

  /// Sending and receiving capabilities.
  final DomainCapabilitiesRequest? capabilities;

  /// Subdomain used for click and open tracking.
  final String? trackingSubdomain;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'name': name,
    'region': region?.value,
    'custom_return_path': customReturnPath,
    'open_tracking': openTracking,
    'click_tracking': clickTracking,
    'tls': tls?.value,
    'capabilities': capabilities?.toJson(),
    'tracking_subdomain': trackingSubdomain,
  });
}

/// Parameters for updating a domain.
final class UpdateDomainRequest implements ResendRequest {
  /// Creates a partial domain update.
  UpdateDomainRequest({
    this.openTracking,
    this.clickTracking,
    this.tls,
    this.capabilities,
    String? trackingSubdomain,
  }) : trackingSubdomain = _optionalNonBlank(
         trackingSubdomain,
         'trackingSubdomain',
       ) {
    if (openTracking == null &&
        clickTracking == null &&
        tls == null &&
        capabilities == null &&
        trackingSubdomain == null) {
      throw ArgumentError('At least one domain update must be provided.');
    }
  }

  /// Updated open-tracking setting.
  final bool? openTracking;

  /// Updated click-tracking setting.
  final bool? clickTracking;

  /// Updated TLS policy.
  final DomainTls? tls;

  /// Updated capabilities.
  final DomainCapabilitiesRequest? capabilities;

  /// Updated tracking subdomain.
  ///
  /// Resend does not currently support removing a tracking subdomain after it
  /// is configured; it can only be replaced and re-verified.
  final String? trackingSubdomain;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'open_tracking': openTracking,
    'click_tracking': clickTracking,
    'tls': tls?.value,
    'capabilities': capabilities?.toJson(),
    'tracking_subdomain': trackingSubdomain,
  });
}

/// Parameters for claiming a domain currently owned by another Resend team.
final class ClaimDomainRequest implements ResendRequest {
  /// Creates domain-claim parameters.
  ClaimDomainRequest({
    required String name,
    this.region,
    String? customReturnPath,
    this.openTracking,
    this.clickTracking,
    String? trackingSubdomain,
  }) : name = requireNonBlank(name, 'name'),
       customReturnPath = _optionalNonBlank(
         customReturnPath,
         'customReturnPath',
       ),
       trackingSubdomain = _optionalNonBlank(
         trackingSubdomain,
         'trackingSubdomain',
       );

  /// Domain name being claimed.
  final String name;

  /// Desired hosting region after transfer.
  final DomainRegion? region;

  /// Desired Return-Path subdomain.
  final String? customReturnPath;

  /// Desired open-tracking setting.
  final bool? openTracking;

  /// Desired click-tracking setting.
  final bool? clickTracking;

  /// Desired tracking subdomain.
  final String? trackingSubdomain;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'name': name,
    'region': region?.value,
    'custom_return_path': customReturnPath,
    'open_tracking': openTracking,
    'click_tracking': clickTracking,
    'tracking_subdomain': trackingSubdomain,
  });
}

/// Sending and receiving capabilities returned for a domain.
final class DomainCapabilities extends ResendModel {
  /// Decodes domain capabilities.
  DomainCapabilities.fromJson(super.json);

  /// Raw sending status, preserved for forward compatibility.
  String get sending => field<String>('sending');

  /// Raw receiving status, preserved for forward compatibility.
  String get receiving => field<String>('receiving');
}

/// One DNS record required by a Resend domain.
final class DomainDnsRecord extends ResendModel {
  /// Decodes a domain DNS record.
  DomainDnsRecord.fromJson(super.json);

  /// Raw record purpose, including future values not known by this SDK.
  String get record => field<String>('record');

  /// Known record purpose, or `null` for a newly introduced value.
  DomainRecordKind? get knownRecord =>
      _knownWireValue(DomainRecordKind.values, record);

  /// DNS record name.
  String get name => field<String>('name');

  /// Raw DNS type, including future values not known by this SDK.
  String get type => field<String>('type');

  /// Known DNS type, or `null` for a newly introduced value.
  DomainDnsType? get knownType => _knownWireValue(DomainDnsType.values, type);

  /// DNS time-to-live setting.
  String get ttl => field<String>('ttl');

  /// Verification status, preserved as a forward-compatible string.
  String get status => field<String>('status');

  /// DNS record value.
  String get value => field<String>('value');

  /// MX priority when applicable.
  int? get priority => optionalField<int>('priority');

  /// Provider routing policy when detected.
  String? get routingPolicy => optionalField<String>('routing_policy');

  /// Provider proxy setting when detected.
  String? get proxyStatus => optionalField<String>('proxy_status');
}

/// A Resend domain returned by create, list, or retrieve operations.
final class Domain extends ResendModel {
  /// Decodes a domain.
  Domain.fromJson(super.json);

  /// Resource type; create and list responses may omit it.
  String? get object => optionalField<String>('object');

  /// Domain ID.
  String get id => field<String>('id');

  /// Domain name.
  String get name => field<String>('name');

  /// Verification status, preserved as a forward-compatible string.
  String get status => field<String>('status');

  /// When the domain was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// Hosting region, preserved as a forward-compatible string.
  String get region => field<String>('region');

  /// Sending and receiving capabilities.
  DomainCapabilities get capabilities {
    return DomainCapabilities.fromJson(objectField('capabilities'));
  }

  /// Whether open tracking is enabled, when returned.
  bool? get openTracking => optionalField<bool>('open_tracking');

  /// Whether click tracking is enabled, when returned.
  bool? get clickTracking => optionalField<bool>('click_tracking');

  /// Tracking subdomain, when configured.
  String? get trackingSubdomain => optionalField<String>('tracking_subdomain');

  /// Return-Path subdomain, when returned.
  String? get customReturnPath => optionalField<String>('custom_return_path');

  /// TLS policy, when returned.
  String? get tls => optionalField<String>('tls');

  /// DNS records. List responses omit this collection.
  List<DomainDnsRecord>? get records => _optionalModels<DomainDnsRecord>(
    this,
    'records',
    DomainDnsRecord.fromJson,
  );
}

/// TXT ownership record for a domain claim.
final class DomainClaimRecord extends ResendModel {
  /// Decodes a claim record.
  DomainClaimRecord.fromJson(super.json);

  /// DNS type, currently `TXT`.
  String get type => field<String>('type');

  /// DNS record name.
  String get name => field<String>('name');

  /// DNS record value.
  String get value => field<String>('value');

  /// DNS time to live, currently `Auto`.
  String get ttl => field<String>('ttl');
}

/// Ownership-transfer state for a domain claim.
final class DomainClaim extends ResendModel {
  /// Decodes a domain claim.
  DomainClaim.fromJson(super.json);

  /// Resource type.
  String? get object => optionalField<String>('object');

  /// Claim ID.
  String get id => field<String>('id');

  /// Domain name being claimed.
  String get name => field<String>('name');

  /// Claim state, preserved as a forward-compatible string.
  String get status => field<String>('status');

  /// Resulting domain ID after transfer, when available.
  String? get domainId => optionalField<String>('domain_id');

  /// Resulting domain region, when available.
  String? get region => optionalField<String>('region');

  /// TXT ownership-verification record.
  DomainClaimRecord get record {
    return DomainClaimRecord.fromJson(objectField('record'));
  }

  /// Why the claim is blocked, when applicable.
  String? get blockedReason => optionalField<String>('blocked_reason');

  /// Failure detail, when applicable.
  String? get failureReason => optionalField<String>('failure_reason');

  /// When the claim was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// When the claim expires.
  DateTime get expiresAt => dateTimeField('expires_at');
}

/// Operations for domains, DNS verification, and ownership claims.
final class DomainsResource {
  /// Creates a domains resource client.
  DomainsResource(this._transport);

  /// Transport used to execute domain endpoint requests.
  final ResendTransport _transport;

  /// Creates a domain.
  Future<ResendResponse<Domain>> create(CreateDomainRequest request) {
    return _transport.post<Domain>(
      pathSegments: <String>['domains'],
      body: request.toJson(),
      decode: Domain.fromJson,
    );
  }

  /// Lists domains.
  Future<ResendResponse<ResendPage<Domain>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<Domain>>(
      pathSegments: <String>['domains'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<Domain>.fromJson(json, Domain.fromJson),
    );
  }

  /// Retrieves one domain by [id].
  Future<ResendResponse<Domain>> retrieve(String id) {
    return _transport.get<Domain>(
      pathSegments: <String>['domains', requireNonBlank(id, 'id')],
      decode: Domain.fromJson,
    );
  }

  /// Updates one domain by [id].
  Future<ResendResponse<ResendId>> update(
    String id,
    UpdateDomainRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>['domains', requireNonBlank(id, 'id')],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Deletes one domain by [id].
  Future<ResendResponse<ResendDeletion>> delete(String id) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>['domains', requireNonBlank(id, 'id')],
      decode: ResendDeletion.fromJson,
    );
  }

  /// Triggers DNS verification for one domain.
  Future<ResendResponse<ResendId>> verify(String id) {
    return _transport.post<ResendId>(
      pathSegments: <String>['domains', requireNonBlank(id, 'id'), 'verify'],
      decode: ResendId.fromJson,
    );
  }

  /// Starts an ownership claim for a domain used by another Resend team.
  Future<ResendResponse<DomainClaim>> claim(ClaimDomainRequest request) {
    return _transport.post<DomainClaim>(
      pathSegments: <String>['domains', 'claim'],
      body: request.toJson(),
      decode: DomainClaim.fromJson,
    );
  }

  /// Retrieves the current ownership claim for a domain.
  Future<ResendResponse<DomainClaim>> retrieveClaim(String domainId) {
    return _transport.get<DomainClaim>(
      pathSegments: <String>[
        'domains',
        requireNonBlank(domainId, 'domainId'),
        'claim',
      ],
      decode: DomainClaim.fromJson,
    );
  }

  /// Verifies the ownership claim for a domain.
  Future<ResendResponse<DomainClaim>> verifyClaim(String domainId) {
    return _transport.post<DomainClaim>(
      pathSegments: <String>[
        'domains',
        requireNonBlank(domainId, 'domainId'),
        'claim',
        'verify',
      ],
      decode: DomainClaim.fromJson,
    );
  }
}

/// Validates [value] when present while preserving null omission semantics.
String? _optionalNonBlank(String? value, String name) {
  return value == null ? null : requireNonBlank(value, name);
}

/// Resolves [value] to a known enum while preserving forward compatibility.
T? _knownWireValue<T extends ResendWireValue>(List<T> values, String value) {
  for (final T candidate in values) {
    if (candidate.value == value) return candidate;
  }
  return null;
}

/// Decodes and freezes a required array of domain response models.
List<T> _models<T>(
  ResendModel reader,
  String key,
  T Function(JsonObject json) decode,
) {
  return List<T>.unmodifiable(
    reader.listField<Object?>(key).map((Object? value) {
      if (value is! Map<String, Object?>) {
        throw FormatException('Expected every "$key" item to be an object.');
      }
      return decode(value);
    }),
  );
}

/// Decodes an optional domain-model array while preserving absence.
List<T>? _optionalModels<T>(
  ResendModel reader,
  String key,
  T Function(JsonObject json) decode,
) {
  return reader.json[key] == null ? null : _models<T>(reader, key, decode);
}
