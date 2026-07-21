import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// A hosted-template variable type.
enum TemplateVariableType implements ResendWireValue {
  /// A string value.
  string('string'),

  /// A numeric value.
  number('number'),

  /// A boolean value.
  boolean('boolean'),

  /// A JSON object value.
  object('object'),

  /// A JSON array value.
  list('list');

  const TemplateVariableType(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// A variable declared by a hosted Resend template.
final class TemplateVariable extends ResendModel {
  /// Decodes a template variable.
  TemplateVariable.fromJson(super.json);

  /// The variable ID when returned by Resend.
  String? get id => optionalField<String>('id');

  /// Variable key referenced by the template.
  String get key => field<String>('key');

  /// Raw variable type, kept forward-compatible with new types.
  String get type => field<String>('type');

  /// Optional fallback value.
  Object? get fallbackValue => json['fallback_value'];

  /// When the variable was created, when returned.
  DateTime? get createdAt => optionalDateTimeField('created_at');

  /// When the variable was last updated, when returned.
  DateTime? get updatedAt => optionalDateTimeField('updated_at');
}

/// Declares a variable for a hosted template.
final class TemplateVariableInput implements ResendRequest {
  /// Creates a variable declaration.
  TemplateVariableInput({
    required String key,
    required this.type,
    this.fallbackValue,
  }) : key = requireNonBlank(key, 'key') {
    _validateFallback(type, fallbackValue);
  }

  /// Variable key referenced by the template.
  final String key;

  /// Expected variable value type.
  final TemplateVariableType type;

  /// Value used when a send request omits this variable.
  final Object? fallbackValue;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'key': key,
    'type': type.value,
    'fallback_value': fallbackValue,
  });
}

/// Parameters for creating a hosted template.
final class CreateTemplateRequest implements ResendRequest {
  /// Creates template parameters.
  CreateTemplateRequest({
    required String name,
    required this.html,
    this.alias,
    this.from,
    this.subject,
    List<String>? replyTo,
    this.text,
    List<TemplateVariableInput> variables = const <TemplateVariableInput>[],
  }) : name = requireNonBlank(name, 'name'),
       replyTo = replyTo == null ? null : List<String>.unmodifiable(replyTo),
       variables = _validatedVariables(variables) {
    if (html.isEmpty) {
      throw ArgumentError.value(html, 'html', 'Must not be empty.');
    }
  }

  /// Human-readable template name.
  final String name;

  /// HTML body.
  final String html;

  /// Optional unique alias.
  final String? alias;

  /// Default sender.
  final String? from;

  /// Default subject.
  final String? subject;

  /// Default reply-to addresses.
  final List<String>? replyTo;

  /// Optional plain-text body. An empty value disables automatic generation.
  final String? text;

  /// Declared template variables.
  final List<TemplateVariableInput> variables;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'name': name,
    'html': html,
    'alias': alias,
    'from': from,
    'subject': subject,
    'reply_to': replyTo,
    'text': text,
    if (variables.isNotEmpty)
      'variables': variables
          .map((TemplateVariableInput variable) => variable.toJson())
          .toList(),
  });
}

/// Parameters for updating a hosted template draft.
final class UpdateTemplateRequest implements ResendRequest {
  /// Creates template-update parameters.
  UpdateTemplateRequest({
    this.name,
    this.alias,
    this.from,
    this.subject,
    List<String>? replyTo,
    this.html,
    this.text,
    List<TemplateVariableInput>? variables,
  }) : replyTo = replyTo == null ? null : List<String>.unmodifiable(replyTo),
       variables = variables == null ? null : _validatedVariables(variables) {
    if (<Object?>[
      name,
      alias,
      from,
      subject,
      replyTo,
      html,
      text,
      variables,
    ].every((Object? value) => value == null)) {
      throw ArgumentError('At least one template field must be updated.');
    }
  }

  /// Updated template name.
  final String? name;

  /// Updated alias.
  final String? alias;

  /// Updated default sender.
  final String? from;

  /// Updated default subject.
  final String? subject;

  /// Updated reply-to addresses.
  final List<String>? replyTo;

  /// Updated HTML body.
  final String? html;

  /// Updated plain-text body.
  final String? text;

  /// Updated variable declarations.
  final List<TemplateVariableInput>? variables;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'name': name,
    'alias': alias,
    'from': from,
    'subject': subject,
    'reply_to': replyTo,
    'html': html,
    'text': text,
    'variables': variables
        ?.map((TemplateVariableInput variable) => variable.toJson())
        .toList(),
  });
}

/// A hosted Resend template or template list item.
final class ResendTemplate extends ResendModel {
  /// Decodes a template.
  ResendTemplate.fromJson(super.json);

  /// The template ID.
  String get id => field<String>('id');

