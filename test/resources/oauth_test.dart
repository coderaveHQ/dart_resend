import 'dart:math';

import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/resources/oauth.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../support/mock_transport.dart';

void main() {
  test('PKCE generates and validates S256 verifier pairs', () {
    const String verifier =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final OAuthPkcePair pair = OAuthPkcePair.fromVerifier(verifier);
    expect(pair.verifier, verifier);
    expect(pair.challenge, isNotEmpty);
    final OAuthPkcePair generated = OAuthPkcePair.generate(random: Random(1));
    expect(generated.verifier.length, inInclusiveRange(43, 128));
    expect(generated.challenge, isNot(contains('=')));

    expect(() => OAuthPkcePair.fromVerifier(' '), throwsArgumentError);
    expect(() => OAuthPkcePair.fromVerifier('short'), throwsRangeError);
    expect(
      () => OAuthPkcePair.fromVerifier(_repeat('a', 129)),
      throwsRangeError,
    );
    expect(
      () => OAuthPkcePair.fromVerifier('${_repeat('a', 42)}!'),
      throwsArgumentError,
    );
  });

  test('PKCE uses a secure random source by default', () {
    final OAuthPkcePair pair = OAuthPkcePair.generate();

    expect(pair.verifier.length, inInclusiveRange(43, 128));
    expect(pair.challenge, isNotEmpty);
  });

  test('OAuth registration validates and serializes public clients', () {
    final RegisterOAuthClientRequest request = RegisterOAuthClientRequest(
      clientName: 'Dart client',
      redirectUris: <Uri>[
        Uri.parse('http://127.0.0.1/callback'),
        Uri.parse('vscode://extension/callback'),
      ],
      scopes: <OAuthScope>[OAuthScope.emailsSend, OAuthScope.fullAccess],
      clientUri: Uri.parse('https://example.com'),
      logoUri: Uri.parse('https://example.com/logo.png'),
    );
    expect(request.toJson(), <String, Object?>{
      'client_name': 'Dart client',
      'redirect_uris': <String>[
        'http://127.0.0.1/callback',
        'vscode://extension/callback',
      ],
      'grant_types': <String>['authorization_code', 'refresh_token'],
      'response_types': <String>['code'],
      'scope': 'emails:send full_access',
      'token_endpoint_auth_method': 'none',
      'client_uri': 'https://example.com',
      'logo_uri': 'https://example.com/logo.png',
    });
    expect(OAuthScope.emailsSend.value, 'emails:send');
    expect(OAuthScope.fullAccess.value, 'full_access');
    expect(
      RegisterOAuthClientRequest(
        clientName: 'Defaults',
        redirectUris: <Uri>[Uri.parse('https://example.com/callback')],
      ).toJson().containsKey('scope'),
      isFalse,
    );
  });

  test('OAuth registration rejects invalid metadata', () {
    expect(
      () => RegisterOAuthClientRequest(
        clientName: _repeat('a', 201),
        redirectUris: <Uri>[Uri.parse('https://example.com')],
      ),
      throwsRangeError,
    );
    expect(
      () => RegisterOAuthClientRequest(
        clientName: 'No redirects',
        redirectUris: <Uri>[],
      ),
      throwsRangeError,
    );
    expect(
      () => RegisterOAuthClientRequest(
        clientName: 'Too many',
        redirectUris: List<Uri>.filled(11, Uri.parse('https://example.com')),
      ),
      throwsRangeError,
    );
    for (final Uri invalid in <Uri>[
      Uri.parse('/relative'),
      Uri.parse('https://example.com/callback#fragment'),
      Uri.parse('file:///tmp/callback'),
      Uri.parse('http://example.com/callback'),
      Uri.parse('https:'),
    ]) {
      expect(
        () => RegisterOAuthClientRequest(
          clientName: 'Invalid',
          redirectUris: <Uri>[invalid],
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => RegisterOAuthClientRequest(
        clientName: 'No code',
        redirectUris: <Uri>[Uri.parse('https://example.com')],
        grantTypes: <String>['refresh_token'],
      ),
      throwsArgumentError,
    );
    expect(
      () => RegisterOAuthClientRequest(
        clientName: 'Bad grant',
        redirectUris: <Uri>[Uri.parse('https://example.com')],
        grantTypes: <String>['authorization_code', 'client_credentials'],
      ),
      throwsArgumentError,
    );
    expect(
      () => RegisterOAuthClientRequest(
        clientName: 'Bad response',
        redirectUris: <Uri>[Uri.parse('https://example.com')],
        responseTypes: <String>['token'],
      ),
      throwsArgumentError,
    );
    final RegisterOAuthClientRequest emptyScopes = RegisterOAuthClientRequest(
      clientName: 'Empty scopes',
      redirectUris: <Uri>[Uri.parse('https://example.com')],
      scopes: <OAuthScope>[],
    );
    expect(() => emptyScopes.toJson(), throwsArgumentError);
  });

  test('OAuth models expose registration, token, and grant data', () {
    final RegisteredOAuthClient client = RegisteredOAuthClient.fromJson(
      _clientJson,
    );
    expect(client.clientId, 'client_1');
    expect(client.clientIdIssuedAt, 1_750_000_000);
    expect(client.clientName, 'Dart client');
    expect(client.redirectUris, <String>['https://example.com/callback']);
    expect(client.grantTypes, <String>['authorization_code', 'refresh_token']);
    expect(client.responseTypes, <String>['code']);
    expect(client.tokenEndpointAuthMethod, 'none');
    expect(client.scope, 'emails:send');

    final OAuthToken token = OAuthToken.fromJson(_tokenJson);
    expect(token.accessToken, 'access');
    expect(token.tokenType, 'Bearer');
    expect(token.expiresIn, 900);
    expect(token.refreshToken, 'refresh');
    expect(token.scope, 'emails:send');

    final OAuthGrant grant = OAuthGrant.fromJson(_grantJson);
    expect(grant.id, 'grant_1');
    expect(grant.clientId, 'client_1');
    expect(grant.scopes, <String>['emails:send']);
    expect(grant.createdAt, DateTime.utc(2026, 7, 20, 12));
    expect(grant.revokedAt, DateTime.utc(2026, 7, 20, 13));
    expect(grant.revokedReason, 'user_revoked');
    expect(grant.client['name'], 'Dart client');
    expect(
      OAuthGrant.fromJson(<String, Object?>{
        ..._grantJson,
        'revoked_at': null,
        'revoked_reason': null,
      }).revokedAt,
      isNull,
    );

    final RevokedOAuthGrant revoked = RevokedOAuthGrant.fromJson(
      _revokedGrantJson,
    );
    expect(revoked.id, 'grant_1');
    expect(revoked.revokedAt, DateTime.utc(2026, 7, 20, 13));
    expect(revoked.revokedReason, 'user_revoked');
  });

  test(
    'OAuth resource covers registration, PKCE, tokens, and grants',
    () async {
      var call = 0;
      final OAuthResource resource = OAuthResource(
        mockTransport((http.Request request) async {
          call++;
          switch (call) {
            case 1:
              expect(request.url.path, '/v1/oauth/register');
              expect(request.headers.containsKey('authorization'), isFalse);
              return jsonResponse(_clientJson, statusCode: 201);
            case 2:
              expect(request.url.path, '/v1/oauth/token');
              expect(request.bodyFields['grant_type'], 'authorization_code');
              return jsonResponse(_tokenJson);
            case 3:
              expect(
                request.bodyFields,
                containsPair('grant_type', 'refresh_token'),
              );
              expect(request.bodyFields, containsPair('scope', 'emails:send'));
              return jsonResponse(_tokenJson);
            case 4:
              expect(request.url.path, '/v1/oauth/revoke');
              expect(request.bodyFields['token_type_hint'], 'refresh_token');
              return http.Response('', 200);
            case 5:
              expect(request.url.path, '/v1/oauth/grants');
              expect(request.url.queryParameters, <String, String>{
                'limit': '1',
              });
              return jsonResponse(<String, Object?>{
                'object': 'list',
                'has_more': false,
                'data': <Object?>[_grantJson],
              });
            default:
              expect(request.method, 'DELETE');
              expect(request.url.path, '/v1/oauth/grants/grant%2F1');
              return jsonResponse(_revokedGrantJson);
          }
        }),
        baseUrl: Uri.parse('https://api.test/v1'),
      );

      expect(
        (await resource.register(
          RegisterOAuthClientRequest(
            clientName: 'Dart client',
            redirectUris: <Uri>[Uri.parse('https://example.com/callback')],
          ),
        )).data.clientId,
        'client_1',
      );

      final OAuthPkcePair pair = OAuthPkcePair.fromVerifier(_repeat('a', 43));
      final Uri authorization = resource.authorizationUri(
        OAuthAuthorizationRequest(
          clientId: 'client_1',
          redirectUri: Uri.parse('https://example.com/callback'),
          codeChallenge: pair.challenge,
          scopes: <OAuthScope>[OAuthScope.emailsSend],
          state: 'state_1',
        ),
      );
      expect(authorization.path, '/v1/oauth/authorize');
      expect(authorization.queryParameters['response_type'], 'code');
      expect(authorization.queryParameters['scope'], 'emails:send');
      expect(authorization.queryParameters['state'], 'state_1');
      expect(authorization.queryParameters['code_challenge_method'], 'S256');
      final Uri noOptionals = resource.authorizationUri(
        OAuthAuthorizationRequest(
          clientId: 'client_1',
          redirectUri: Uri.parse('localhost://callback'),
          codeChallenge: pair.challenge,
        ),
      );
      expect(noOptionals.queryParameters.containsKey('scope'), isFalse);
      expect(noOptionals.queryParameters.containsKey('state'), isFalse);

      expect(
        (await resource.exchangeCode(
          clientId: 'client_1',
          code: 'code_1',
          redirectUri: Uri.parse('https://example.com/callback'),
          codeVerifier: pair.verifier,
        )).data.accessToken,
        'access',
      );
      expect(
        (await resource.refresh(
          clientId: 'client_1',
          refreshToken: 'refresh',
          scopes: <OAuthScope>[OAuthScope.emailsSend],
        )).data.refreshToken,
        'refresh',
      );
      final revokeResponse = await resource.revokeToken(
        clientId: 'client_1',
        refreshToken: 'refresh',
      );
      expect(revokeResponse.statusCode, 200);
      expect(
        (await resource.listGrants(
          pagination: PaginationOptions(limit: 1),
        )).data.data.single.id,
        'grant_1',
      );
      expect((await resource.revokeGrant('grant/1')).data.id, 'grant_1');

      expect(
        () => OAuthAuthorizationRequest(
          clientId: 'client_1',
          redirectUri: Uri.parse('https://example.com'),
          codeChallenge: pair.challenge,
          state: _repeat('x', 1025),
        ),
        throwsRangeError,
      );
      expect(
        () => resource.exchangeCode(
          clientId: ' ',
          code: 'code',
          redirectUri: Uri.parse('https://example.com'),
          codeVerifier: pair.verifier,
        ),
        throwsArgumentError,
      );
      expect(
        () => resource.refresh(clientId: 'id', refreshToken: ' '),
        throwsArgumentError,
      );
      expect(
        () => resource.revokeToken(clientId: 'id', refreshToken: ' '),
        throwsArgumentError,
      );
      expect(() => resource.revokeGrant(' '), throwsArgumentError);
    },
  );
}

const Map<String, Object?> _clientJson = <String, Object?>{
  'client_id': 'client_1',
  'client_id_issued_at': 1_750_000_000,
  'client_name': 'Dart client',
  'redirect_uris': <String>['https://example.com/callback'],
  'grant_types': <String>['authorization_code', 'refresh_token'],
  'response_types': <String>['code'],
  'token_endpoint_auth_method': 'none',
  'scope': 'emails:send',
};

const Map<String, Object?> _tokenJson = <String, Object?>{
  'access_token': 'access',
  'token_type': 'Bearer',
  'expires_in': 900,
  'refresh_token': 'refresh',
  'scope': 'emails:send',
};

const Map<String, Object?> _grantJson = <String, Object?>{
  'id': 'grant_1',
  'client_id': 'client_1',
  'scopes': <String>['emails:send'],
  'created_at': '2026-07-20T12:00:00Z',
  'revoked_at': '2026-07-20T13:00:00Z',
  'revoked_reason': 'user_revoked',
  'client': <String, Object?>{'name': 'Dart client', 'logo_uri': null},
};

const Map<String, Object?> _revokedGrantJson = <String, Object?>{
  'object': 'oauth_grant',
  'id': 'grant_1',
  'revoked_at': '2026-07-20T13:00:00Z',
  'revoked_reason': 'user_revoked',
};

String _repeat(String value, int count) =>
    List<String>.filled(count, value).join();
