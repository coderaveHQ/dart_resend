import 'dart:convert';

import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/core/transport.dart';
import 'package:dart_resend/src/models/base.dart';
import 'package:dart_resend/src/resources/domains.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Registers this file's test cases with the package:test runner.
void main() {
  // Covers: domain requests.
  group('domain requests', () {
    // Verifies: wire enums expose every documented value.
    test('wire enums expose every documented value', () {
      expect(
        DomainRegion.values.map((DomainRegion value) => value.value).toList(),
        <String>['us-east-1', 'eu-west-1', 'sa-east-1', 'ap-northeast-1'],
      );
      expect(
        DomainTls.values.map((DomainTls value) => value.value).toList(),
        <String>['opportunistic', 'enforced'],
      );
      expect(
        DomainCapabilityStatus.values
            .map((DomainCapabilityStatus value) => value.value)
            .toList(),
        <String>['enabled', 'disabled'],
      );
      expect(
        DomainRecordKind.values
            .map((DomainRecordKind value) => value.value)
            .toList(),
        <String>['SPF', 'DKIM', 'Receiving', 'Tracking', 'TrackingCAA'],
      );
      expect(
        DomainDnsType.values.map((DomainDnsType value) => value.value).toList(),
        <String>['MX', 'TXT', 'CNAME', 'CAA'],
      );
    });

    // Verifies: capabilities support partial changes and prevent disabling
    // both.
    test('capabilities support partial changes and prevent disabling both', () {
      final DomainCapabilitiesRequest partial = DomainCapabilitiesRequest(
        sending: DomainCapabilityStatus.enabled,
      );
      expect(partial.sending, DomainCapabilityStatus.enabled);
      expect(partial.receiving, isNull);
      expect(partial.toJson(), <String, Object?>{'sending': 'enabled'});

      final DomainCapabilitiesRequest complete = DomainCapabilitiesRequest(
        sending: DomainCapabilityStatus.disabled,
        receiving: DomainCapabilityStatus.enabled,
      );
      expect(complete.toJson(), <String, Object?>{
        'sending': 'disabled',
        'receiving': 'enabled',
      });
      expect(() => DomainCapabilitiesRequest(), throwsArgumentError);
      expect(
        () => DomainCapabilitiesRequest(
          sending: DomainCapabilityStatus.disabled,
          receiving: DomainCapabilityStatus.disabled,
        ),
        throwsArgumentError,
      );
    });

    // Verifies: create domain serializes all current options.
    test('create domain serializes all current options', () {
      final CreateDomainRequest request = CreateDomainRequest(
        name: 'mail.example.com',
        region: DomainRegion.apNortheast1,
        customReturnPath: 'return',
        openTracking: true,
        clickTracking: false,
        tls: DomainTls.enforced,
        capabilities: DomainCapabilitiesRequest(
          sending: DomainCapabilityStatus.enabled,
          receiving: DomainCapabilityStatus.enabled,
        ),
        trackingSubdomain: 'clicks',
      );
      expect(request.name, 'mail.example.com');
      expect(request.region, DomainRegion.apNortheast1);
      expect(request.customReturnPath, 'return');
      expect(request.openTracking, isTrue);
      expect(request.clickTracking, isFalse);
      expect(request.tls, DomainTls.enforced);
      expect(request.capabilities, isNotNull);
      expect(request.trackingSubdomain, 'clicks');
      expect(request.toJson(), <String, Object?>{
        'name': 'mail.example.com',
        'region': 'ap-northeast-1',
        'custom_return_path': 'return',
        'open_tracking': true,
        'click_tracking': false,
        'tls': 'enforced',
        'capabilities': <String, Object?>{
          'sending': 'enabled',
          'receiving': 'enabled',
        },
        'tracking_subdomain': 'clicks',
      });
      expect(
        CreateDomainRequest(name: 'example.com').toJson(),
        <String, Object?>{'name': 'example.com'},
      );
    });

    // Verifies: create domain validates all strings.
    test('create domain validates all strings', () {
      expect(() => CreateDomainRequest(name: ' '), throwsArgumentError);
      expect(
        () => CreateDomainRequest(name: 'example.com', customReturnPath: ' '),
        throwsArgumentError,
      );
      expect(
        () => CreateDomainRequest(name: 'example.com', trackingSubdomain: ' '),
        throwsArgumentError,
      );
    });

    // Verifies: update domain requires and serializes at least one change.
    test('update domain requires and serializes at least one change', () {
      final UpdateDomainRequest request = UpdateDomainRequest(
        openTracking: false,
        clickTracking: true,
        tls: DomainTls.opportunistic,
        capabilities: DomainCapabilitiesRequest(
          receiving: DomainCapabilityStatus.enabled,
        ),
        trackingSubdomain: 'track',
      );
      expect(request.openTracking, isFalse);
      expect(request.clickTracking, isTrue);
      expect(request.tls, DomainTls.opportunistic);
      expect(request.capabilities, isNotNull);
      expect(request.trackingSubdomain, 'track');
      expect(request.toJson(), <String, Object?>{
        'open_tracking': false,
        'click_tracking': true,
        'tls': 'opportunistic',
        'capabilities': <String, Object?>{'receiving': 'enabled'},
        'tracking_subdomain': 'track',
      });
      expect(() => UpdateDomainRequest(), throwsArgumentError);
      expect(
        () => UpdateDomainRequest(trackingSubdomain: ' '),
        throwsArgumentError,
      );
    });

    // Verifies: claim domain serializes transfer configuration.
    test('claim domain serializes transfer configuration', () {
      final ClaimDomainRequest request = ClaimDomainRequest(
        name: 'claimed.example.com',
        region: DomainRegion.euWest1,
        customReturnPath: 'bounce',
        openTracking: true,
        clickTracking: false,
        trackingSubdomain: 'links',
      );
      expect(request.name, 'claimed.example.com');
      expect(request.region, DomainRegion.euWest1);
      expect(request.customReturnPath, 'bounce');
      expect(request.openTracking, isTrue);
      expect(request.clickTracking, isFalse);
      expect(request.trackingSubdomain, 'links');
      expect(request.toJson(), <String, Object?>{
        'name': 'claimed.example.com',
        'region': 'eu-west-1',
        'custom_return_path': 'bounce',
        'open_tracking': true,
        'click_tracking': false,
        'tracking_subdomain': 'links',
      });
      expect(
        ClaimDomainRequest(name: 'minimal.example.com').toJson(),
        <String, Object?>{'name': 'minimal.example.com'},
      );
      expect(() => ClaimDomainRequest(name: ' '), throwsArgumentError);
      expect(
        () => ClaimDomainRequest(name: 'example.com', customReturnPath: ' '),
        throwsArgumentError,
      );
      expect(
        () => ClaimDomainRequest(name: 'example.com', trackingSubdomain: ' '),
        throwsArgumentError,
      );
    });
  });

  // Covers: domain models.
  group('domain models', () {
    // Verifies: domain exposes capabilities and every DNS record field.
    test('domain exposes capabilities and every DNS record field', () {
      final Domain domain = Domain.fromJson(_domainJson());
      expect(domain.object, 'domain');
      expect(domain.id, 'domain_1');
      expect(domain.name, 'example.com');
      expect(domain.status, 'partially_verified');
      expect(domain.createdAt, DateTime.parse('2026-07-20T08:00:00Z'));
      expect(domain.region, 'ap-northeast-1');
      expect(domain.capabilities.sending, 'enabled');
      expect(domain.capabilities.receiving, 'enabled');
      expect(domain.openTracking, isTrue);
      expect(domain.clickTracking, isFalse);
      expect(domain.trackingSubdomain, 'links');
      expect(domain.customReturnPath, 'return');
      expect(domain.tls, 'enforced');

      final DomainDnsRecord trackingCaa = domain.records!.first;
      expect(trackingCaa.record, 'TrackingCAA');
      expect(trackingCaa.knownRecord, DomainRecordKind.trackingCaa);
      expect(trackingCaa.name, 'links.example.com');
      expect(trackingCaa.type, 'CAA');
      expect(trackingCaa.knownType, DomainDnsType.caa);
      expect(trackingCaa.ttl, 'Auto');
      expect(trackingCaa.status, 'verified');
      expect(trackingCaa.value, '0 issue "letsencrypt.org"');
      expect(trackingCaa.priority, 10);
      expect(trackingCaa.routingPolicy, 'simple');
      expect(trackingCaa.proxyStatus, 'disable');

      final DomainDnsRecord future = domain.records!.last;
      expect(future.knownRecord, isNull);
      expect(future.knownType, isNull);
      expect(future.priority, isNull);
      expect(future.routingPolicy, isNull);
      expect(future.proxyStatus, isNull);
      expect(domain.json['new_domain_field'], 'preserved');
    });

    // Verifies: list domain may omit retrieve-only fields.
    test('list domain may omit retrieve-only fields', () {
      final Domain domain = Domain.fromJson(
        _domainJson(includeOptional: false),
      );
      expect(domain.object, isNull);
      expect(domain.openTracking, isNull);
      expect(domain.clickTracking, isNull);
      expect(domain.trackingSubdomain, isNull);
      expect(domain.customReturnPath, isNull);
      expect(domain.tls, isNull);
      expect(domain.records, isNull);
    });

    // Verifies: domain claims expose verification and blocking state.
    test('domain claims expose verification and blocking state', () {
      final DomainClaim claim = DomainClaim.fromJson(_claimJson());
      expect(claim.object, 'domain_claim');
      expect(claim.id, 'claim_1');
      expect(claim.name, 'claimed.example.com');
      expect(claim.status, 'blocked');
      expect(claim.domainId, 'domain_1');
      expect(claim.region, 'eu-west-1');
      expect(claim.record.type, 'TXT');
      expect(claim.record.name, '_resend.claimed.example.com');
      expect(claim.record.value, 'resend-domain-verification=token');
      expect(claim.record.ttl, 'Auto');
      expect(claim.blockedReason, 'grace_period');
      expect(claim.failureReason, 'Waiting for transfer');
      expect(claim.createdAt, DateTime.parse('2026-07-20T08:00:00Z'));
      expect(claim.expiresAt, DateTime.parse('2026-07-27T08:00:00Z'));

      final DomainClaim pending = DomainClaim.fromJson(<String, Object?>{
        ..._claimJson(),
        'object': null,
        'domain_id': null,
        'region': null,
        'blocked_reason': null,
        'failure_reason': null,
      });
      expect(pending.object, isNull);
      expect(pending.domainId, isNull);
      expect(pending.region, isNull);
      expect(pending.blockedReason, isNull);
      expect(pending.failureReason, isNull);
    });

    // Verifies: invalid record arrays fail with context.
    test('invalid record arrays fail with context', () {
      final Domain domain = Domain.fromJson(<String, Object?>{
        ..._domainJson(includeOptional: false),
        'records': <Object?>[1],
      });
      expect(() => domain.records, throwsFormatException);
    });
  });

  // Covers: DomainsResource.
  group('DomainsResource', () {
    // Verifies: calls CRUD, verification, and claim endpoints.
    test('calls CRUD, verification, and claim endpoints', () async {
      final List<String> calls = <String>[];
      final DomainsResource domains = _domainsResource((
        http.Request request,
      ) async {
        calls.add('${request.method} ${request.url}');
        final String path = request.url.path;
        if (request.method == 'POST' && path == '/domains') {
          expect(jsonDecode(request.body), <String, Object?>{
            'name': 'example.com',
          });
          return _jsonResponse(_domainJson());
        }
        if (request.method == 'GET' && path == '/domains') {
          expect(request.url.queryParameters, <String, String>{
            'limit': '1',
            'before': 'domain_2',
          });
          return _jsonResponse(<String, Object?>{
            'object': 'list',
            'has_more': false,
            'data': <Object?>[_domainJson(includeOptional: false)],
          });
        }
        if (request.method == 'GET' && path == '/domains/domain_1') {
          return _jsonResponse(_domainJson());
        }
        if (request.method == 'PATCH' && path == '/domains/domain_1') {
          expect(jsonDecode(request.body), <String, Object?>{
            'open_tracking': false,
          });
          return _jsonResponse(<String, Object?>{
            'object': 'domain',
            'id': 'domain_1',
          });
        }
        if (request.method == 'DELETE' && path == '/domains/domain_1') {
          return _jsonResponse(<String, Object?>{
            'object': 'domain',
            'id': 'domain_1',
            'deleted': true,
          });
        }
        if (request.method == 'POST' && path == '/domains/domain_1/verify') {
          return _jsonResponse(<String, Object?>{
            'object': 'domain',
            'id': 'domain_1',
          });
        }
        if (request.method == 'POST' && path == '/domains/claim') {
          expect(jsonDecode(request.body), <String, Object?>{
            'name': 'claimed.example.com',
          });
          return _jsonResponse(_claimJson());
        }
        if (request.method == 'GET' && path == '/domains/domain_1/claim') {
          return _jsonResponse(_claimJson());
        }
        if (request.method == 'POST' &&
            path == '/domains/domain_1/claim/verify') {
          return _jsonResponse(<String, Object?>{
            ..._claimJson(),
            'status': 'verified',
          });
        }
        return http.Response('not found', 404);
      });

      expect(
        (await domains.create(
          CreateDomainRequest(name: 'example.com'),
        )).data.id,
        'domain_1',
      );
      expect(
        (await domains.list(
          pagination: PaginationOptions(limit: 1, before: 'domain_2'),
        )).data.data.single.id,
        'domain_1',
      );
      expect((await domains.retrieve('domain_1')).data.id, 'domain_1');
      expect(
        (await domains.update(
          'domain_1',
          UpdateDomainRequest(openTracking: false),
        )).data.id,
        'domain_1',
      );
      expect((await domains.delete('domain_1')).data.deleted, isTrue);
      expect((await domains.verify('domain_1')).data.object, 'domain');
      expect(
        (await domains.claim(
          ClaimDomainRequest(name: 'claimed.example.com'),
        )).data.id,
        'claim_1',
      );
      expect((await domains.retrieveClaim('domain_1')).data.id, 'claim_1');
      expect((await domains.verifyClaim('domain_1')).data.status, 'verified');
      expect(calls, hasLength(9));
    });
  });
}

