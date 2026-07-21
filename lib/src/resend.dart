import 'package:http/http.dart' as http;

import 'core/transport.dart';
import 'resources/api_keys.dart';
import 'resources/automations.dart';
import 'resources/broadcasts.dart';
import 'resources/contact_properties.dart';
import 'resources/contacts.dart';
import 'resources/domains.dart';
import 'resources/emails.dart';
import 'resources/events.dart';
import 'resources/logs.dart';
import 'resources/oauth.dart';
import 'resources/segments.dart';
import 'resources/suppressions.dart';
import 'resources/templates.dart';
import 'resources/topics.dart';
import 'resources/webhooks.dart';

/// The current package version included in every request's User-Agent.
const String dartResendVersion = '2.0.0';

/// A production-ready client for the Resend API.
///
/// Create one client per application or service, reuse it, and call [close]
/// when the client is no longer needed. API keys should be loaded from a
/// server-side secret store or environment variable, never shipped in a
/// browser or other untrusted client.
final class Resend {
  /// Creates an authenticated Resend client.
  Resend({
    required String apiKey,
    http.Client? client,
    Uri? baseUri,
    Uri? authorizationBaseUri,
    Duration timeout = const Duration(seconds: 30),
    Map<String, String> defaultHeaders = const <String, String>{},
    bool closeClient = false,
  }) : this._(
         ResendTransport(
           apiKey: apiKey,
           client: client,
           baseUri: baseUri,
           timeout: timeout,
           userAgent: 'dart_resend/$dartResendVersion',
           defaultHeaders: defaultHeaders,
           closeClient: closeClient,
         ),
         authorizationBaseUri ?? baseUri ?? Uri.parse('https://api.resend.com'),
       );

  /// Creates a client for unauthenticated OAuth registration and token calls.
  ///
  /// Authenticated resource calls and OAuth grant management will fail until
  /// an access token is supplied through the primary [Resend] constructor.
  Resend.unauthenticated({
    http.Client? client,
    Uri? baseUri,
    Uri? authorizationBaseUri,
    Duration timeout = const Duration(seconds: 30),
    Map<String, String> defaultHeaders = const <String, String>{},
    bool closeClient = false,
  }) : this._(
         ResendTransport(
           client: client,
           baseUri: baseUri,
           timeout: timeout,
           userAgent: 'dart_resend/$dartResendVersion',
           defaultHeaders: defaultHeaders,
           closeClient: closeClient,
         ),
         authorizationBaseUri ?? baseUri ?? Uri.parse('https://api.resend.com'),
       );

  /// Wires one transport into all resource clients exposed by this facade.
  Resend._(ResendTransport transport, Uri authorizationBaseUri)
    : _transport = transport,
      emails = EmailsResource(transport),
      domains = DomainsResource(transport),
      apiKeys = ApiKeysResource(transport),
      broadcasts = BroadcastsResource(transport),
      templates = TemplatesResource(transport),
      contacts = ContactsResource(transport),
      segments = SegmentsResource(transport),
      topics = TopicsResource(transport),
      contactProperties = ContactPropertiesResource(transport),
      webhooks = WebhooksResource(transport),
      logs = LogsResource(transport),
      automations = AutomationsResource(transport),
      events = EventsResource(transport),
      suppressions = SuppressionsResource(transport),
      oauth = OAuthResource(transport, baseUrl: authorizationBaseUri);

  /// Shared transport owned by this facade and used by every resource client.
  final ResendTransport _transport;

  /// Sending, scheduling, batch, received-email, and attachment operations.
  final EmailsResource emails;

  /// Domain, DNS record, verification, and domain-claim operations.
  final DomainsResource domains;

  /// API-key management operations.
  final ApiKeysResource apiKeys;

  /// Marketing broadcast operations.
  final BroadcastsResource broadcasts;

  /// Reusable email-template operations.
  final TemplatesResource templates;

  /// Contact, membership, subscription, and CSV import operations.
  final ContactsResource contacts;

  /// Contact-segment operations.
  final SegmentsResource segments;

  /// Contact subscription-topic operations.
  final TopicsResource topics;

  /// Custom contact-property operations.
  final ContactPropertiesResource contactProperties;

  /// Webhook endpoint operations.
  final WebhooksResource webhooks;

  /// API request-log operations.
  final LogsResource logs;

  /// Automation graph and run operations.
  final AutomationsResource automations;

  /// Custom event definition and delivery operations.
  final EventsResource events;

  /// Email suppression operations.
  ///
  /// This Resend API is currently gated as a private beta.
  final SuppressionsResource suppressions;

  /// OAuth 2.1, PKCE, token, and grant operations.
  final OAuthResource oauth;

  /// Releases the internally owned HTTP client, if any.
  void close() => _transport.close();
}
