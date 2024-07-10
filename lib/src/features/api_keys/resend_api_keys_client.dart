import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:dart_resend/src/features/api_keys/enums/resend_api_key_permission.dart';
import 'package:dart_resend/src/features/api_keys/models/resend_create_api_key_response.dart';
import 'package:dart_resend/src/features/api_keys/models/resend_delete_api_key_response.dart';
import 'package:dart_resend/src/features/api_keys/models/resend_list_api_keys_response.dart';
import 'package:dart_resend/src/utils/resend_result.dart';
import 'package:dart_resend/src/utils/typedefs.dart';

/// The client for the Resend API Keys API
class ResendApiKeysClient {
  /// API Key for API authentication
  final String _apiKey;

  /// Base URI for the Resend API Keys API
  final Uri _baseUri = Uri.parse('https://api.resend.com/api-keys');

  /// Constructor of ResendApiKeysClient
  ResendApiKeysClient({
    required String apiKey,
  }) : _apiKey = apiKey;

  /// Add a new API key to authenticate communications with Resend.
  Future<ResendResult<ResendCreateApiKeyResponse>> createApiKey(

      /// The API key name.
      String name,
      {
      /// The API key can have full access to Resend’s API or be only restricted to send emails. * full_access: Can create, delete, get, and update any resource. * sending_access: Can only send emails.
      ResendApiKeyPermission? permission,

      /// Restrict an API key to send emails only from a specific domain. This is only used when the permission is set to sending_access.
      String? domainId}) async {
    // Validation
    assert(name.isNotEmpty, 'The API Key name can not be empty.');

    // Construct the request URI
    final Uri uri =
        Uri(scheme: _baseUri.scheme, host: _baseUri.host, path: _baseUri.path);

    // Send GET request to the API
    final http.Response response = await http.post(uri,
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(<String, dynamic>{
          'name': name,
          if (permission != null) 'permission': permission.id,
          if (domainId != null &&
              permission == ResendApiKeyPermission.sendingAccess)
            'domain_id': domainId
        }));

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendCreateApiKeyResponse result =
        ResendCreateApiKeyResponse.fromJson(body);
    return ResendResult<ResendCreateApiKeyResponse>.success(result);
  }

  /// Retrieve a list of API keys for the authenticated user.
  Future<ResendResult<ResendListApiKeysResponse>> listApiKeys() async {
    // Construct the request URI
    final Uri uri =
        Uri(scheme: _baseUri.scheme, host: _baseUri.host, path: _baseUri.path);

    // Send GET request to the API
    final http.Response response = await http.get(uri,
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json'
        });

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendListApiKeysResponse result =
        ResendListApiKeysResponse.fromJson(body);
    return ResendResult<ResendListApiKeysResponse>.success(result);
  }

  /// Remove an existing API key.
  Future<ResendResult<ResendDeleteApiKeyResponse>> deleteApiKey(

      /// The API key ID.
      String apiKeyId) async {
    // Validation
    assert(apiKeyId.isNotEmpty, 'The API Key ID can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$apiKeyId');

    // Send GET request to the API
    final http.Response response = await http.delete(uri,
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json'
        });

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendDeleteApiKeyResponse result =
        ResendDeleteApiKeyResponse.fromJson(body);
    return ResendResult<ResendDeleteApiKeyResponse>.success(result);
  }
}
