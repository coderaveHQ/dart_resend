import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:dart_resend/src/features/audiences/models/resend_add_audience_response.dart';
import 'package:dart_resend/src/features/audiences/models/resend_delete_audience_response.dart';
import 'package:dart_resend/src/features/audiences/models/resend_list_audiences_response.dart';
import 'package:dart_resend/src/features/audiences/models/resend_retrieve_audience_response.dart';
import 'package:dart_resend/src/utils/resend_result.dart';
import 'package:dart_resend/src/utils/typedefs.dart';

/// The client for the Resend Audiences API
class ResendAudiencesClient {
  /// API Key for API authentication
  final String _apiKey;

  /// Base URI for the Resend Audiences API
  final Uri _baseUri = Uri.parse('https://api.resend.com/audiences');

  /// Constructor of ResendAudiencesClient
  ResendAudiencesClient({
    required String apiKey,
  }) : _apiKey = apiKey;

  /// Create a list of contacts.
  Future<ResendResult<ResendAddAudienceResponse>> addAudience(

      /// The name of the audience you want to create.
      String name) async {
    // Validation
    assert(name.isNotEmpty, 'The audience name can not be empty.');

    // Construct the request URI
    final Uri uri =
        Uri(scheme: _baseUri.scheme, host: _baseUri.host, path: _baseUri.path);

    // Send GET request to the API
    final http.Response response = await http.post(uri,
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(<String, dynamic>{'name': name}));

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendAddAudienceResponse result =
        ResendAddAudienceResponse.fromJson(body);
    return ResendResult<ResendAddAudienceResponse>.success(result);
  }

  /// Retrieve a single audience.
  Future<ResendResult<ResendRetrieveAudienceResponse>> retrieveAudience(

      /// The Audience ID.
      String audienceId) async {
    // Validation
    assert(audienceId.isNotEmpty, 'The audience ID can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$audienceId');

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
    final ResendRetrieveAudienceResponse result =
        ResendRetrieveAudienceResponse.fromJson(body);
    return ResendResult<ResendRetrieveAudienceResponse>.success(result);
  }

  /// Remove an existing audience.
  Future<ResendResult<ResendDeleteAudienceResponse>> deleteAudience(

      /// The Audience ID.
      String audienceId) async {
    // Validation
    assert(audienceId.isNotEmpty, 'The audience ID can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$audienceId');

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
    final ResendDeleteAudienceResponse result =
        ResendDeleteAudienceResponse.fromJson(body);
    return ResendResult<ResendDeleteAudienceResponse>.success(result);
  }

  /// Retrieve a list of audiences.
  Future<ResendResult<ResendListAudiencesResponse>> listAudiences() async {
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
    final ResendListAudiencesResponse result =
        ResendListAudiencesResponse.fromJson(body);
    return ResendResult<ResendListAudiencesResponse>.success(result);
  }
}
