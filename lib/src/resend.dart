import 'package:dart_resend/src/resend_client.dart';

/// A class for holding the client that separates the clients for the Resend API
class Resend {
  /// Singleton instance of Resend
  static Resend get instance {
    // Ensure the instance is initialized before returning it
    assert(_instance._initialized,
        'You must initialize the Resend instance before calling Resend.instance.');
    return _instance;
  }

  /// Initialize the Resend instance with the API Key
  static Resend initialize({required String apiKey}) {
    // Ensure the instance is not already initialized
    assert(!_instance._initialized, 'This instance is already initialized.');
    // Initialize the instance with the provided access token
    _instance._init(apiKey: apiKey);

    return _instance;
  }

  /// Private constructor to prevent direct instantiation
  Resend._();

  /// Static singleton instance
  static final Resend _instance = Resend._();

  /// Flag to indicate if the instance has been initialized
  bool _initialized = false;

  /// Client for interacting with Resend API
  late ResendClient client;

  /// Dispose the instance, resetting the initialization flag
  void dispose() {
    _initialized = false;
  }

  /// Initialize the client with the API Key
  void _init({required String apiKey}) {
    client = ResendClient(apiKey: apiKey);

    _initialized = true;
  }
}
