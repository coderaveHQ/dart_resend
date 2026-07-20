import 'package:dart_resend/dart_resend.dart';

/// Creates a sending-only API key and returns its one-time secret token.
Future<ResendResponse<CreatedApiKey>> createApiKey(Resend resend) {
  return resend.apiKeys.create(
    CreateApiKeyRequest(
      name: 'Production sender',
      permission: ApiKeyPermission.sendingAccess,
      domainId: 'd_example',
    ),
  );
}

/// Lists API keys with cursor pagination.
Future<ResendResponse<ResendPage<ApiKey>>> listApiKeys(Resend resend) {
  return resend.apiKeys.list(
    pagination: PaginationOptions(limit: 20, after: 'key_cursor'),
  );
}

/// Deletes an API key.
Future<ResendResponse<ResendDeletion>> deleteApiKey(
  Resend resend,
  String apiKeyId,
) {
  return resend.apiKeys.delete(apiKeyId);
}
