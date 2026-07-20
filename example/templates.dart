import 'package:dart_resend/dart_resend.dart';

/// Creates a template draft with every supported variable type.
Future<ResendResponse<ResendId>> createTemplate(Resend resend) {
  return resend.templates.create(
    CreateTemplateRequest(
      name: 'Welcome email',
      alias: 'welcome-email',
      from: 'Acme <onboarding@example.com>',
      subject: 'Welcome, {{{first_name}}}!',
      replyTo: <String>['support@example.com'],
      html: '<h1>Welcome, {{{first_name}}}!</h1>',
      text: 'Welcome, {{{first_name}}}!',
      variables: <TemplateVariableInput>[
        TemplateVariableInput(
          key: 'first_name',
          type: TemplateVariableType.string,
          fallbackValue: 'there',
        ),
        TemplateVariableInput(
          key: 'login_count',
          type: TemplateVariableType.number,
          fallbackValue: 0,
        ),
        TemplateVariableInput(
          key: 'verified',
          type: TemplateVariableType.boolean,
          fallbackValue: false,
        ),
        TemplateVariableInput(
          key: 'account',
          type: TemplateVariableType.object,
          fallbackValue: <String, Object?>{'plan': 'free'},
        ),
        TemplateVariableInput(
          key: 'features',
          type: TemplateVariableType.list,
          fallbackValue: <Object?>[],
        ),
      ],
    ),
  );
}

/// Lists hosted templates.
Future<ResendResponse<ResendPage<ResendTemplate>>> listTemplates(
  Resend resend,
) {
  return resend.templates.list(pagination: PaginationOptions(limit: 25));
}

/// Retrieves a template by ID or alias.
Future<ResendResponse<ResendTemplate>> retrieveTemplate(
  Resend resend,
  String idOrAlias,
) {
  return resend.templates.retrieve(idOrAlias);
}

/// Updates the current template draft.
Future<ResendResponse<ResendId>> updateTemplate(
  Resend resend,
  String idOrAlias,
) {
  return resend.templates.update(
    idOrAlias,
    UpdateTemplateRequest(
      subject: 'Welcome to Acme, {{{first_name}}}!',
      html: '<h1>Welcome to Acme, {{{first_name}}}!</h1>',
      text: 'Welcome to Acme, {{{first_name}}}!',
    ),
  );
}

/// Publishes the current template draft.
Future<ResendResponse<ResendId>> publishTemplate(
  Resend resend,
  String idOrAlias,
) {
  return resend.templates.publish(idOrAlias);
}

/// Duplicates a template.
Future<ResendResponse<ResendId>> duplicateTemplate(
  Resend resend,
  String idOrAlias,
) {
  return resend.templates.duplicate(idOrAlias);
}

/// Deletes a hosted template.
Future<ResendResponse<ResendDeletion>> deleteTemplate(
  Resend resend,
  String idOrAlias,
) {
  return resend.templates.delete(idOrAlias);
}
