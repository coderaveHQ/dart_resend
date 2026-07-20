import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// A scope currently documented by Resend's OAuth service.
enum OAuthScope implements ResendWireValue {
  /// Permission to send emails and send existing broadcasts.
  emailsSend('emails:send'),

  /// Permission to call every API route.
  fullAccess('full_access');

  const OAuthScope(this.value);

  @override
  final String value;
}

/// PKCE verifier and S256 challenge for an OAuth authorization flow.
final class OAuthPkcePair {
  /// Creates and validates a PKCE pair from an existing verifier.
  factory OAuthPkcePair.fromVerifier(String verifier) {
    final String value = requireNonBlank(verifier, 'verifier');
    if (value.length < 43 || value.length > 128) {
      throw RangeError.range(value.length, 43, 128, 'verifier.length');
    }
    if (!RegExp(r'^[A-Za-z0-9._~-]+$').hasMatch(value)) {
      throw ArgumentError.value(
        verifier,
        'verifier',
        'Must contain only RFC 7636 unreserved characters.',
      );
    }
    final String challenge = base64Url
        .encode(sha256.convert(ascii.encode(value)).bytes)
        .replaceAll('=', '');
    return OAuthPkcePair._(value, challenge);
  }

  /// Generates a cryptographically secure PKCE pair.
  factory OAuthPkcePair.generate({Random? random}) {
    final Random generator = random ?? Random.secure();
    final List<int> bytes = List<int>.generate(
      64,
      (int index) => generator.nextInt(256),
      growable: false,
    );
    return OAuthPkcePair.fromVerifier(
      base64Url.encode(bytes).replaceAll('=', ''),
    );
  }

  OAuthPkcePair._(this.verifier, this.challenge);

  /// The secret value retained by the OAuth client.
  final String verifier;

  /// The public S256 challenge sent to the authorization endpoint.
  final String challenge;
}

/// Dynamic OAuth client-registration parameters.
final class RegisterOAuthClientRequest implements ResendRequest {
  /// Creates OAuth client-registration parameters.
  RegisterOAuthClientRequest({
    required String clientName,
    required List<Uri> redirectUris,
    List<String> grantTypes = const <String>[
      'authorization_code',
      'refresh_token',
    ],
    List<String> responseTypes = const <String>['code'],
    List<OAuthScope>? scopes,
    this.clientUri,
    this.logoUri,
  }) : clientName = requireNonBlank(clientName, 'clientName'),
       redirectUris = List<Uri>.unmodifiable(redirectUris),
       grantTypes = List<String>.unmodifiable(grantTypes),
       responseTypes = List<String>.unmodifiable(responseTypes),
       scopes = scopes == null ? null : List<OAuthScope>.unmodifiable(scopes) {
    if (clientName.length > 200) {
      throw RangeError.range(clientName.length, 1, 200, 'clientName.length');
    }
    if (redirectUris.isEmpty || redirectUris.length > 10) {
      throw RangeError.range(redirectUris.length, 1, 10, 'redirectUris.length');
    }
    for (final Uri uri in redirectUris) {
      _validateRedirectUri(uri);
    }
    if (!grantTypes.contains('authorization_code') ||
        grantTypes.any(
          (String value) =>
              value != 'authorization_code' && value != 'refresh_token',
        )) {
      throw ArgumentError.value(
        grantTypes,
        'grantTypes',
        'Unsupported grants.',
      );
    }
    if (responseTypes.length != 1 || responseTypes.single != 'code') {
      throw ArgumentError.value(
        responseTypes,
        'responseTypes',
        'Only the code response type is supported.',
      );
    }
  }

  /// Human-readable client name.
  final String clientName;

  /// Allowed OAuth callback URIs.
  final List<Uri> redirectUris;

  /// Requested grant types.
  final List<String> grantTypes;

  /// Requested response types. Resend only supports `code`.
  final List<String> responseTypes;

  /// Allowed OAuth scopes, or all supported scopes when omitted.
  final List<OAuthScope>? scopes;

  /// Optional client homepage.
  final Uri? clientUri;

  /// Optional logo displayed on the consent screen.
  final Uri? logoUri;

  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'client_name': clientName,
    'redirect_uris': redirectUris.map((Uri uri) => uri.toString()).toList(),
    'grant_types': List<String>.unmodifiable(grantTypes),
    'response_types': List<String>.unmodifiable(responseTypes),
    'scope': _scopeValue(scopes),
    'token_endpoint_auth_method': 'none',
    'client_uri': clientUri?.toString(),
    'logo_uri': logoUri?.toString(),
  });
}

/// A dynamically registered public OAuth client.
final class RegisteredOAuthClient extends ResendModel {
  /// Decodes a registered OAuth client.
  RegisteredOAuthClient.fromJson(super.json);

