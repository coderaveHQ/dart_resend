import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:dart_resend/src/features/contacts/models/resend_add_contact_response.dart';
import 'package:dart_resend/src/features/contacts/models/resend_delete_contact_response.dart';
import 'package:dart_resend/src/features/contacts/models/resend_list_contacts_response.dart';
import 'package:dart_resend/src/features/contacts/models/resend_retrieve_contact_response.dart';
import 'package:dart_resend/src/features/contacts/models/resend_update_contact_response.dart';
import 'package:dart_resend/src/utils/resend_result.dart';
import 'package:dart_resend/src/utils/typedefs.dart';

/// The client for the Resend Contacts API
class ResendContactsClient {
  /// API Key for API authentication
  final String _apiKey;

  /// Base URI for the Resend Contacts API
  final Uri _baseUri = Uri.parse('https://api.resend.com/audiences');

  /// Constructor of ResendContactsClient
  ResendContactsClient({
    required String apiKey,
  }) : _apiKey = apiKey;

  /// Create a contact inside an audience.
  Future<ResendResult<ResendAddContactResponse>> addContact(
      {
      /// The Audience ID.
      required String audienceId,

      /// The email address of the contact.
      required String email,

      /// The first name of the contact.
      String? firstName,

      /// The last name of the contact.
      String? lastName,

      /// The subscription status.
      bool? unsubscribed}) async {
    // Validation
    assert(audienceId.isNotEmpty, 'The audience ID can not be empty.');
    assert(email.isNotEmpty, 'The audience E-Mail can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$audienceId/contacts');

    // Send GET request to the API
    final http.Response response = await http.post(uri,
        headers: <String, String>{'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode(<String, dynamic>{
          'email': email,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (unsubscribed != null) 'unsubscribed': unsubscribed
        }));

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendAddContactResponse result =
        ResendAddContactResponse.fromJson(body);
    return ResendResult<ResendAddContactResponse>.success(result);
  }

  /// Retrieve a single contact from an audience.
  Future<ResendResult<ResendRetrieveContactResponse>> retrieveContact(
      {
      /// The Audience ID.
      required String audienceId,

      /// The Contact ID.
      required String contactId}) async {
    // Validation
    assert(audienceId.isNotEmpty, 'The audience ID can not be empty.');
    assert(contactId.isNotEmpty, 'The contact ID can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$audienceId/contacts/$contactId');

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
    final ResendRetrieveContactResponse result =
        ResendRetrieveContactResponse.fromJson(body);
    return ResendResult<ResendRetrieveContactResponse>.success(result);
  }

  /// Update an existing contact.
  Future<ResendResult<ResendUpdateContactResponse>> updateContact(
      {
      /// The Audience ID.
      required String audienceId,

      /// The Contact ID.
      required String contactId,

      /// The first name of the contact.
      String? firstName,

      /// The last name of the contact.
      String? lastName,

      /// The subscription status.
      bool? unsubscribed}) async {
    // Validation
    assert(audienceId.isNotEmpty, 'The audience ID can not be empty.');
    assert(contactId.isNotEmpty, 'The contact ID can not be empty.');
    assert(firstName != null || lastName != null || unsubscribed != null,
        'At least one optional parameter is required.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$audienceId/contacts/$contactId');

    // Send GET request to the API
    final http.Response response = await http.patch(uri,
        headers: <String, String>{'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode(<String, dynamic>{
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (unsubscribed != null) 'unsubscribed': unsubscribed
        }));

    // Decode the response
    final Json body = json.decode(response.body);

    // Return Failure when statusCode is not OK
    if (response.statusCode != 200) {
      return ResendFailure.fromJson(body);
    }

    // Return parsed data when statusCode is OK
    final ResendUpdateContactResponse result =
        ResendUpdateContactResponse.fromJson(body);
    return ResendResult<ResendUpdateContactResponse>.success(result);
  }

  /// Remove an existing contact from an audience by ID
  Future<ResendResult<ResendDeleteContactResponse>> deleteContactById(
      {
      /// The Audience ID.
      required String audienceId,

      /// The Contact ID.
      required String contactId}) async {
    // Validation
    assert(audienceId.isNotEmpty, 'The audience ID can not be empty.');
    assert(contactId.isNotEmpty, 'The contact ID can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$audienceId/contacts/$contactId');

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
    final ResendDeleteContactResponse result =
        ResendDeleteContactResponse.fromJson(body);
    return ResendResult<ResendDeleteContactResponse>.success(result);
  }

  /// Remove an existing contact from an audience by email
  Future<ResendResult<ResendDeleteContactResponse>> deleteContactByEmail(
      {
      /// The Audience ID.
      required String audienceId,

      /// The Contact email.
      required String contactEmail}) async {
    // Validation
    assert(audienceId.isNotEmpty, 'The audience ID can not be empty.');
    assert(contactEmail.isNotEmpty, 'The contact E-Mail can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$audienceId/contacts/$contactEmail');

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
    final ResendDeleteContactResponse result =
        ResendDeleteContactResponse.fromJson(body);
    return ResendResult<ResendDeleteContactResponse>.success(result);
  }

  /// Show all contacts from an audience.
  Future<ResendResult<ResendListContactsResponse>> listContacts(
      String audienceId) async {
    // Validation
    assert(audienceId.isNotEmpty, 'The audience ID can not be empty.');

    // Construct the request URI
    final Uri uri = Uri(
        scheme: _baseUri.scheme,
        host: _baseUri.host,
        path: '${_baseUri.path}/$audienceId/contacts');

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
    final ResendListContactsResponse result =
        ResendListContactsResponse.fromJson(body);
    return ResendResult<ResendListContactsResponse>.success(result);
  }
}
