/// Enum for all possible errors by Resend
enum ResendError {
  /// missing required field
  missingRequiredField(
      'missing_required_field',
      422,
      'The request body is missing one or more required fields.',
      'Check the error message to see the list of missing fields.'),

  /// invalid attachment
  invalidAttachment(
      'invalid_attachment',
      422,
      'Attachment must have either a `content` or `path`.',
      'Attachments must either have a `content` (strings, Buffer, or Stream contents) or `path` to a remote resource (better for larger attachments).'),

  /// missing API key
  missingApiKey(
      'missing_api_key',
      401,
      'Missing API key in the authorization header.',
      'Include the following header `Authorization: Bearer YOUR_API_KEY` in the request.'),

  /// invalid API key
  invalidApiKey('invalid_api_key', 403, 'The API key is not valid.',
      'Generate a new API key in the dashboard.'),

  /// invalid from address
  invalidFromAddress(
      'invalid_from_address',
      403,
      'The `from` address is not valid.',
      'Review your existing domains in the dashboard.'),

  /// invalid to address
  invalidToAddress(
      'invalid_to_address',
      403,
      'You can only send testing emails to your own email address.',
      'In order to send emails to any external address, you need to add a domain and use that as the `from` address instead of `onboarding@resend.dev.`'),

  /// not found
  notFound('not_found', 404, 'The requested endpoint does not exist.',
      'Change your request URL to match a valid API endpoint.'),

  /// method not allowed
  methodNotAllowed(
      'method_not_allowed',
      405,
      'This endpoint does not support the specified HTTP method.',
      'Change the HTTP method to follow the documentation for the endpoint.'),

  /// invalid scope
  invalidScope(
      'invalid_scope',
      422,
      'This endpoint does not support the specified scope.',
      'Change the scope to follow the documentation for the endpoint.'),

  /// rate limit exceeded
  rateLimitExceeded(
      'rate_limit_exceeded',
      429,
      'Too many requests. Please limit the number of requests per second. Or contact support to increase rate limit.',
      'You should read the response headers and reduce the rate at which you request the API. This can be done by introducing a queue mechanism or reducing the number of concurrent requests per second. If you have specific requirements, contact support to request a rate increase.'),

  /// daily quota exceeded
  dailyQuotaExceeded(
      'daily_quota_exceeded',
      429,
      'You have reached your daily email sending quota.',
      'Upgrade your plan to remove daily quota limit or wait until 24 hours have passed to continue sending.'),

  /// internal server error
  internalServerError(
      'internal_server_error',
      500,
      'An unexpected error occurred.',
      'Try the request again later. If the error does not resolve, check our status page for service updates.');

  /// The id of the error
  final String id;

  /// The status code of the error
  final int statusCode;

  /// The message by Resend
  final String message;

  /// The suggested action by Resend
  final String suggestedAction;

  /// Constructor of ResendError
  const ResendError(
      this.id, this.statusCode, this.message, this.suggestedAction);

  /// Method to get ResendError from an ID
  static ResendError? fromId(String value) {
    try {
      return ResendError.values.firstWhere((e) => e.id == value);
    } catch (_) {
      return null;
    }
  }
}
