import 'package:dart_resend/src/features/audiences/resend_audiences_client.dart';
import 'package:dart_resend/src/features/contacts/resend_contacts_client.dart';
import 'package:dart_resend/src/features/domains/resend_domains_client.dart';
import 'package:dart_resend/src/features/email/resend_email_client.dart';
import 'package:dart_resend/src/features/api_keys/resend_api_keys_client.dart';

/// A class holding the clients for the Resend API
class ResendClient {
  /// Client for email functionalities
  late final ResendEmailClient email;

  /// Client for domains functionalities
  late final ResendDomainsClient domains;

  /// Client for api keys functionalities
  late final ResendApiKeysClient apiKeys;

  /// Client for audiences functionalities
  late final ResendAudiencesClient audiences;

  /// Client for contacts functionalities
  late final ResendContactsClient contacts;

  /// Constructor to initialize the clients with the API Key
  ResendClient({required String apiKey}) {
    email = _initResendEmailClient(apiKey: apiKey);
    domains = _initResendDomainsClient(apiKey: apiKey);
    apiKeys = _initResendApiKeysClient(apiKey: apiKey);
    audiences = _initResendAudiencesClient(apiKey: apiKey);
    contacts = _initResendContactsClient(apiKey: apiKey);
  }

  /// Initialize the email client
  ResendEmailClient _initResendEmailClient({required String apiKey}) {
    return ResendEmailClient(apiKey: apiKey);
  }

  /// Initialize the domains client
  ResendDomainsClient _initResendDomainsClient({required String apiKey}) {
    return ResendDomainsClient(apiKey: apiKey);
  }

  /// Initialize the api keys client
  ResendApiKeysClient _initResendApiKeysClient({required String apiKey}) {
    return ResendApiKeysClient(apiKey: apiKey);
  }

  /// Initialize the audiences client
  ResendAudiencesClient _initResendAudiencesClient({required String apiKey}) {
    return ResendAudiencesClient(apiKey: apiKey);
  }

  /// Initialize the contacts client
  ResendContactsClient _initResendContactsClient({required String apiKey}) {
    return ResendContactsClient(apiKey: apiKey);
  }
}
