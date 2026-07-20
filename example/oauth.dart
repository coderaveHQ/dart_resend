import 'package:dart_resend/dart_resend.dart';

/// Registers a public OAuth client without a Resend API key.
Future<ResendResponse<RegisteredOAuthClient>> registerOAuthClient() async {
  final Resend resend = Resend.unauthenticated(
    authorizationBaseUri: Uri.parse('https://api.resend.com'),
  );
  try {
    return await resend.oauth.register(
      RegisterOAuthClientRequest(
        clientName: 'Acme integration',
        redirectUris: <Uri>[
          Uri.parse('https://app.example.com/oauth/resend/callback'),
        ],
        scopes: <OAuthScope>[OAuthScope.emailsSend],
        clientUri: Uri.parse('https://app.example.com'),
        logoUri: Uri.parse('https://app.example.com/logo.png'),
      ),
    );
  } finally {
    resend.close();
  }
}

/// Generates PKCE values and builds the URL to open in the user's browser.
({OAuthPkcePair pkce, Uri authorizationUri}) buildOAuthAuthorization(
  Resend resend, {
  required String clientId,
}) {
  final OAuthPkcePair pkce = OAuthPkcePair.generate();
  final Uri authorizationUri = resend.oauth.authorizationUri(
    OAuthAuthorizationRequest(
      clientId: clientId,
      redirectUri: Uri.parse('https://app.example.com/oauth/resend/callback'),
      codeChallenge: pkce.challenge,
      scopes: <OAuthScope>[OAuthScope.emailsSend],
      state: 'csrf-bound-random-state',
    ),
  );
  return (pkce: pkce, authorizationUri: authorizationUri);
}

/// Restores an S256 PKCE pair from a securely retained verifier.
OAuthPkcePair restorePkcePair(String verifier) {
  return OAuthPkcePair.fromVerifier(verifier);
}

/// Exchanges the callback authorization code for a token pair.
Future<ResendResponse<OAuthToken>> exchangeOAuthCode(
  Resend resend, {
  required String clientId,
  required String authorizationCode,
  required String codeVerifier,
}) {
  return resend.oauth.exchangeCode(
    clientId: clientId,
    code: authorizationCode,
    redirectUri: Uri.parse('https://app.example.com/oauth/resend/callback'),
    codeVerifier: codeVerifier,
  );
}

/// Rotates an OAuth refresh token.
Future<ResendResponse<OAuthToken>> refreshOAuthToken(
  Resend resend, {
  required String clientId,
  required String refreshToken,
}) {
  return resend.oauth.refresh(
    clientId: clientId,
    refreshToken: refreshToken,
    scopes: <OAuthScope>[OAuthScope.emailsSend],
  );
}

/// Revokes a refresh token and its complete grant.
Future<ResendResponse<void>> revokeOAuthToken(
  Resend resend, {
  required String clientId,
  required String refreshToken,
}) {
  return resend.oauth.revokeToken(
    clientId: clientId,
    refreshToken: refreshToken,
  );
}

/// Creates an authenticated SDK client from an OAuth access token.
///
/// The caller must close the returned client.
Resend oauthAccessTokenClient(OAuthToken token) {
  return Resend(apiKey: token.accessToken);
}

/// Lists apps authorized by the authenticated Resend team.
Future<ResendResponse<ResendPage<OAuthGrant>>> listOAuthGrants(Resend resend) {
  return resend.oauth.listGrants(pagination: PaginationOptions(limit: 25));
}

/// Revokes one app grant using team authentication.
Future<ResendResponse<RevokedOAuthGrant>> revokeOAuthGrant(
  Resend resend,
  String grantId,
) {
  return resend.oauth.revokeGrant(grantId);
}