  /// The assigned client ID.
  String get clientId => field<String>('client_id');

  /// Unix timestamp at which the client ID was issued.
  int get clientIdIssuedAt => field<int>('client_id_issued_at');

  /// Human-readable client name.
  String get clientName => field<String>('client_name');

  /// Registered redirect URI strings.
  List<String> get redirectUris => listField<String>('redirect_uris');

  /// Registered grant types.
  List<String> get grantTypes => listField<String>('grant_types');

  /// Registered response types.
  List<String> get responseTypes => listField<String>('response_types');

  /// Token endpoint authentication method, currently `none`.
  String get tokenEndpointAuthMethod =>
      field<String>('token_endpoint_auth_method');

  /// Space-delimited registered scopes.
  String get scope => field<String>('scope');
}

/// Parameters used to build the browser authorization URL.
final class OAuthAuthorizationRequest {
  /// Creates an OAuth authorization request.
  OAuthAuthorizationRequest({
    required String clientId,
    required this.redirectUri,
    required String codeChallenge,
    List<OAuthScope>? scopes,
    this.state,
  }) : clientId = requireNonBlank(clientId, 'clientId'),
       codeChallenge = requireNonBlank(codeChallenge, 'codeChallenge'),
       scopes = scopes == null ? null : List<OAuthScope>.unmodifiable(scopes) {
    _validateRedirectUri(redirectUri);
    if (state != null && state!.length > 1024) {
      throw RangeError.range(state!.length, 0, 1024, 'state.length');
    }
  }

  /// Registered OAuth client ID.
  final String clientId;

  /// Callback URI used for this flow.
  final Uri redirectUri;

  /// Base64url-encoded S256 PKCE challenge.
  final String codeChallenge;

  /// Requested scopes, or the client's full registered scope set.
  final List<OAuthScope>? scopes;

  /// Opaque CSRF-binding state value.
  final String? state;
}

/// Access and refresh tokens returned by Resend OAuth.
final class OAuthToken extends ResendModel {
  /// Decodes an OAuth token response.
  OAuthToken.fromJson(super.json);

  /// Short-lived bearer access token.
  String get accessToken => field<String>('access_token');

  /// Token type, currently `Bearer`.
  String get tokenType => field<String>('token_type');

  /// Number of seconds until the access token expires.
  int get expiresIn => field<int>('expires_in');

  /// Rotating refresh token.
  String get refreshToken => field<String>('refresh_token');

  /// Space-delimited granted scopes.
  String get scope => field<String>('scope');
}

/// An OAuth grant authorized by the authenticated Resend team.
final class OAuthGrant extends ResendModel {
  /// Decodes an OAuth grant.
  OAuthGrant.fromJson(super.json);

  /// The grant ID.
  String get id => field<String>('id');

  /// The client ID that owns this grant.
  String get clientId => field<String>('client_id');

  /// Granted scope strings.
  List<String> get scopes => listField<String>('scopes');

  /// When the grant was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// When the grant was revoked, if it is revoked.
  DateTime? get revokedAt => optionalDateTimeField('revoked_at');

  /// Why the grant was revoked, when available.
  String? get revokedReason => optionalField<String>('revoked_reason');

  /// OAuth client metadata embedded in the grant.
  JsonObject get client => objectField('client');
}

/// Details returned after revoking an OAuth grant.
final class RevokedOAuthGrant extends ResendModel {
  /// Decodes a revoked grant.
  RevokedOAuthGrant.fromJson(super.json);

  /// The grant ID.
  String get id => field<String>('id');

  /// When the grant was revoked.
  DateTime get revokedAt => dateTimeField('revoked_at');

  /// The revocation reason.
  String get revokedReason => field<String>('revoked_reason');
}

/// OAuth 2.1, PKCE, token, and authorized-app operations.
final class OAuthResource {
  /// Creates an OAuth resource client.
  OAuthResource(this._transport, {required Uri baseUrl}) : _baseUrl = baseUrl;

  final ResendTransport _transport;
  final Uri _baseUrl;

  /// Dynamically registers an unauthenticated public OAuth client.
  Future<ResendResponse<RegisteredOAuthClient>> register(
    RegisterOAuthClientRequest request,
  ) {
    return _transport.post<RegisteredOAuthClient>(
      pathSegments: <String>['oauth', 'register'],
      body: request.toJson(),
      authenticated: false,
      decode: RegisteredOAuthClient.fromJson,
    );
  }

