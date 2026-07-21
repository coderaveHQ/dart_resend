import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/resources/api_keys.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../support/mock_transport.dart';

/// Registers this file's test cases with the package:test runner.
void main() {
  // Verifies: API key request validates and serializes permissions.
  test('API key request validates and serializes permissions', () {
    final CreateApiKeyRequest request = CreateApiKeyRequest(
      name: 'Mailer',
      permission: ApiKeyPermission.sendingAccess,
      domainId: 'domain_1',
    );
    expect(request.toJson(), <String, Object?>{
      'name': 'Mailer',
      'permission': 'sending_access',
      'domain_id': 'domain_1',
    });
    expect(ApiKeyPermission.fullAccess.value, 'full_access');
    expect(ApiKeyPermission.sendingAccess.value, 'sending_access');
    expect(CreateApiKeyRequest(name: 'All').toJson(), <String, Object?>{
      'name': 'All',
    });
    expect(() => CreateApiKeyRequest(name: ' '), throwsArgumentError);
    expect(
      () => CreateApiKeyRequest(
        name: 'Bad',
        permission: ApiKeyPermission.fullAccess,
        domainId: 'domain_1',
      ),
      throwsArgumentError,
    );
  });

  // Verifies: API key models expose response data.
  test('API key models expose response data', () {
    final CreatedApiKey created = CreatedApiKey.fromJson(<String, Object?>{
      'id': 'key_1',
      'token': 're_secret',
    });
    expect(created.id, 'key_1');
    expect(created.token, 're_secret');

    final ApiKey key = ApiKey.fromJson(<String, Object?>{
      'id': 'key_1',
      'name': 'Mailer',
      'created_at': '2026-07-20T10:00:00Z',
      'last_used_at': '2026-07-20T11:00:00Z',
    });
    expect(key.id, 'key_1');
    expect(key.name, 'Mailer');
    expect(key.createdAt, DateTime.utc(2026, 7, 20, 10));
    expect(key.lastUsedAt, DateTime.utc(2026, 7, 20, 11));
    expect(
      ApiKey.fromJson(<String, Object?>{
        'id': 'key_2',
        'name': 'Unused',
        'created_at': '2026-07-20T10:00:00Z',
        'last_used_at': null,
      }).lastUsedAt,
      isNull,
    );
  });

  // Verifies: API key resource calls create, list, and delete endpoints.
  test('API key resource calls create, list, and delete endpoints', () async {
    var call = 0;
    final ApiKeysResource resource = ApiKeysResource(
      mockTransport((http.Request request) async {
        call++;
        if (call == 1) {
          expect(request.method, 'POST');
          expect(request.url.path, '/v1/api-keys');
          expect(decodedBody(request), <String, Object?>{'name': 'Mailer'});
          return jsonResponse(<String, Object?>{
            'id': 'key_1',
            'token': 're_secret',
          }, statusCode: 201);
        }
        if (call == 2) {
          expect(request.method, 'GET');
          expect(request.url.queryParameters, <String, String>{
            'limit': '1',
            'after': 'key_0',
          });
          return jsonResponse(<String, Object?>{
            'object': 'list',
            'has_more': false,
            'data': <Object?>[
              <String, Object?>{
                'id': 'key_1',
                'name': 'Mailer',
                'created_at': '2026-07-20T10:00:00Z',
                'last_used_at': null,
              },
            ],
          });
        }
        expect(request.method, 'DELETE');
        expect(request.url.path, '/v1/api-keys/key%2F1');
        return jsonResponse(<String, Object?>{
          'object': 'api_key',
          'id': 'key/1',
          'deleted': true,
        });
      }),
    );

    expect(
      (await resource.create(CreateApiKeyRequest(name: 'Mailer'))).data.token,
      're_secret',
    );
    final ApiKey listed = (await resource.list(
      pagination: PaginationOptions(limit: 1, after: 'key_0'),
    )).data.data.single;
    expect(listed.name, 'Mailer');
    expect((await resource.delete('key/1')).data.deleted, isTrue);
    expect(() => resource.delete(' '), throwsArgumentError);
  });
}
