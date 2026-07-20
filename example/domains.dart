import 'package:dart_resend/dart_resend.dart';

/// Creates a domain with sending and receiving enabled.
Future<ResendResponse<Domain>> createDomain(Resend resend) {
  return resend.domains.create(
    CreateDomainRequest(
      name: 'mail.example.com',
      region: DomainRegion.euWest1,
      customReturnPath: 'bounce',
      openTracking: true,
      clickTracking: true,
      tls: DomainTls.enforced,
      capabilities: DomainCapabilitiesRequest(
        sending: DomainCapabilityStatus.enabled,
        receiving: DomainCapabilityStatus.enabled,
      ),
      trackingSubdomain: 'links',
    ),
  );
}

/// Lists domains with cursor pagination.
Future<ResendResponse<ResendPage<Domain>>> listDomains(Resend resend) {
  return resend.domains.list(pagination: PaginationOptions(limit: 20));
}

/// Retrieves a domain and its required DNS records.
Future<ResendResponse<Domain>> retrieveDomain(Resend resend, String domainId) {
  return resend.domains.retrieve(domainId);
}

/// Updates domain tracking, TLS, and sending/receiving capabilities.
Future<ResendResponse<ResendId>> updateDomain(Resend resend, String domainId) {
  return resend.domains.update(
    domainId,
    UpdateDomainRequest(
      openTracking: false,
      clickTracking: true,
      tls: DomainTls.opportunistic,
      capabilities: DomainCapabilitiesRequest(
        sending: DomainCapabilityStatus.enabled,
        receiving: DomainCapabilityStatus.disabled,
      ),
      trackingSubdomain: 'email',
    ),
  );
}

/// Asks Resend to verify a domain's DNS records.
Future<ResendResponse<ResendId>> verifyDomain(Resend resend, String domainId) {
  return resend.domains.verify(domainId);
}

/// Deletes a domain.
Future<ResendResponse<ResendDeletion>> deleteDomain(
  Resend resend,
  String domainId,
) {
  return resend.domains.delete(domainId);
}

/// Starts an ownership claim for a domain belonging to another team.
Future<ResendResponse<DomainClaim>> claimDomain(Resend resend) {
  return resend.domains.claim(
    ClaimDomainRequest(
      name: 'mail.example.com',
      region: DomainRegion.euWest1,
      customReturnPath: 'bounce',
      openTracking: true,
      clickTracking: true,
      trackingSubdomain: 'links',
    ),
  );
}

/// Retrieves the current ownership claim for a domain.
Future<ResendResponse<DomainClaim>> retrieveDomainClaim(
  Resend resend,
  String domainId,
) {
  return resend.domains.retrieveClaim(domainId);
}

/// Verifies a domain claim after its ownership TXT record is installed.
Future<ResendResponse<DomainClaim>> verifyDomainClaim(
  Resend resend,
  String domainId,
) {
  return resend.domains.verifyClaim(domainId);
}
