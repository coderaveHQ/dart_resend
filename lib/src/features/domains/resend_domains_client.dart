import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:dart_resend/src/utils/resend_result.dart';
import 'package:dart_resend/src/features/domains/models/resend_add_domain_response.dart';
import 'package:dart_resend/src/features/domains/models/resend_delete_domain_response.dart';
import 'package:dart_resend/src/features/domains/models/resend_list_domains_response.dart';
import 'package:dart_resend/src/features/domains/models/resend_retrieve_domain_response.dart';
import 'package:dart_resend/src/features/domains/models/resend_update_domain_response.dart';
import 'package:dart_resend/src/features/domains/models/resend_verify_domain_response.dart';
import 'package:dart_resend/src/features/domains/enums/resend_domain_region.dart';
import 'package:dart_resend/src/features/domains/enums/resend_domain_tls.dart';
import 'package:dart_resend/src/utils/typedefs.dart';

/// The client for the Resend Domains API
class ResendDomainsClient {
  /// API Key for API authentication
  final String _apiKey;

  /// Base URI for the Resend Domains API
  final Uri _baseUri = Uri.parse('https://api.resend.com/domains');

  /// Constructor of ResendDomainsClient
  ResendDomainsClient({
    required String apiKey,
  }) : _apiKey = apiKey;

  /// Create a domain through the Resend Email API.
  Future<ResendResult<ResendAddDomainResponse>> addDomain(

      /// The name of the domain you want to create.
      String name,
      {
      /// The region where emails will be sent from. Possible values: us-east-1' | 'eu-west-1' | 'sa-east-1' | 'ap-northeast-1'
      ResendDomainRegion? region}) async {
    // Validation
    assert(name.isNotEmpty, 'The domain name can not be empty.');

    // Construct the request URI
    final Uri uri =
        Uri(scheme: _baseUri.scheme, host: _baseUri.host, path: _baseUri.path);

    // Send GET request to the API
    final http.Response response = await http.post(uri,
        headers: <String, String>{'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode(<String, dynamic>{
          'name': name,
          if (region != null) 'region': region.id
        }));

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendAddDomainResponse result =
        ResendAddDomainResponse.fromJson(body);
    return ResendResult<ResendAddDomainResponse>.success(result);
  }

  /// Retrieve a single domain for the authenticated user.
  Future<ResendResult<ResendRetrieveDomainResponse>> retrieveDomain(

      /// The Domain ID.
      String domainId) async {
    // Validation
    assert(domainId.isNotEmpty, 'The domain ID can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$domainId');

    // Send GET request to the API
    final http.Response response = await http.get(uri,
        headers: <String, String>{'Authorization': 'Bearer $_apiKey'});

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendRetrieveDomainResponse result =
        ResendRetrieveDomainResponse.fromJson(body);
    return ResendResult<ResendRetrieveDomainResponse>.success(result);
  }

  /// Verify an existing domain.
  Future<ResendResult<ResendVerifyDomainResponse>> verifyDomain(

      /// The Domain ID.
      String domainId) async {
    // Validation
    assert(domainId.isNotEmpty, 'The domain ID can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$domainId');

    // Send GET request to the API
    final http.Response response = await http.post(uri,
        headers: <String, String>{'Authorization': 'Bearer $_apiKey'});

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendVerifyDomainResponse result =
        ResendVerifyDomainResponse.fromJson(body);
    return ResendResult<ResendVerifyDomainResponse>.success(result);
  }

  /// Update an existing domain.
  Future<ResendResult<ResendUpdateDomainResponse>> updateDomain(

      /// The Domain ID.
      String domainId,
      {
      /// Track clicks within the body of each HTML email.
      bool? clickTracking,

      /// Track the open rate of each email.
      bool? openTracking,

      /// - opportunistic: Opportunistic TLS means that it always attempts to make a secure connection to the receiving mail server. If it can’t establish a secure connection, it sends the message unencrypted.
      /// - enforced: Enforced TLS on the other hand, requires that the email communication must use TLS no matter what. If the receiving server does not support TLS, the email will not be sent.
      ResendDomainTls? tls}) async {
    // Validation
    assert(domainId.isNotEmpty, 'The domain ID can not be empty.');
    assert(clickTracking != null || openTracking != null || tls != null,
        'At least one optional parameter is required.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$domainId');

    // Send GET request to the API
    final http.Response response = await http.patch(uri,
        headers: <String, String>{'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode(<String, dynamic>{
          if (clickTracking != null) 'click_tracking': clickTracking,
          if (openTracking != null) 'open_tracking': openTracking,
          if (tls != null) 'tls': tls.id
        }));

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendUpdateDomainResponse result =
        ResendUpdateDomainResponse.fromJson(body);
    return ResendResult<ResendUpdateDomainResponse>.success(result);
  }

  /// Retrieve a list of domains for the authenticated user.
  Future<ResendResult<ResendListDomainsResponse>> listDomains() async {
    // Construct the request URI
    final Uri uri =
        Uri(scheme: _baseUri.scheme, host: _baseUri.host, path: _baseUri.path);

    // Send GET request to the API
    final http.Response response = await http.get(uri,
        headers: <String, String>{'Authorization': 'Bearer $_apiKey'});

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendListDomainsResponse result =
        ResendListDomainsResponse.fromJson(body);
    return ResendResult<ResendListDomainsResponse>.success(result);
  }

  /// Remove an existing domain.
  Future<ResendResult<ResendDeleteDomainResponse>> deleteDomain(

      /// The Domain ID.
      String domainId) async {
    // Validation
    assert(domainId.isNotEmpty, 'The domain ID can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$domainId');

    // Send GET request to the API
    final http.Response response = await http.delete(uri,
        headers: <String, String>{'Authorization': 'Bearer $_apiKey'});

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendDeleteDomainResponse result =
        ResendDeleteDomainResponse.fromJson(body);
    return ResendResult<ResendDeleteDomainResponse>.success(result);
  }
}
