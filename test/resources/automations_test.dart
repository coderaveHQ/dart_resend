import 'dart:convert';

import 'package:dart_resend/src/core/pagination.dart';
import 'package:dart_resend/src/core/transport.dart';
import 'package:dart_resend/src/models/base.dart';
import 'package:dart_resend/src/resources/automations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Registers this file's test cases with the package:test runner.
void main() {
  // Covers: automation wire enums.
  group('automation wire enums', () {
    // Verifies: serialize every documented value.
    test('serialize every documented value', () {
      expect(
        AutomationStatus.values.map((AutomationStatus value) => value.value),
        <String>['enabled', 'disabled'],
      );
      expect(
        AutomationRunStatus.values.map(
          (AutomationRunStatus value) => value.value,
        ),
        <String>['running', 'completed', 'failed', 'cancelled'],
      );
      expect(
        AutomationConditionOperator.values.map(
          (AutomationConditionOperator value) => value.value,
        ),
        <String>[
          'eq',
          'neq',
          'gt',
          'gte',
          'lt',
          'lte',
          'contains',
          'starts_with',
          'ends_with',
          'exists',
          'is_empty',
        ],
      );
      expect(
        AutomationConnectionType.values.map(
          (AutomationConnectionType value) => value.value,
        ),
        <String>[
          'default',
          'condition_met',
          'condition_not_met',
          'timeout',
          'event_received',
        ],
      );
    });
  });

  // Covers: AutomationCondition.
  group('AutomationCondition', () {
    // Verifies: serializes every rule operator and logical group.
    test('serializes every rule operator and logical group', () {
      final List<AutomationCondition> rules = <AutomationCondition>[
        AutomationCondition.rule(
          field: 'event.nullable',
          operator: AutomationConditionOperator.equal,
          value: null,
        ),
        AutomationCondition.rule(
          field: 'contact.active',
          operator: AutomationConditionOperator.notEqual,
          value: false,
        ),
        AutomationCondition.rule(
          field: 'event.amount',
          operator: AutomationConditionOperator.greaterThan,
          value: 1,
        ),
        AutomationCondition.rule(
          field: 'event.amount',
          operator: AutomationConditionOperator.greaterThanOrEqual,
          value: 2.5,
        ),
        AutomationCondition.rule(
          field: 'event.amount',
          operator: AutomationConditionOperator.lessThan,
          value: 10,
        ),
        AutomationCondition.rule(
          field: 'event.amount',
          operator: AutomationConditionOperator.lessThanOrEqual,
          value: 11,
        ),
        AutomationCondition.rule(
          field: 'event.name',
          operator: AutomationConditionOperator.contains,
          value: 'dart',
        ),
        AutomationCondition.rule(
          field: 'event.name',
          operator: AutomationConditionOperator.startsWith,
          value: 'da',
        ),
        AutomationCondition.rule(
          field: 'event.name',
          operator: AutomationConditionOperator.endsWith,
          value: 'rt',
        ),
        AutomationCondition.rule(
          field: 'event.name',
          operator: AutomationConditionOperator.exists,
        ),
        AutomationCondition.rule(
          field: 'contact.last_name',
          operator: AutomationConditionOperator.isEmpty,
        ),
      ];

      expect(rules.first.type, 'rule');
      expect(rules.first.toJson(), <String, Object?>{
        'type': 'rule',
        'field': 'event.nullable',
        'operator': 'eq',
        'value': null,
      });
      final AutomationCondition all = AutomationCondition.all(rules);
      final AutomationCondition any = AutomationCondition.any(
        <AutomationCondition>[rules.first],
      );
      expect(all.type, 'and');
      expect((all.toJson()['rules']! as List<Object?>), hasLength(11));
      expect(any.type, 'or');
      expect(() => all.toJson()['new'] = true, throwsUnsupportedError);
    });

    // Verifies: validates fields, values, and groups.
    test('validates fields, values, and groups', () {
      expect(
        () => AutomationCondition.rule(
          field: ' ',
          operator: AutomationConditionOperator.exists,
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationCondition.rule(
          field: 'payload.name',
          operator: AutomationConditionOperator.exists,
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationCondition.rule(
          field: 'event.',
          operator: AutomationConditionOperator.exists,
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationCondition.rule(
          field: 'event.name',
          operator: AutomationConditionOperator.equal,
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationCondition.rule(
          field: 'event.name',
          operator: AutomationConditionOperator.exists,
          value: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationCondition.rule(
          field: 'event.value',
          operator: AutomationConditionOperator.equal,
          value: <Object?>[],
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationCondition.rule(
          field: 'event.value',
          operator: AutomationConditionOperator.greaterThan,
          value: 'large',
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationCondition.rule(
          field: 'event.value',
          operator: AutomationConditionOperator.contains,
          value: 3,
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationCondition.rule(
          field: 'event.value',
          operator: AutomationConditionOperator.equal,
          value: double.nan,
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationCondition.all(const <AutomationCondition>[]),
        throwsArgumentError,
      );
    });
  });

  // Covers: AutomationStep.
  group('AutomationStep', () {
    // Verifies: serializes all documented step factories.
    test('serializes all documented step factories', () {
      final JsonObject variable = automationVariable('event.first_name');
      final AutomationCondition filter = AutomationCondition.rule(
        field: 'event.status',
        operator: AutomationConditionOperator.equal,
        value: 'paid',
      );
      final List<AutomationStep> steps = <AutomationStep>[
        AutomationStep.trigger(key: 'trigger', eventName: 'user.created'),
        AutomationStep.delay(key: 'delay', duration: '1 day'),
        AutomationStep.sendEmail(
          key: 'email',
          templateId: 'template-id',
          variables: <String, Object?>{'name': variable, 'static': 'value'},
          subject: 'Welcome',
          from: 'Sender <sender@example.com>',
          replyTo: 'reply@example.com',
        ),
        AutomationStep.waitForEvent(
          key: 'wait',
          eventName: 'payment.completed',
          timeout: '3 days',
          filter: filter,
        ),
        AutomationStep.condition(key: 'condition', condition: filter),
        AutomationStep.updateContact(
          key: 'update',
          firstName: variable,
          lastName: null,
          unsubscribed: variable,
          properties: <String, Object?>{
            'plan': 'pro',
            'score': 4.5,
            'vip': true,
            'nullable': null,
            'source': variable,
          },
        ),
        AutomationStep.deleteContact(key: 'delete'),
        AutomationStep.addToSegment(key: 'segment', segmentId: 'segment-id'),
        AutomationStep.custom(
          key: 'future',
          type: 'future_step',
          config: <String, Object?>{'future': true},
        ),
      ];

      expect(variable, <String, Object?>{'var': 'event.first_name'});
      expect(steps.map((AutomationStep step) => step.type), <String>[
        'trigger',
        'delay',
        'send_email',
        'wait_for_event',
        'condition',
        'contact_update',
        'contact_delete',
        'add_to_segment',
        'future_step',
      ]);
      expect(steps.first.key, 'trigger');
      expect(steps.first.config, <String, Object?>{
        'event_name': 'user.created',
      });
      expect(steps[2].config['reply_to'], 'reply@example.com');
      expect(steps[3].config['filter_rule'], filter.toJson());
      expect(steps[5].config['last_name'], isNull);
      expect(steps[6].config, isEmpty);
      expect(steps[7].config['segment_id'], 'segment-id');
      expect(steps.last.config['future'], isTrue);
      expect(steps.first.toJson()['type'], 'trigger');
      expect(() => steps.first.config['new'] = true, throwsUnsupportedError);
      expect(() => steps.first.toJson()['new'] = true, throwsUnsupportedError);

      expect(
        AutomationStep.sendEmail(
          key: 'minimal-email',
          templateId: 'template-id',
        ).config,
        <String, Object?>{
          'template': <String, Object?>{'id': 'template-id'},
        },
      );
      expect(
        AutomationStep.waitForEvent(
          key: 'minimal-wait',
          eventName: 'event.name',
        ).config,
        <String, Object?>{'event_name': 'event.name'},
      );
      expect(
        AutomationStep.updateContact(
          key: 'simple-update',
          firstName: 'Ada',
          lastName: 'Lovelace',
          unsubscribed: false,
        ).config,
        <String, Object?>{
          'first_name': 'Ada',
          'last_name': 'Lovelace',
          'unsubscribed': false,
        },
      );
    });

    // Verifies: validates factory input and typed contact values.
    test('validates factory input and typed contact values', () {
      expect(() => automationVariable(' '), throwsArgumentError);
      expect(
        () => AutomationStep.custom(key: ' ', type: 'type', config: const {}),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.custom(key: 'key', type: ' ', config: const {}),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.trigger(key: 'key', eventName: ' '),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.delay(key: 'key', duration: ' '),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.sendEmail(key: 'key', templateId: ' '),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.sendEmail(
          key: 'key',
          templateId: 'template',
          subject: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.sendEmail(
          key: 'key',
          templateId: 'template',
          from: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.sendEmail(
          key: 'key',
          templateId: 'template',
          replyTo: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.waitForEvent(key: 'key', eventName: ' '),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.waitForEvent(
          key: 'key',
          eventName: 'event',
          timeout: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.addToSegment(key: 'key', segmentId: ' '),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.updateContact(key: 'key'),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.updateContact(key: 'key', firstName: 1),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.updateContact(key: 'key', lastName: false),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.updateContact(key: 'key', unsubscribed: null),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.updateContact(
          key: 'key',
          properties: <String, Object?>{' ': 'value'},
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.updateContact(
          key: 'key',
          properties: <String, Object?>{'invalid': <Object?>[]},
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.updateContact(
          key: 'key',
          properties: <String, Object?>{'invalid': double.nan},
        ),
        throwsArgumentError,
      );
      expect(
        () => AutomationStep.updateContact(
          key: 'key',
          firstName: <String, Object?>{'var': ''},
        ),
        throwsArgumentError,
      );
    });
  });

  // Covers: automation graph requests.
  group('automation graph requests', () {
    // Verifies: connection serializes optional and explicit types.
    test('connection serializes optional and explicit types', () {
      final AutomationConnection plain = AutomationConnection(
        from: 'one',
        to: 'two',
      );
      final AutomationConnection typed = AutomationConnection(
        from: 'condition',
        to: 'yes',
        type: AutomationConnectionType.conditionMet,
      );
      expect(plain.from, 'one');
      expect(plain.to, 'two');
      expect(plain.type, isNull);
      expect(plain.toJson(), <String, Object?>{'from': 'one', 'to': 'two'});
      expect(typed.toJson()['type'], 'condition_met');
      expect(
        () => AutomationConnection(from: ' ', to: 'two'),
        throwsArgumentError,
      );
      expect(
        () => AutomationConnection(from: 'one', to: ' '),
        throwsArgumentError,
      );
      expect(
        () => AutomationConnection(from: 'one', to: 'one'),
        throwsArgumentError,
      );
    });

    // Verifies: create request validates and freezes a branching graph.
    test('create request validates and freezes a branching graph', () {
      final List<AutomationStep> steps = _branchingSteps();
      final List<AutomationConnection> connections = _branchingConnections();
      final CreateAutomationRequest request = CreateAutomationRequest(
        name: 'Lifecycle',
        status: AutomationStatus.enabled,
        steps: steps,
        connections: connections,
      );
      steps.add(AutomationStep.deleteContact(key: 'later'));
      connections.clear();

      expect(request.name, 'Lifecycle');
      expect(request.status, AutomationStatus.enabled);
      expect(request.steps, hasLength(6));
      expect(request.connections, hasLength(6));
      expect(request.toJson()['status'], 'enabled');
      expect(request.toJson()['steps'], hasLength(6));
      expect(request.toJson()['connections'], hasLength(6));
      expect(
        () => request.steps.add(request.steps.first),
        throwsUnsupportedError,
      );
      expect(
        () => request.connections.add(request.connections.first),
        throwsUnsupportedError,
      );

      final CreateAutomationRequest triggerOnly = CreateAutomationRequest(
        name: 'Trigger only',
        steps: <AutomationStep>[
          AutomationStep.trigger(key: 'start', eventName: 'event.name'),
        ],
        connections: const <AutomationConnection>[],
      );
      expect(triggerOnly.status, isNull);
      expect(triggerOnly.toJson(), <String, Object?>{
        'name': 'Trigger only',
        'steps': <Object?>[
          <String, Object?>{
            'key': 'start',
            'type': 'trigger',
            'config': <String, Object?>{'event_name': 'event.name'},
          },
        ],
        'connections': <Object?>[],
      });
    });

    // Verifies: update request accepts each supported patch shape.
    test('update request accepts each supported patch shape', () {
      final UpdateAutomationRequest metadata = UpdateAutomationRequest(
        name: 'Renamed',
        status: AutomationStatus.disabled,
      );
      expect(metadata.name, 'Renamed');
      expect(metadata.status, AutomationStatus.disabled);
      expect(metadata.steps, isNull);
      expect(metadata.connections, isNull);
      expect(metadata.toJson(), <String, Object?>{
        'name': 'Renamed',
        'status': 'disabled',
      });

      final UpdateAutomationRequest graph = UpdateAutomationRequest(
        steps: _branchingSteps(),
        connections: _branchingConnections(),
      );
      expect(graph.toJson()['steps'], hasLength(6));
      expect(graph.toJson()['connections'], hasLength(6));

      expect(
        () => UpdateAutomationRequest(
          steps: <AutomationStep>[
            AutomationStep.trigger(key: 'start', eventName: 'event.name'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => UpdateAutomationRequest(
          connections: <AutomationConnection>[
            AutomationConnection(from: 'old', to: 'new'),
          ],
        ),
        throwsArgumentError,
      );

      expect(() => UpdateAutomationRequest(), throwsArgumentError);
      expect(() => UpdateAutomationRequest(name: ' '), throwsArgumentError);
    });

    // Verifies: rejects invalid graph structures and branch types.
    test('rejects invalid graph structures and branch types', () {
      final AutomationStep trigger = AutomationStep.trigger(
        key: 'start',
        eventName: 'event.name',
      );
      final AutomationStep delay = AutomationStep.delay(
        key: 'delay',
        duration: '1 hour',
      );
      final AutomationStep condition = AutomationStep.condition(
        key: 'condition',
        condition: AutomationCondition.rule(
          field: 'event.value',
          operator: AutomationConditionOperator.exists,
        ),
      );
      final AutomationStep wait = AutomationStep.waitForEvent(
        key: 'wait',
        eventName: 'event.done',
      );

      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: const <AutomationStep>[],
          connections: const <AutomationConnection>[],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Too many steps',
          steps: List<AutomationStep>.generate(
            151,
            (int index) => index == 0
                ? AutomationStep.trigger(key: 'start', eventName: 'event.name')
                : AutomationStep.delay(
                    key: 'step_$index',
                    duration: '1 minute',
                  ),
          ),
          connections: const <AutomationConnection>[],
        ),
        throwsRangeError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[delay],
          connections: const <AutomationConnection>[],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[
            trigger,
            AutomationStep.trigger(key: 'again', eventName: 'event.other'),
          ],
          connections: <AutomationConnection>[
            AutomationConnection(from: 'start', to: 'again'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[trigger, trigger],
          connections: const <AutomationConnection>[],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[
            trigger,
            AutomationStep.delay(key: 'start', duration: '1 hour'),
          ],
          connections: const <AutomationConnection>[],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[trigger, delay],
          connections: <AutomationConnection>[
            AutomationConnection(from: 'start', to: 'missing'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[trigger, delay],
          connections: const <AutomationConnection>[],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[trigger, delay],
          connections: <AutomationConnection>[
            AutomationConnection(from: 'start', to: 'delay'),
            AutomationConnection(from: 'start', to: 'delay'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[trigger, delay],
          connections: <AutomationConnection>[
            AutomationConnection(from: 'start', to: 'delay'),
            AutomationConnection(from: 'delay', to: 'start'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[trigger, condition, delay],
          connections: <AutomationConnection>[
            AutomationConnection(from: 'start', to: 'condition'),
            AutomationConnection(from: 'condition', to: 'delay'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[trigger, wait, delay],
          connections: <AutomationConnection>[
            AutomationConnection(from: 'start', to: 'wait'),
            AutomationConnection(from: 'wait', to: 'delay'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: 'Invalid',
          steps: <AutomationStep>[trigger, delay],
          connections: <AutomationConnection>[
            AutomationConnection(
              from: 'start',
              to: 'delay',
              type: AutomationConnectionType.conditionMet,
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => UpdateAutomationRequest(
          connections: <AutomationConnection>[
            AutomationConnection(from: 'old', to: 'new'),
            AutomationConnection(from: 'old', to: 'new'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateAutomationRequest(
          name: ' ',
          steps: <AutomationStep>[trigger],
          connections: const <AutomationConnection>[],
        ),
        throwsArgumentError,
      );
    });
  });

  // Covers: automation response models.
  group('automation response models', () {
    // Verifies: expose summaries and forward-compatible raw strings.
    test('expose summaries and forward-compatible raw strings', () {
      final Automation automation = Automation.fromJson(<String, Object?>{
        'id': 'automation-id',
        'name': 'Lifecycle',
        'status': 'future_status',
        'created_at': '2026-07-20T10:00:00Z',
        'updated_at': '2026-07-20T11:00:00Z',
      });
      expect(automation.id, 'automation-id');
      expect(automation.name, 'Lifecycle');
      expect(automation.status, 'future_status');
      expect(automation.createdAt, DateTime.utc(2026, 7, 20, 10));
      expect(automation.updatedAt, DateTime.utc(2026, 7, 20, 11));

      final Automation minimal = Automation.fromJson(<String, Object?>{
        'id': 'minimal',
        'name': 'Minimal',
        'status': 'disabled',
        'created_at': '2026-07-20T10:00:00Z',
        'updated_at': null,
      });
      expect(minimal.updatedAt, isNull);
    });

    // Verifies: decodes complete automation graph details.
    test('decodes complete automation graph details', () {
      final AutomationDetails details = AutomationDetails.fromJson(
        _automationDetailsJson('automation-id'),
      );
      expect(details.id, 'automation-id');
      expect(details.name, 'Lifecycle');
      expect(details.status, 'future_status');
      expect(details.createdAt, DateTime.utc(2026, 7, 20, 10));
      expect(details.updatedAt, isNull);
      expect(details.object, 'automation');
      expect(details.steps.single.key, 'start');
      expect(details.steps.single.type, 'future_step');
      expect(details.steps.single.config['future'], isTrue);
      expect(details.connections.single.from, 'start');
      expect(details.connections.single.to, 'end');
      expect(details.connections.single.type, 'future_branch');

      final AutomationGraphConnection noType =
          AutomationGraphConnection.fromJson(<String, Object?>{
            'from': 'one',
            'to': 'two',
          });
      expect(noType.type, isNull);

      final AutomationDetails malformed = AutomationDetails.fromJson(
        <String, Object?>{
          ..._automationDetailsJson('malformed'),
          'steps': <Object?>['not-an-object'],
        },
      );
      expect(() => malformed.steps, throwsFormatException);
    });

    // Verifies: decodes stop and run diagnostics.
    test('decodes stop and run diagnostics', () {
      final StoppedAutomation stopped = StoppedAutomation.fromJson(
        <String, Object?>{
          'id': 'automation-id',
          'object': 'automation',
          'status': 'future_disabled',
        },
      );
      expect(stopped.id, 'automation-id');
      expect(stopped.object, 'automation');
      expect(stopped.status, 'future_disabled');

      final AutomationRunSummary summary = AutomationRunSummary.fromJson(
        _runSummaryJson('run-id'),
      );
      expect(summary.id, 'run-id');
      expect(summary.status, 'future_run_status');
      expect(summary.startedAt, DateTime.utc(2026, 7, 20, 10));
      expect(summary.completedAt, isNull);
      expect(summary.createdAt, DateTime.utc(2026, 7, 20, 9));

      final AutomationRun run = AutomationRun.fromJson(_runJson('run-id'));
      expect(run.object, 'automation_run');
      expect(run.id, 'run-id');
      expect(run.status, 'future_run_status');
      expect(run.startedAt, DateTime.utc(2026, 7, 20, 10));
      expect(run.completedAt, isNull);
      expect(run.createdAt, DateTime.utc(2026, 7, 20, 9));
      final AutomationRunStep step = run.steps.single;
      expect(step.key, 'start');
      expect(step.type, 'future_step');
      expect(step.status, 'future_step_status');
      expect(step.output!['accepted'], isTrue);
      expect(step.error!['message'], 'warning');
      expect(step.startedAt, DateTime.utc(2026, 7, 20, 10));
      expect(step.completedAt, isNull);
      expect(step.createdAt, DateTime.utc(2026, 7, 20, 9));

      final AutomationRunStep empty =
          AutomationRunStep.fromJson(<String, Object?>{
            'key': 'empty',
            'type': 'delay',
            'status': 'pending',
            'output': null,
            'error': null,
            'started_at': null,
            'completed_at': null,
            'created_at': '2026-07-20T09:00:00Z',
          });
      expect(empty.output, isNull);
      expect(empty.error, isNull);
      expect(empty.startedAt, isNull);
      expect(empty.completedAt, isNull);
    });
  });

  // Verifies: AutomationsResource sends every endpoint with encoded paths.
  test('AutomationsResource sends every endpoint with encoded paths', () async {
    final List<http.Request> requests = <http.Request>[];
    final MockClient client = MockClient((http.Request request) async {
      requests.add(request);
      final int index = requests.length - 1;
      switch (index) {
        case 0:
          expect(request.method, 'POST');
          expect(request.url.pathSegments, <String>['v1', 'automations']);
          final Map<String, Object?> body =
              jsonDecode(request.body) as Map<String, Object?>;
          expect(body['name'], 'Lifecycle');
          expect(body['status'], 'enabled');
          expect(body['steps'], hasLength(6));
          return _jsonResponse(<String, Object?>{
            'object': 'automation',
            'id': 'automation/a b',
          }, 201);
        case 1:
          expect(request.method, 'GET');
          expect(request.url.queryParameters, <String, String>{
            'limit': '10',
            'after': 'cursor',
            'status': 'enabled',
          });
          return _jsonResponse(<String, Object?>{
            'object': 'list',
            'has_more': false,
            'data': <Object?>[_automationJson('automation-list')],
          });
        case 2:
          expect(request.url.pathSegments.last, 'automation/a b');
          expect(request.url.toString(), contains('automation%2Fa%20b'));
          return _jsonResponse(_automationDetailsJson('automation/a b'));
        case 3:
          expect(request.method, 'PATCH');
          expect(jsonDecode(request.body), <String, Object?>{
            'status': 'disabled',
          });
          return _jsonResponse(<String, Object?>{
            'object': 'automation',
            'id': 'automation/a b',
          });
        case 4:
          expect(request.method, 'DELETE');
          return _jsonResponse(<String, Object?>{
            'object': 'automation',
            'id': 'automation/a b',
            'deleted': true,
          });
        case 5:
          expect(request.method, 'POST');
          expect(request.url.pathSegments.last, 'stop');
          return _jsonResponse(<String, Object?>{
            'object': 'automation',
            'id': 'automation/a b',
            'status': 'disabled',
          });
        case 6:
          expect(request.url.pathSegments, <String>[
            'v1',
            'automations',
            'automation/a b',
            'runs',
          ]);
          expect(request.url.queryParameters, <String, String>{
            'limit': '5',
            'before': 'run-cursor',
            'status': 'running,failed',
          });
          return _jsonResponse(<String, Object?>{
            'object': 'list',
            'has_more': false,
            'data': <Object?>[_runSummaryJson('run-list')],
          });
        case 7:
          expect(request.url.pathSegments.last, 'run/a b');
          expect(request.url.toString(), contains('run%2Fa%20b'));
          return _jsonResponse(_runJson('run/a b'));
        case 8:
          expect(request.url.queryParameters, isEmpty);
          return _jsonResponse(<String, Object?>{
            'object': 'list',
            'has_more': false,
            'data': <Object?>[],
          });
        default:
          expect(request.url.queryParameters, isEmpty);
          return _jsonResponse(<String, Object?>{
            'object': 'list',
            'has_more': false,
            'data': <Object?>[],
          });
      }
    });
    final AutomationsResource automations = AutomationsResource(
      ResendTransport(
        apiKey: 're_test',
        client: client,
        baseUri: Uri.parse('https://api.example.test/v1/'),
      ),
    );

    final CreateAutomationRequest createRequest = CreateAutomationRequest(
      name: 'Lifecycle',
      status: AutomationStatus.enabled,
      steps: _branchingSteps(),
      connections: _branchingConnections(),
    );
    final create = await automations.create(createRequest);
    expect(create.statusCode, 201);
    expect(create.data.id, 'automation/a b');
    expect(create.data.object, 'automation');

    final list = await automations.list(
      status: AutomationStatus.enabled,
      pagination: PaginationOptions(limit: 10, after: 'cursor'),
    );
    expect(list.data.data.single.id, 'automation-list');

    final retrieve = await automations.retrieve('automation/a b');
    expect(retrieve.data.id, 'automation/a b');

    final update = await automations.update(
      'automation/a b',
      UpdateAutomationRequest(status: AutomationStatus.disabled),
    );
    expect(update.data.id, 'automation/a b');

    final deletion = await automations.delete('automation/a b');
    expect(deletion.data.deleted, isTrue);
    expect(deletion.data.id, 'automation/a b');
    expect(deletion.data.object, 'automation');

    final stopped = await automations.stop('automation/a b');
    expect(stopped.data.status, 'disabled');

    final runs = await automations.runs.list(
      'automation/a b',
      statuses: <AutomationRunStatus>[
        AutomationRunStatus.running,
        AutomationRunStatus.failed,
      ],
      pagination: PaginationOptions(limit: 5, before: 'run-cursor'),
    );
    expect(runs.data.data.single.id, 'run-list');

    final run = await automations.runs.retrieve('automation/a b', 'run/a b');
    expect(run.data.id, 'run/a b');

    final noFilter = await automations.list();
    expect(noFilter.data.data, isEmpty);
    final noStatus = await automations.runs.list(
      'automation/a b',
      statuses: const <AutomationRunStatus>[],
    );
    expect(noStatus.data.data, isEmpty);

    expect(requests, hasLength(10));
  });
}

/// Builds the canonical branching graph steps reused by automation tests.
List<AutomationStep> _branchingSteps() => <AutomationStep>[
  AutomationStep.trigger(key: 'start', eventName: 'user.created'),
  AutomationStep.condition(
    key: 'condition',
    condition: AutomationCondition.rule(
      field: 'event.plan',
      operator: AutomationConditionOperator.equal,
      value: 'pro',
    ),
  ),
  AutomationStep.delay(key: 'delay', duration: '1 hour'),
  AutomationStep.waitForEvent(
    key: 'wait',
    eventName: 'payment.completed',
    timeout: '1 day',
  ),
  AutomationStep.sendEmail(key: 'email', templateId: 'template-id'),
  AutomationStep.deleteContact(key: 'delete'),
];

/// Builds valid branch connections for [_branchingSteps].
List<AutomationConnection> _branchingConnections() => <AutomationConnection>[
  AutomationConnection(from: 'start', to: 'condition'),
  AutomationConnection(
    from: 'condition',
    to: 'delay',
    type: AutomationConnectionType.conditionMet,
  ),
  AutomationConnection(
    from: 'condition',
    to: 'wait',
    type: AutomationConnectionType.conditionNotMet,
  ),
  AutomationConnection(from: 'delay', to: 'email'),
  AutomationConnection(
    from: 'wait',
    to: 'email',
    type: AutomationConnectionType.eventReceived,
  ),
  AutomationConnection(
    from: 'wait',
    to: 'delete',
    type: AutomationConnectionType.timeout,
  ),
];

/// Builds an automation summary response fixture for [id].
Map<String, Object?> _automationJson(String id) => <String, Object?>{
  'id': id,
  'name': 'Lifecycle',
  'status': 'future_status',
  'created_at': '2026-07-20T10:00:00Z',
  'updated_at': null,
};

/// Builds an automation detail fixture linked to [_branchingSteps].
Map<String, Object?> _automationDetailsJson(String id) => <String, Object?>{
  ..._automationJson(id),
  'object': 'automation',
  'steps': <Object?>[
    <String, Object?>{
      'key': 'start',
      'type': 'future_step',
      'config': <String, Object?>{'future': true},
    },
  ],
  'connections': <Object?>[
    <String, Object?>{'from': 'start', 'to': 'end', 'type': 'future_branch'},
  ],
};

/// Builds an automation-run summary response fixture for [id].
Map<String, Object?> _runSummaryJson(String id) => <String, Object?>{
  'id': id,
  'status': 'future_run_status',
  'started_at': '2026-07-20T10:00:00Z',
  'completed_at': null,
  'created_at': '2026-07-20T09:00:00Z',
};

/// Builds a detailed automation-run response fixture for [id].
Map<String, Object?> _runJson(String id) => <String, Object?>{
  'object': 'automation_run',
  ..._runSummaryJson(id),
  'steps': <Object?>[
    <String, Object?>{
      'key': 'start',
      'type': 'future_step',
      'status': 'future_step_status',
      'output': <String, Object?>{'accepted': true},
      'error': <String, Object?>{'message': 'warning'},
      'started_at': '2026-07-20T10:00:00Z',
      'completed_at': null,
      'created_at': '2026-07-20T09:00:00Z',
    },
  ],
};

/// Encodes [body] as the JSON response returned by an automation endpoint.
http.Response _jsonResponse(Object body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: <String, String>{'content-type': 'application/json'},
  );
}
