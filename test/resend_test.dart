import 'dart:convert';

import 'package:dart_resend/dart_resend.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test(
    'authenticated client exposes every resource and request metadata',
    () async {
      late http.Request captured;
      final MockClient httpClient = MockClient((http.Request request) async {
        captured = request;
        return http.Response('{"data":[]}', 200);
      });
      final Resend resend = Resend(
        apiKey: 're_test',
        client: httpClient,
        baseUri: Uri.parse('https://api.example.test/v1'),
        authorizationBaseUri: Uri.parse('https://accounts.example.test'),
        defaultHeaders: const <String, String>{'X-App': 'tests'},
      );

      expect(resend.emails, isA<EmailsResource>());
      expect(resend.domains, isA<DomainsResource>());
      expect(resend.apiKeys, isA<ApiKeysResource>());
      expect(resend.broadcasts, isA<BroadcastsResource>());
      expect(resend.templates, isA<TemplatesResource>());
      expect(resend.contacts, isA<ContactsResource>());
      expect(resend.contacts.imports, isA<ContactImportsResource>());
      expect(resend.segments, isA<SegmentsResource>());
      expect(resend.topics, isA<TopicsResource>());
      expect(resend.contactProperties, isA<ContactPropertiesResource>());
      expect(resend.webhooks, isA<WebhooksResource>());
      expect(resend.logs, isA<LogsResource>());
      expect(resend.automations, isA<AutomationsResource>());
      expect(resend.automations.runs, isA<AutomationRunsResource>());
      expect(resend.events, isA<EventsResource>());
      expect(resend.suppressions, isA<SuppressionsResource>());
      expect(resend.oauth, isA<OAuthResource>());
      expect(dartResendVersion, '2.0.0');

      await resend.logs.list();
      expect(captured.url.toString(), 'https://api.example.test/v1/logs');
      expect(captured.headers['authorization'], 'Bearer re_test');
      expect(captured.headers['user-agent'], 'dart_resend/2.0.0');
      expect(captured.headers['x-app'], 'tests');
      expect(
        resend.oauth
            .authorizationUri(
              OAuthAuthorizationRequest(
                clientId: 'client',
                redirectUri: Uri.parse('https://app.example.test/callback'),
                codeChallenge: 'challenge',
              ),
            )
            .host,
        'accounts.example.test',
      );
      resend.close();
    },
  );

  test('unauthenticated client supports public OAuth operations', () async {
    final MockClient httpClient = MockClient((http.Request request) async {
      expect(request.headers, isNot(contains('authorization')));
      return http.Response(
        jsonEncode(<String, Object?>{
          'client_id': 'client',
          'client_name': 'Example',
          'redirect_uris': <String>['https://app.example/callback'],
        }),
        200,
      );
    });
    final Resend resend = Resend.unauthenticated(
      client: httpClient,
      baseUri: Uri.parse('https://api.example.test'),
    );

    final ResendResponse<RegisteredOAuthClient> response = await resend.oauth
        .register(
          RegisterOAuthClientRequest(
            clientName: 'Example',
            redirectUris: <Uri>[Uri.parse('https://app.example/callback')],
          ),
        );
    expect(response.data.clientId, 'client');
    expect(
      resend.oauth
          .authorizationUri(
            OAuthAuthorizationRequest(
              clientId: 'client',
              redirectUri: Uri.parse('https://app.example/callback'),
              codeChallenge: 'challenge',
            ),
          )
          .origin,
      'https://api.example.test',
    );
    resend.close();
  });

  test('authenticated client uses the production authorization origin', () {
    final Resend resend = Resend(apiKey: 're_test');

    final Uri uri = resend.oauth.authorizationUri(
      OAuthAuthorizationRequest(
        clientId: 'client',
        redirectUri: Uri.parse('https://app.example/callback'),
        codeChallenge: 'challenge',
      ),
    );
    expect(uri.origin, 'https://api.resend.com');
    resend.close();
  });

  test('unauthenticated client uses the production authorization origin', () {
    final Resend resend = Resend.unauthenticated();

    final Uri uri = resend.oauth.authorizationUri(
      OAuthAuthorizationRequest(
        clientId: 'client',
        redirectUri: Uri.parse('https://app.example/callback'),
        codeChallenge: 'challenge',
      ),
    );
    expect(uri.origin, 'https://api.resend.com');
    resend.close();
  });
}
