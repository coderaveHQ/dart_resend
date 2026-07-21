import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/resources/templates.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../support/mock_transport.dart';

/// Registers this file's test cases with the package:test runner.
void main() {
  // Verifies: template variable inputs validate every documented type.
  test('template variable inputs validate every documented type', () {
    final List<TemplateVariableInput> variables = <TemplateVariableInput>[
      TemplateVariableInput(
        key: 'STRING',
        type: TemplateVariableType.string,
        fallbackValue: 'value',
      ),
      TemplateVariableInput(
        key: 'NUMBER',
        type: TemplateVariableType.number,
        fallbackValue: 1,
      ),
      TemplateVariableInput(
        key: 'BOOLEAN',
        type: TemplateVariableType.boolean,
        fallbackValue: true,
      ),
      TemplateVariableInput(
        key: 'OBJECT',
        type: TemplateVariableType.object,
        fallbackValue: <String, Object?>{'key': 'value'},
      ),
      TemplateVariableInput(
        key: 'LIST',
        type: TemplateVariableType.list,
        fallbackValue: <Object?>['value'],
      ),
    ];
    expect(
      TemplateVariableType.values.map(
        (TemplateVariableType type) => type.value,
      ),
      <String>['string', 'number', 'boolean', 'object', 'list'],
    );
    expect(variables.first.toJson(), <String, Object?>{
      'key': 'STRING',
      'type': 'string',
      'fallback_value': 'value',
    });
    expect(
      TemplateVariableInput(
        key: 'OPTIONAL',
        type: TemplateVariableType.string,
      ).toJson(),
      <String, Object?>{'key': 'OPTIONAL', 'type': 'string'},
    );
    for (final (TemplateVariableType, Object) invalid
        in <(TemplateVariableType, Object)>[
          (TemplateVariableType.string, 1),
          (TemplateVariableType.number, '1'),
          (TemplateVariableType.boolean, 'true'),
          (TemplateVariableType.object, <Object?>[]),
          (TemplateVariableType.list, <String, Object?>{}),
        ]) {
      expect(
        () => TemplateVariableInput(
          key: 'INVALID',
          type: invalid.$1,
          fallbackValue: invalid.$2,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => TemplateVariableInput(key: ' ', type: TemplateVariableType.string),
      throwsArgumentError,
    );
  });

  // Verifies: template create and update requests serialize every field.
  test('template create and update requests serialize every field', () {
    final TemplateVariableInput variable = TemplateVariableInput(
      key: 'NAME',
      type: TemplateVariableType.string,
      fallbackValue: 'friend',
    );
    final CreateTemplateRequest create = CreateTemplateRequest(
      name: 'Welcome',
      html: '<p>Hello {{{NAME}}}</p>',
      alias: 'welcome',
      from: 'Acme <hello@example.com>',
      subject: 'Hello',
      replyTo: <String>['reply@example.com'],
      text: 'Hello {{{NAME}}}',
      variables: <TemplateVariableInput>[variable],
    );
    expect(create.toJson(), <String, Object?>{
      'name': 'Welcome',
      'html': '<p>Hello {{{NAME}}}</p>',
      'alias': 'welcome',
      'from': 'Acme <hello@example.com>',
      'subject': 'Hello',
      'reply_to': <String>['reply@example.com'],
      'text': 'Hello {{{NAME}}}',
      'variables': <Object?>[
        <String, Object?>{
          'key': 'NAME',
          'type': 'string',
          'fallback_value': 'friend',
        },
      ],
    });
    final UpdateTemplateRequest update = UpdateTemplateRequest(
      name: 'Welcome 2',
      alias: 'welcome-2',
      from: 'hello@example.com',
      subject: 'Hi',
      replyTo: <String>['reply@example.com'],
      html: '<p>Hi</p>',
      text: 'Hi',
      variables: <TemplateVariableInput>[variable],
    );
    expect(update.toJson()['name'], 'Welcome 2');
    expect(update.toJson()['variables'], isNotEmpty);
    expect(
      CreateTemplateRequest(name: 'Minimal', html: '<p>Hi</p>').toJson(),
      <String, Object?>{'name': 'Minimal', 'html': '<p>Hi</p>'},
    );
  });

  // Verifies: template requests reject empty content and invalid update sets.
  test('template requests reject empty content and invalid update sets', () {
    expect(
      () => CreateTemplateRequest(name: ' ', html: '<p>Hi</p>'),
      throwsArgumentError,
    );
    expect(
      () => CreateTemplateRequest(name: 'Empty', html: ''),
      throwsArgumentError,
    );
    expect(
      () => CreateTemplateRequest(
        name: 'Too many',
        html: '<p>Hi</p>',
        variables: List<TemplateVariableInput>.generate(
          51,
          (int index) => TemplateVariableInput(
            key: 'KEY_$index',
            type: TemplateVariableType.string,
          ),
        ),
      ),
      throwsRangeError,
    );
    expect(() => UpdateTemplateRequest(), throwsArgumentError);
  });

  // Verifies: template response exposes full and summary representations.
  test('template response exposes full and summary representations', () {
    final ResendTemplate template = ResendTemplate.fromJson(_templateJson);
    expect(template.id, 'tpl_1');
    expect(template.currentVersionId, 'ver_1');
    expect(template.name, 'Welcome');
    expect(template.alias, 'welcome');
    expect(template.from, 'hello@example.com');
    expect(template.subject, 'Hello');
    expect(template.replyTo, <String>['reply@example.com']);
    expect(template.html, '<p>Hello</p>');
    expect(template.text, 'Hello');
    expect(template.createdAt, DateTime.utc(2026, 7, 20, 10));
    expect(template.updatedAt, DateTime.utc(2026, 7, 20, 11));
    expect(template.status, 'published');
    expect(template.publishedAt, DateTime.utc(2026, 7, 20, 11));
    expect(template.hasUnpublishedVersions, isTrue);

    final TemplateVariable variable = template.variables.single;
    expect(variable.id, 'var_1');
    expect(variable.key, 'NAME');
    expect(variable.type, 'string');
    expect(variable.fallbackValue, 'friend');
    expect(variable.createdAt, DateTime.utc(2026, 7, 20, 10));
    expect(variable.updatedAt, DateTime.utc(2026, 7, 20, 11));

    final ResendTemplate summary = ResendTemplate.fromJson(<String, Object?>{
      'id': 'tpl_2',
      'name': 'Summary',
      'status': 'draft',
      'created_at': '2026-07-20T10:00:00Z',
      'updated_at': '2026-07-20T11:00:00Z',
      'published_at': null,
    });
    expect(summary.currentVersionId, isNull);
    expect(summary.alias, isNull);
    expect(summary.from, isNull);
    expect(summary.subject, isNull);
    expect(summary.replyTo, isNull);
    expect(summary.html, isNull);
    expect(summary.text, isNull);
    expect(summary.variables, isEmpty);
    expect(summary.publishedAt, isNull);
    expect(summary.hasUnpublishedVersions, isFalse);
    expect(
      () => ResendTemplate.fromJson(<String, Object?>{
        ..._templateJson,
        'variables': <Object?>[1],
      }).variables,
      throwsFormatException,
    );
    final TemplateVariable minimalVariable = TemplateVariable.fromJson(
      <String, Object?>{'key': 'NAME', 'type': 'string'},
    );
    expect(minimalVariable.id, isNull);
    expect(minimalVariable.fallbackValue, isNull);
    expect(minimalVariable.createdAt, isNull);
    expect(minimalVariable.updatedAt, isNull);
  });

  // Verifies: templates resource covers every endpoint.
  test('templates resource covers every endpoint', () async {
    var call = 0;
    final TemplatesResource resource = TemplatesResource(
      mockTransport((http.Request request) async {
        call++;
        switch (call) {
          case 1:
            expect(request.method, 'POST');
            expect(request.url.path, '/v1/templates');
            return jsonResponse(<String, Object?>{
              'object': 'template',
              'id': 'tpl_1',
            }, statusCode: 201);
          case 2:
            expect(request.url.queryParameters, <String, String>{'limit': '1'});
            return jsonResponse(<String, Object?>{
              'object': 'list',
              'has_more': false,
              'data': <Object?>[_templateJson],
            });
          case 3:
            expect(request.url.path, '/v1/templates/welcome%2Falias');
            return jsonResponse(_templateJson);
          case 4:
            expect(request.method, 'PATCH');
            expect(decodedBody(request), <String, Object?>{'name': 'Updated'});
            return jsonResponse(<String, Object?>{
              'object': 'template',
              'id': 'tpl_1',
            });
          case 5:
            expect(request.method, 'DELETE');
            return jsonResponse(<String, Object?>{
              'object': 'template',
              'id': 'tpl_1',
              'deleted': true,
            });
          case 6:
            expect(request.url.path, '/v1/templates/tpl_1/publish');
            return jsonResponse(<String, Object?>{
              'object': 'template',
              'id': 'tpl_1',
            });
          default:
            expect(request.url.path, '/v1/templates/tpl_1/duplicate');
            return jsonResponse(<String, Object?>{
              'object': 'template',
              'id': 'tpl_2',
            });
        }
      }),
    );

    expect(
      (await resource.create(
        CreateTemplateRequest(name: 'Welcome', html: '<p>Hello</p>'),
      )).data.id,
      'tpl_1',
    );
    expect(
      (await resource.list(
        pagination: PaginationOptions(limit: 1),
      )).data.data.single.name,
      'Welcome',
    );
    expect((await resource.retrieve('welcome/alias')).data.id, 'tpl_1');
    expect(
      (await resource.update(
        'tpl_1',
        UpdateTemplateRequest(name: 'Updated'),
      )).data.id,
      'tpl_1',
    );
    expect((await resource.delete('tpl_1')).data.deleted, isTrue);
    expect((await resource.publish('tpl_1')).data.id, 'tpl_1');
    expect((await resource.duplicate('tpl_1')).data.id, 'tpl_2');

    expect(() => resource.retrieve(' '), throwsArgumentError);
    expect(
      () => resource.update(' ', UpdateTemplateRequest(name: 'x')),
      throwsArgumentError,
    );
    expect(() => resource.delete(' '), throwsArgumentError);
    expect(() => resource.publish(' '), throwsArgumentError);
    expect(() => resource.duplicate(' '), throwsArgumentError);
  });
}

const Map<String, Object?> _templateJson = <String, Object?>{
  'object': 'template',
  'id': 'tpl_1',
  'current_version_id': 'ver_1',
  'name': 'Welcome',
  'alias': 'welcome',
  'from': 'hello@example.com',
  'subject': 'Hello',
  'reply_to': <String>['reply@example.com'],
  'html': '<p>Hello</p>',
  'text': 'Hello',
  'variables': <Object?>[
    <String, Object?>{
      'id': 'var_1',
      'key': 'NAME',
      'type': 'string',
      'fallback_value': 'friend',
      'created_at': '2026-07-20T10:00:00Z',
      'updated_at': '2026-07-20T11:00:00Z',
    },
  ],
  'created_at': '2026-07-20T10:00:00Z',
  'updated_at': '2026-07-20T11:00:00Z',
  'status': 'published',
  'published_at': '2026-07-20T11:00:00Z',
  'has_unpublished_versions': true,
};