  /// Builds the URL that must be opened in the user's browser.
  Uri authorizationUri(OAuthAuthorizationRequest request) {
    return _baseUrl.replace(
      pathSegments: <String>[
        ..._baseUrl.pathSegments.where((String segment) => segment.isNotEmpty),
        'oauth',
        'authorize',
      ],
      queryParameters: <String, String>{
        'client_id': request.clientId,
        'response_type': 'code',
        'redirect_uri': request.redirectUri.toString(),
        if (request.scopes != null) 'scope': _scopeValue(request.scopes)!,
        if (request.state != null) 'state': request.state!,
        'code_challenge': request.codeChallenge,
        'code_challenge_method': 'S256',
      },
    );
  }

  /// Exchanges an authorization [code] using the original PKCE verifier.
  Future<ResendResponse<OAuthToken>> exchangeCode({
    required String clientId,
    required String code,
    required Uri redirectUri,
    required String codeVerifier,
  }) {
    OAuthPkcePair.fromVerifier(codeVerifier);
    return _transport.post<OAuthToken>(
      pathSegments: <String>['oauth', 'token'],
      authenticated: false,
      form: <String, String>{
        'grant_type': 'authorization_code',
        'client_id': requireNonBlank(clientId, 'clientId'),
        'code': requireNonBlank(code, 'code'),
        'redirect_uri': redirectUri.toString(),
        'code_verifier': codeVerifier,
      },
      decode: OAuthToken.fromJson,
    );
  }

  /// Rotates a refresh token and returns a new token pair.
  Future<ResendResponse<OAuthToken>> refresh({
    required String clientId,
    required String refreshToken,
    List<OAuthScope>? scopes,
  }) {
    return _transport.post<OAuthToken>(
      pathSegments: <String>['oauth', 'token'],
      authenticated: false,
      form: <String, String>{
        'grant_type': 'refresh_token',
        'client_id': requireNonBlank(clientId, 'clientId'),
        'refresh_token': requireNonBlank(refreshToken, 'refreshToken'),
        if (scopes != null) 'scope': _scopeValue(scopes)!,
      },
      decode: OAuthToken.fromJson,
    );
  }

  /// Revokes a refresh token and its entire grant.
  Future<ResendResponse<void>> revokeToken({
    required String clientId,
    required String refreshToken,
  }) {
    return _transport.post<void>(
      pathSegments: <String>['oauth', 'revoke'],
      authenticated: false,
      form: <String, String>{
        'client_id': requireNonBlank(clientId, 'clientId'),
        'token': requireNonBlank(refreshToken, 'refreshToken'),
        'token_type_hint': 'refresh_token',
      },
      decode: (JsonObject json) {},
    );
  }

  /// Lists OAuth grants authorized by the authenticated team.
  Future<ResendResponse<ResendPage<OAuthGrant>>> listGrants({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<OAuthGrant>>(
      pathSegments: <String>['oauth', 'grants'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<OAuthGrant>.fromJson(json, OAuthGrant.fromJson),
    );
  }

  /// Revokes an OAuth grant by [id] using team authentication.
  Future<ResendResponse<RevokedOAuthGrant>> revokeGrant(String id) {
    return _transport.delete<RevokedOAuthGrant>(
      pathSegments: <String>['oauth', 'grants', requireNonBlank(id, 'id')],
      decode: RevokedOAuthGrant.fromJson,
    );
  }
}

String? _scopeValue(List<OAuthScope>? scopes) {
  if (scopes == null) return null;
  if (scopes.isEmpty) {
    throw ArgumentError.value(scopes, 'scopes', 'Must not be empty.');
  }
  return scopes.map((OAuthScope scope) => scope.value).join(' ');
}

void _validateRedirectUri(Uri uri) {
  final String value = uri.toString();
  if (!uri.hasScheme || value.length > 2048 || uri.hasFragment) {
    throw ArgumentError.value(
      uri,
      'redirectUri',
      'Invalid OAuth redirect URI.',
    );
  }
  const Set<String> forbidden = <String>{
    'file',
    'ftp',
    'data',
    'javascript',
    'blob',
    'about',
    'vbscript',
  };
  final String scheme = uri.scheme.toLowerCase();
  if (forbidden.contains(scheme)) {
    throw ArgumentError.value(uri, 'redirectUri', 'Scheme is not allowed.');
  }
  if (scheme == 'http') {
    final String host = uri.host.toLowerCase();
    if (host != 'localhost' && host != '127.0.0.1' && host != '::1') {
      throw ArgumentError.value(
        uri,
        'redirectUri',
        'HTTP is only allowed for loopback redirect URIs.',
      );
    }
  }
  if ((scheme == 'http' || scheme == 'https') && uri.host.isEmpty) {
    throw ArgumentError.value(uri, 'redirectUri', 'Host must not be empty.');
  }
}