/// Creates a domain resource whose transport delegates to [handler].
DomainsResource _domainsResource(
  Future<http.Response> Function(http.Request request) handler,
) {
  return DomainsResource(
    ResendTransport(
      apiKey: 're_test',
      client: MockClient(handler),
      baseUri: Uri.parse('https://api.example.test'),
    ),
  );
}

/// Encodes [json] as a successful domain endpoint response.
http.Response _jsonResponse(JsonObject json) {
  return http.Response(
    jsonEncode(json),
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

/// Builds a domain fixture with optionally omitted retrieve-only fields.
JsonObject _domainJson({bool includeOptional = true}) {
  return <String, Object?>{
    if (includeOptional) 'object': 'domain',
    'id': 'domain_1',
    'name': 'example.com',
    'status': 'partially_verified',
    'created_at': '2026-07-20T08:00:00Z',
    'region': 'ap-northeast-1',
    'capabilities': <String, Object?>{
      'sending': 'enabled',
      'receiving': 'enabled',
    },
    if (includeOptional) ...<String, Object?>{
      'open_tracking': true,
      'click_tracking': false,
      'tracking_subdomain': 'links',
      'custom_return_path': 'return',
      'tls': 'enforced',
      'records': <Object?>[
        <String, Object?>{
          'record': 'TrackingCAA',
          'name': 'links.example.com',
          'type': 'CAA',
          'ttl': 'Auto',
          'status': 'verified',
          'value': '0 issue "letsencrypt.org"',
          'priority': 10,
          'routing_policy': 'simple',
          'proxy_status': 'disable',
        },
        <String, Object?>{
          'record': 'FutureRecord',
          'name': 'future.example.com',
          'type': 'HTTPS',
          'ttl': '300',
          'status': 'pending',
          'value': 'future',
        },
      ],
      'new_domain_field': 'preserved',
    },
  };
}

/// Builds a complete domain-claim response fixture.
JsonObject _claimJson() {
  return <String, Object?>{
    'object': 'domain_claim',
    'id': 'claim_1',
    'name': 'claimed.example.com',
    'status': 'blocked',
    'domain_id': 'domain_1',
    'region': 'eu-west-1',
    'record': <String, Object?>{
      'type': 'TXT',
      'name': '_resend.claimed.example.com',
      'value': 'resend-domain-verification=token',
      'ttl': 'Auto',
    },
    'blocked_reason': 'grace_period',
    'failure_reason': 'Waiting for transfer',
    'created_at': '2026-07-20T08:00:00Z',
    'expires_at': '2026-07-27T08:00:00Z',
  };
}
