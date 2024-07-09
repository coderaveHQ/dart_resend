/// API key permission
enum ResendApiKeyPermission {
  /// The API key can have full access to Resend’s API or be only restricted to send emails. * full_access: Can create, delete, get, and update any resource. * sending_access: Can only send emails.
  fullAccess('full_access'),

  /// Restrict an API key to send emails only from a specific domain.
  sendingAccess('sending_access');

  /// The ID of the permission
  final String id;

  /// Constructor of ResendApiKeyPermission
  const ResendApiKeyPermission(this.id);
}
