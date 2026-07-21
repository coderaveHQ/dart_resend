import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// Permission granted to a Resend API key.
enum ApiKeyPermission implements ResendWireValue {
  /// Full access to every API resource.
  fullAccess('full_access'),

  /// Permission to send email only.
  sendingAccess('sending_access');

  const ApiKeyPermission(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// Parameters for creating a Resend API key.
final class CreateApiKeyRequest implements ResendRequest {
  /// Creates API-key parameters.
  CreateApiKeyRequest({required String name, this.permission, this.domainId})
    : name = requireNonBlank(name, 'name') {
    if (domainId != null && permission != ApiKeyPermission.sendingAccess) {
      throw ArgumentError(
        'domainId can only be used with ApiKeyPermission.sendingAccess.',
      );
    }
  }

  /// Human-readable key name.
  final String name;

  /// Access granted to the key.
  final ApiKeyPermission? permission;

  /// Optional domain restriction for a sending-only key.
  final String? domainId;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'name': name,
    'permission': permission?.value,
    'domain_id': domainId,
  });
}

/// A newly created API key and its one-time token.
final class CreatedApiKey extends ResendModel {
  /// Decodes a newly created API key.
  CreatedApiKey.fromJson(super.json);

  /// The API key ID.
  String get id => field<String>('id');

  /// The secret token. Store it securely because it is only returned once.
  String get token => field<String>('token');
}

/// API-key metadata returned by list operations.
final class ApiKey extends ResendModel {
  /// Decodes API-key metadata.
  ApiKey.fromJson(super.json);

  /// The API key ID.
  String get id => field<String>('id');

  /// Human-readable key name.
  String get name => field<String>('name');

  /// When the key was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// When the key was last used, if it has been used.
  DateTime? get lastUsedAt => optionalDateTimeField('last_used_at');
}

/// Operations for managing Resend API keys.
final class ApiKeysResource {
  /// Creates an API-key resource client.
  ApiKeysResource(this._transport);

  /// Transport used to execute API-key endpoint requests.
  final ResendTransport _transport;

  /// Creates an API key.
  Future<ResendResponse<CreatedApiKey>> create(CreateApiKeyRequest request) {
    return _transport.post<CreatedApiKey>(
      pathSegments: <String>['api-keys'],
      body: request.toJson(),
      decode: CreatedApiKey.fromJson,
    );
  }

  /// Lists API keys.
  Future<ResendResponse<ResendPage<ApiKey>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<ApiKey>>(
      pathSegments: <String>['api-keys'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<ApiKey>.fromJson(json, ApiKey.fromJson),
    );
  }

  /// Deletes an API key by [id].
  Future<ResendResponse<ResendDeletion>> delete(String id) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>['api-keys', requireNonBlank(id, 'id')],
      decode: ResendDeletion.fromJson,
    );
  }
}