  /// The currently published/draft version ID when returned.
  String? get currentVersionId => optionalField<String>('current_version_id');

  /// Human-readable template name.
  String get name => field<String>('name');

  /// Unique template alias, when configured.
  String? get alias => optionalField<String>('alias');

  /// Default sender, when configured.
  String? get from => optionalField<String>('from');

  /// Default subject, when configured.
  String? get subject => optionalField<String>('subject');

  /// Default reply-to addresses, when configured.
  List<String>? get replyTo => optionalListField<String>('reply_to');

  /// HTML body when returned by a retrieve operation.
  String? get html => optionalField<String>('html');

  /// Plain-text body when returned by a retrieve operation.
  String? get text => optionalField<String>('text');

  /// Declared variables when returned by a retrieve operation.
  List<TemplateVariable> get variables {
    final List<Object?> values =
        optionalListField<Object?>('variables') ?? const <Object?>[];
    return List<TemplateVariable>.unmodifiable(
      values.map(
        (Object? value) =>
            TemplateVariable.fromJson(_jsonObject(value, 'variables')),
      ),
    );
  }

  /// When the template was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// When the template was last updated.
  DateTime get updatedAt => dateTimeField('updated_at');

  /// Raw publication status.
  String get status => field<String>('status');

  /// When the current version was published.
  DateTime? get publishedAt => optionalDateTimeField('published_at');

  /// Whether a newer unpublished draft exists.
  bool get hasUnpublishedVersions =>
      optionalField<bool>('has_unpublished_versions') ?? false;
}

/// Operations for hosted email templates.
final class TemplatesResource {
  /// Creates a templates resource client.
  TemplatesResource(this._transport);

  /// Transport used to execute template endpoint requests.
  final ResendTransport _transport;

  /// Creates a template draft.
  Future<ResendResponse<ResendId>> create(CreateTemplateRequest request) {
    return _transport.post<ResendId>(
      pathSegments: <String>['templates'],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Lists templates.
  Future<ResendResponse<ResendPage<ResendTemplate>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<ResendTemplate>>(
      pathSegments: <String>['templates'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<ResendTemplate>.fromJson(json, ResendTemplate.fromJson),
    );
  }

  /// Retrieves a template by ID or alias.
  Future<ResendResponse<ResendTemplate>> retrieve(String idOrAlias) {
    return _transport.get<ResendTemplate>(
      pathSegments: <String>[
        'templates',
        requireNonBlank(idOrAlias, 'idOrAlias'),
      ],
      decode: ResendTemplate.fromJson,
    );
  }

  /// Updates a template draft by ID or alias.
  Future<ResendResponse<ResendId>> update(
    String idOrAlias,
    UpdateTemplateRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>[
        'templates',
        requireNonBlank(idOrAlias, 'idOrAlias'),
      ],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Deletes a template by ID or alias.
  Future<ResendResponse<ResendDeletion>> delete(String idOrAlias) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>[
        'templates',
        requireNonBlank(idOrAlias, 'idOrAlias'),
      ],
      decode: ResendDeletion.fromJson,
    );
  }

  /// Publishes the current template draft.
  Future<ResendResponse<ResendId>> publish(String idOrAlias) {
    return _transport.post<ResendId>(
      pathSegments: <String>[
        'templates',
        requireNonBlank(idOrAlias, 'idOrAlias'),
        'publish',
      ],
      decode: ResendId.fromJson,
    );
  }

  /// Duplicates a template.
  Future<ResendResponse<ResendId>> duplicate(String idOrAlias) {
    return _transport.post<ResendId>(
      pathSegments: <String>[
        'templates',
        requireNonBlank(idOrAlias, 'idOrAlias'),
        'duplicate',
      ],
      decode: ResendId.fromJson,
    );
  }
}

/// Enforces that a template fallback matches its declared variable [type].
void _validateFallback(TemplateVariableType type, Object? value) {
  if (value == null) return;
  final bool valid = switch (type) {
    TemplateVariableType.string => value is String,
    TemplateVariableType.number => value is num,
    TemplateVariableType.boolean => value is bool,
    TemplateVariableType.object => value is Map<Object?, Object?>,
    TemplateVariableType.list => value is List<Object?>,
  };
  if (!valid) {
    throw ArgumentError.value(value, 'fallbackValue', 'Does not match $type.');
  }
}

/// Validates, copies, and freezes template variable definitions.
List<TemplateVariableInput> _validatedVariables(
  List<TemplateVariableInput> variables,
) {
  if (variables.length > 50) {
    throw RangeError.range(variables.length, 0, 50, 'variables.length');
  }
  return List<TemplateVariableInput>.unmodifiable(variables);
}

/// Validates and freezes one JSON object decoded within [name].
JsonObject _jsonObject(Object? value, String name) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Expected every $name item to be a JSON object.');
}
