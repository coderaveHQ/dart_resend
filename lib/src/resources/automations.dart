import '../core/json.dart';
import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// Whether an automation accepts new runs.
enum AutomationStatus implements ResendWireValue {
  /// The automation accepts matching events.
  enabled('enabled'),

  /// The automation does not accept matching events.
  disabled('disabled');

  const AutomationStatus(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// A status accepted by the automation-runs list filter.
enum AutomationRunStatus implements ResendWireValue {
  /// The run is currently executing.
  running('running'),

  /// The run finished successfully.
  completed('completed'),

  /// The run stopped because a step failed.
  failed('failed'),

  /// The run was cancelled.
  cancelled('cancelled');

  const AutomationRunStatus(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// A comparison supported by automation conditions and event filters.
enum AutomationConditionOperator implements ResendWireValue {
  /// Values are equal.
  equal('eq'),

  /// Values are not equal.
  notEqual('neq'),

  /// The field is greater than the value.
  greaterThan('gt'),

  /// The field is greater than or equal to the value.
  greaterThanOrEqual('gte'),

  /// The field is less than the value.
  lessThan('lt'),

  /// The field is less than or equal to the value.
  lessThanOrEqual('lte'),

  /// The field contains the value.
  contains('contains'),

  /// The field starts with the value.
  startsWith('starts_with'),

  /// The field ends with the value.
  endsWith('ends_with'),

  /// The field exists.
  exists('exists'),

  /// The field is empty.
  isEmpty('is_empty');

  const AutomationConditionOperator(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// A condition rule or a logical group of condition rules.
final class AutomationCondition implements ResendRequest {
  /// Creates a condition from an already validated wire object.
  AutomationCondition._(JsonObject json) : _json = immutableJsonMap(json);

  /// Creates a single comparison rule.
  ///
  /// [field] must use the `event.` or `contact.` namespace. [value] is omitted
  /// for [AutomationConditionOperator.exists] and
  /// [AutomationConditionOperator.isEmpty], required for all other operators,
  /// and may explicitly be `null` for equality operators.
  factory AutomationCondition.rule({
    required String field,
    required AutomationConditionOperator operator,
    Object? value = _omitted,
  }) {
    final String validatedField = requireNonBlank(field, 'field');
    if (!_isConditionField(validatedField)) {
      throw ArgumentError.value(
        field,
        'field',
        'Must start with event. or contact..',
      );
    }
    final bool hasValue = !identical(value, _omitted);
    if (operator == AutomationConditionOperator.exists ||
        operator == AutomationConditionOperator.isEmpty) {
      if (hasValue) {
        throw ArgumentError.value(
          value,
          'value',
          'Must be omitted for ${operator.value}.',
        );
      }
    } else if (!hasValue) {
      throw ArgumentError('A value is required for ${operator.value}.');
    }

    _validateConditionValue(operator, value);
    return AutomationCondition._(<String, Object?>{
      'type': 'rule',
      'field': validatedField,
      'operator': operator.value,
      if (hasValue) 'value': value,
    });
  }

  /// Requires every condition in [rules] to match.
  factory AutomationCondition.all(List<AutomationCondition> rules) {
    return AutomationCondition._group('and', rules);
  }

  /// Requires at least one condition in [rules] to match.
  factory AutomationCondition.any(List<AutomationCondition> rules) {
    return AutomationCondition._group('or', rules);
  }

  /// Creates a validated logical [type] group from [rules].
  factory AutomationCondition._group(
    String type,
    List<AutomationCondition> rules,
  ) {
    final List<AutomationCondition> validated = requireNonEmpty(rules, 'rules');
    return AutomationCondition._(<String, Object?>{
      'type': type,
      'rules': <Object?>[
        for (final AutomationCondition rule in validated) rule.toJson(),
      ],
    });
  }

  /// Immutable wire representation shared by rule and group conditions.
  final JsonObject _json;

  /// The wire condition type: `rule`, `and`, or `or`.
  String get type => _json['type']! as String;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => _json;
}

/// A directed connection between two automation steps.
final class AutomationConnection implements ResendRequest {
  /// Creates a graph connection.
  AutomationConnection({required String from, required String to, this.type})
    : from = requireNonBlank(from, 'from'),
      to = requireNonBlank(to, 'to') {
    if (this.from == this.to) {
      throw ArgumentError('An automation step cannot connect to itself.');
    }
  }

  /// Key of the source step.
  final String from;

  /// Key of the destination step.
  final String to;

  /// Branch type, omitted for an ordinary default connection.
  final AutomationConnectionType? type;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'from': from,
    'to': to,
    'type': type?.value,
  });
}

/// A documented automation connection branch.
enum AutomationConnectionType implements ResendWireValue {
  /// Ordinary linear execution.
  defaultConnection('default'),

  /// A condition evaluated to true.
  conditionMet('condition_met'),

  /// A condition evaluated to false.
  conditionNotMet('condition_not_met'),

  /// A wait-for-event step timed out.
  timeout('timeout'),

  /// A wait-for-event step received its event.
  eventReceived('event_received');

  const AutomationConnectionType(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// One node in an automation graph.
final class AutomationStep implements ResendRequest {
  /// Creates a step from a validated type-specific payload.
  AutomationStep._({
    required String key,
    required String type,
    required JsonObject config,
  }) : key = requireNonBlank(key, 'key'),
       type = requireNonBlank(type, 'type'),
       config = immutableJsonMap(config);

  /// Creates an event trigger step.
  factory AutomationStep.trigger({
    required String key,
    required String eventName,
  }) {
    return AutomationStep._(
      key: key,
      type: 'trigger',
      config: <String, Object?>{
        'event_name': requireNonBlank(eventName, 'eventName'),
      },
    );
  }

  /// Creates a natural-language delay step, such as `1 hour`.
  factory AutomationStep.delay({
    required String key,
    required String duration,
  }) {
    return AutomationStep._(
      key: key,
      type: 'delay',
      config: <String, Object?>{
        'duration': requireNonBlank(duration, 'duration'),
      },
    );
  }

  /// Creates a published-template email step.
  factory AutomationStep.sendEmail({
    required String key,
    required String templateId,
    JsonObject? variables,
    String? subject,
    String? from,
    String? replyTo,
  }) {
    return AutomationStep._(
      key: key,
      type: 'send_email',
      config: compactJson(<String, Object?>{
        'template': compactJson(<String, Object?>{
          'id': requireNonBlank(templateId, 'templateId'),
          'variables': variables == null ? null : immutableJsonMap(variables),
        }),
        'subject': _optionalNonBlank(subject, 'subject'),
        'from': _optionalNonBlank(from, 'from'),
        'reply_to': _optionalNonBlank(replyTo, 'replyTo'),
      }),
    );
  }

  /// Creates a step that waits for a matching event.
  factory AutomationStep.waitForEvent({
    required String key,
    required String eventName,
    String? timeout,
    AutomationCondition? filter,
  }) {
    return AutomationStep._(
      key: key,
      type: 'wait_for_event',
      config: compactJson(<String, Object?>{
        'event_name': requireNonBlank(eventName, 'eventName'),
        'timeout': _optionalNonBlank(timeout, 'timeout'),
        'filter_rule': filter?.toJson(),
      }),
    );
  }

  /// Creates a branching condition step.
  factory AutomationStep.condition({
    required String key,
    required AutomationCondition condition,
  }) {
    return AutomationStep._(
      key: key,
      type: 'condition',
      config: condition.toJson(),
    );
  }

  /// Creates a contact update step.
  ///
  /// Name values may be strings, `null`, or [automationVariable] references.
  /// [unsubscribed] may be a boolean or variable reference. Property values may
  /// be strings, numbers, booleans, `null`, or variable references.
  factory AutomationStep.updateContact({
    required String key,
    Object? firstName = _omitted,
    Object? lastName = _omitted,
    Object? unsubscribed = _omitted,
    JsonObject? properties,
  }) {
    if (identical(firstName, _omitted) &&
        identical(lastName, _omitted) &&
        identical(unsubscribed, _omitted) &&
        properties == null) {
      throw ArgumentError('At least one contact field must be updated.');
    }
    if (!identical(firstName, _omitted)) {
      _validateNameValue(firstName, 'firstName');
    }
    if (!identical(lastName, _omitted)) {
      _validateNameValue(lastName, 'lastName');
    }
    if (!identical(unsubscribed, _omitted) &&
        unsubscribed is! bool &&
        !_isVariable(unsubscribed)) {
      throw ArgumentError.value(
        unsubscribed,
        'unsubscribed',
        'Must be a boolean or variable reference.',
      );
    }
    if (properties != null) {
      for (final MapEntry<String, Object?> entry in properties.entries) {
        requireNonBlank(entry.key, 'properties key');
        _validatePropertyValue(entry.value, entry.key);
      }
    }

    final JsonObject config = <String, Object?>{};
    if (!identical(firstName, _omitted)) config['first_name'] = firstName;
    if (!identical(lastName, _omitted)) config['last_name'] = lastName;
    if (!identical(unsubscribed, _omitted)) {
      config['unsubscribed'] = unsubscribed;
    }
    if (properties != null) config['properties'] = properties;
    return AutomationStep._(key: key, type: 'contact_update', config: config);
  }

  /// Creates a permanent contact deletion step.
  factory AutomationStep.deleteContact({required String key}) {
    return AutomationStep._(
      key: key,
      type: 'contact_delete',
      config: const <String, Object?>{},
    );
  }

  /// Creates a step that adds the current contact to a segment.
  factory AutomationStep.addToSegment({
    required String key,
    required String segmentId,
  }) {
    return AutomationStep._(
      key: key,
      type: 'add_to_segment',
      config: <String, Object?>{
        'segment_id': requireNonBlank(segmentId, 'segmentId'),
      },
    );
  }

  /// Creates a forward-compatible custom step.
  factory AutomationStep.custom({
    required String key,
    required String type,
    required JsonObject config,
  }) {
    return AutomationStep._(key: key, type: type, config: config);
  }

  /// Stable key used by graph connections.
  final String key;

  /// Raw wire step type.
  final String type;

  /// Deeply immutable wire-format step configuration.
  final JsonObject config;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => immutableJsonMap(<String, Object?>{
    'key': key,
    'type': type,
    'config': config,
  });
}

/// Creates a dynamic automation value reference.
JsonObject automationVariable(String path) {
  return immutableJsonMap(<String, Object?>{
    'var': requireNonBlank(path, 'path'),
  });
}

/// Parameters for creating an automation graph.
final class CreateAutomationRequest implements ResendRequest {
  /// Creates and validates an automation graph.
  CreateAutomationRequest({
    required String name,
    this.status,
    required List<AutomationStep> steps,
    required List<AutomationConnection> connections,
  }) : name = requireNonBlank(name, 'name'),
       steps = List<AutomationStep>.unmodifiable(steps),
       connections = List<AutomationConnection>.unmodifiable(connections) {
    _validateGraph(this.steps, this.connections);
  }

  /// Human-readable automation name.
  final String name;

  /// Initial state. Resend defaults to disabled when omitted.
  final AutomationStatus? status;

  /// Immutable graph steps.
  final List<AutomationStep> steps;

  /// Immutable graph connections.
  final List<AutomationConnection> connections;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'name': name,
    'status': status?.value,
    'steps': <Object?>[for (final AutomationStep step in steps) step.toJson()],
    'connections': <Object?>[
      for (final AutomationConnection connection in connections)
        connection.toJson(),
    ],
  });
}

/// Parameters for updating an automation.
final class UpdateAutomationRequest implements ResendRequest {
  /// Creates automation update parameters.
  UpdateAutomationRequest({
    String? name,
    this.status,
    List<AutomationStep>? steps,
    List<AutomationConnection>? connections,
  }) : name = _optionalNonBlank(name, 'name'),
       steps = steps == null ? null : List<AutomationStep>.unmodifiable(steps),
       connections = connections == null
           ? null
           : List<AutomationConnection>.unmodifiable(connections) {
    if (name == null &&
        status == null &&
        steps == null &&
        connections == null) {
      throw ArgumentError('At least one automation field must be updated.');
    }
    if ((this.steps == null) != (this.connections == null)) {
      throw ArgumentError('steps and connections must be updated together.');
    }
    if (this.steps != null) {
      _validateGraph(this.steps!, this.connections!);
    }
  }

  /// Replacement automation name.
  final String? name;

  /// Replacement enabled state.
  final AutomationStatus? status;

  /// Replacement graph steps.
  final List<AutomationStep>? steps;

  /// Replacement graph connections.
  final List<AutomationConnection>? connections;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'name': name,
    'status': status?.value,
    'steps': steps == null
        ? null
        : <Object?>[for (final AutomationStep step in steps!) step.toJson()],
    'connections': connections == null
        ? null
        : <Object?>[
            for (final AutomationConnection connection in connections!)
              connection.toJson(),
          ],
  });
}

/// An automation summary returned by list operations.
final class Automation extends ResendModel {
  /// Decodes an automation summary.
  Automation.fromJson(super.json);

  /// Automation ID.
  String get id => field<String>('id');

  /// Human-readable name.
  String get name => field<String>('name');

  /// Raw status, preserved for forward compatibility.
  String get status => field<String>('status');

  /// Creation timestamp.
  DateTime get createdAt => dateTimeField('created_at');

  /// Last update timestamp, when present.
  DateTime? get updatedAt => optionalDateTimeField('updated_at');
}

/// A response step in a retrieved automation graph.
final class AutomationGraphStep extends ResendModel {
  /// Decodes an automation graph step.
  AutomationGraphStep.fromJson(super.json);

  /// Stable graph key.
  String get key => field<String>('key');

  /// Raw step type, preserved for forward compatibility.
  String get type => field<String>('type');

  /// Raw, immutable configuration.
  JsonObject get config => objectField('config');
}

/// A response connection in a retrieved automation graph.
final class AutomationGraphConnection extends ResendModel {
  /// Decodes an automation graph connection.
  AutomationGraphConnection.fromJson(super.json);

  /// Source step key.
  String get from => field<String>('from');

  /// Destination step key.
  String get to => field<String>('to');

  /// Raw branch type, preserved for forward compatibility.
  String? get type => optionalField<String>('type');
}

/// A retrieved automation including its complete graph.
final class AutomationDetails extends ResendModel {
  /// Decodes automation details.
  AutomationDetails.fromJson(super.json);

  /// Automation ID.
  String get id => field<String>('id');

  /// Human-readable name.
  String get name => field<String>('name');

  /// Raw status, preserved for forward compatibility.
  String get status => field<String>('status');

  /// Creation timestamp.
  DateTime get createdAt => dateTimeField('created_at');

  /// Last update timestamp, when present.
  DateTime? get updatedAt => optionalDateTimeField('updated_at');

  /// Raw object discriminator.
  String get object => field<String>('object');

  /// Decoded graph steps.
  List<AutomationGraphStep> get steps => List<AutomationGraphStep>.unmodifiable(
    listField<Object?>('steps').map(
      (Object? value) =>
          AutomationGraphStep.fromJson(_jsonObject(value, 'steps')),
    ),
  );

  /// Decoded graph connections.
  List<AutomationGraphConnection> get connections =>
      List<AutomationGraphConnection>.unmodifiable(
        listField<Object?>('connections').map(
          (Object? value) => AutomationGraphConnection.fromJson(
            _jsonObject(value, 'connections'),
          ),
        ),
      );
}

/// Response returned after an automation is stopped.
final class StoppedAutomation extends ResendModel {
  /// Decodes a stop response.
  StoppedAutomation.fromJson(super.json);

  /// Automation ID.
  String get id => field<String>('id');

  /// Raw object discriminator.
  String get object => field<String>('object');

  /// Raw resulting status, preserved for forward compatibility.
  String get status => field<String>('status');
}

/// A compact automation run returned by list operations.
final class AutomationRunSummary extends ResendModel {
  /// Decodes a run summary.
  AutomationRunSummary.fromJson(super.json);

  /// Run ID.
  String get id => field<String>('id');

  /// Raw run status, preserved for forward compatibility.
  String get status => field<String>('status');

  /// When execution started.
  DateTime? get startedAt => optionalDateTimeField('started_at');

  /// When execution completed.
  DateTime? get completedAt => optionalDateTimeField('completed_at');

  /// When the run was created.
  DateTime get createdAt => dateTimeField('created_at');
}

/// The execution state of one automation step.
final class AutomationRunStep extends ResendModel {
  /// Decodes a run step.
  AutomationRunStep.fromJson(super.json);

  /// Graph step key.
  String get key => field<String>('key');

  /// Raw step type, preserved for forward compatibility.
  String get type => field<String>('type');

  /// Raw execution status, preserved for forward compatibility.
  String get status => field<String>('status');

  /// Step output, when produced.
  JsonObject? get output => optionalObjectField('output');

  /// Structured step error, when present.
  JsonObject? get error => optionalObjectField('error');

  /// When execution started.
  DateTime? get startedAt => optionalDateTimeField('started_at');

  /// When execution completed.
  DateTime? get completedAt => optionalDateTimeField('completed_at');

  /// When the step was created.
  DateTime get createdAt => dateTimeField('created_at');
}

/// A retrieved automation run with step-level diagnostics.
final class AutomationRun extends ResendModel {
  /// Decodes an automation run.
  AutomationRun.fromJson(super.json);

  /// Raw object discriminator.
  String get object => field<String>('object');

  /// Run ID.
  String get id => field<String>('id');

  /// Raw run status, preserved for forward compatibility.
  String get status => field<String>('status');

  /// When execution started.
  DateTime? get startedAt => optionalDateTimeField('started_at');

  /// When execution completed.
  DateTime? get completedAt => optionalDateTimeField('completed_at');

  /// When the run was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// Step-level execution details.
  List<AutomationRunStep> get steps => List<AutomationRunStep>.unmodifiable(
    listField<Object?>('steps').map(
      (Object? value) =>
          AutomationRunStep.fromJson(_jsonObject(value, 'steps')),
    ),
  );
}

/// Operations for automation runs.
final class AutomationRunsResource {
  /// Creates an automation-runs resource client.
  AutomationRunsResource(this._transport);

  /// Transport used to execute automation-run endpoint requests.
  final ResendTransport _transport;

  /// Lists runs belonging to [automationId].
  Future<ResendResponse<ResendPage<AutomationRunSummary>>> list(
    String automationId, {
    List<AutomationRunStatus>? statuses,
    PaginationOptions? pagination,
  }) {
    final Map<String, String> query = <String, String>{
      ...?pagination?.toQuery(),
    };
    if (statuses != null && statuses.isNotEmpty) {
      query['status'] = statuses
          .map((AutomationRunStatus status) => status.value)
          .join(',');
    }
    return _transport.get<ResendPage<AutomationRunSummary>>(
      pathSegments: <String>[
        'automations',
        requireNonBlank(automationId, 'automationId'),
        'runs',
      ],
      query: query,
      decode: (JsonObject json) => ResendPage<AutomationRunSummary>.fromJson(
        json,
        AutomationRunSummary.fromJson,
      ),
    );
  }

  /// Retrieves [runId] from [automationId].
  Future<ResendResponse<AutomationRun>> retrieve(
    String automationId,
    String runId,
  ) {
    return _transport.get<AutomationRun>(
      pathSegments: <String>[
        'automations',
        requireNonBlank(automationId, 'automationId'),
        'runs',
        requireNonBlank(runId, 'runId'),
      ],
      decode: AutomationRun.fromJson,
    );
  }
}

/// Operations for automation graphs and their runs.
final class AutomationsResource {
  /// Creates an automations resource client.
  AutomationsResource(this._transport)
    : runs = AutomationRunsResource(_transport);

  /// Transport shared by graph operations and nested run operations.
  final ResendTransport _transport;

  /// Operations for executions of an automation.
  final AutomationRunsResource runs;

  /// Creates an automation.
  Future<ResendResponse<ResendId>> create(CreateAutomationRequest request) {
    return _transport.post<ResendId>(
      pathSegments: <String>['automations'],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Lists automations, optionally filtered by [status].
  Future<ResendResponse<ResendPage<Automation>>> list({
    AutomationStatus? status,
    PaginationOptions? pagination,
  }) {
    final Map<String, String> query = <String, String>{
      ...?pagination?.toQuery(),
    };
    if (status != null) query['status'] = status.value;
    return _transport.get<ResendPage<Automation>>(
      pathSegments: <String>['automations'],
      query: query,
      decode: (JsonObject json) =>
          ResendPage<Automation>.fromJson(json, Automation.fromJson),
    );
  }

  /// Retrieves an automation by [id].
  Future<ResendResponse<AutomationDetails>> retrieve(String id) {
    return _transport.get<AutomationDetails>(
      pathSegments: <String>['automations', requireNonBlank(id, 'id')],
      decode: AutomationDetails.fromJson,
    );
  }

  /// Updates an automation by [id].
  Future<ResendResponse<ResendId>> update(
    String id,
    UpdateAutomationRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>['automations', requireNonBlank(id, 'id')],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Deletes an automation by [id].
  Future<ResendResponse<ResendDeletion>> delete(String id) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>['automations', requireNonBlank(id, 'id')],
      decode: ResendDeletion.fromJson,
    );
  }

  /// Stops an automation so it no longer accepts new runs.
  Future<ResendResponse<StoppedAutomation>> stop(String id) {
    return _transport.post<StoppedAutomation>(
      pathSegments: <String>['automations', requireNonBlank(id, 'id'), 'stop'],
      decode: StoppedAutomation.fromJson,
    );
  }
}

/// Sentinel that distinguishes an omitted update from an explicit JSON null.
const Object _omitted = Object();

/// Whether [field] addresses event or contact data in a condition.
bool _isConditionField(String field) {
  return (field.startsWith('event.') && field.length > 'event.'.length) ||
      (field.startsWith('contact.') && field.length > 'contact.'.length);
}

/// Enforces the operand type required by [operator].
void _validateConditionValue(
  AutomationConditionOperator operator,
  Object? value,
) {
  switch (operator) {
    case AutomationConditionOperator.equal:
    case AutomationConditionOperator.notEqual:
      if (value != null &&
          value is! String &&
          value is! num &&
          value is! bool) {
        throw ArgumentError.value(value, 'value', 'Must be a JSON scalar.');
      }
    case AutomationConditionOperator.greaterThan:
    case AutomationConditionOperator.greaterThanOrEqual:
    case AutomationConditionOperator.lessThan:
    case AutomationConditionOperator.lessThanOrEqual:
      if (value is! num) {
        throw ArgumentError.value(value, 'value', 'Must be a number.');
      }
    case AutomationConditionOperator.contains:
    case AutomationConditionOperator.startsWith:
    case AutomationConditionOperator.endsWith:
      if (value is! String) {
        throw ArgumentError.value(value, 'value', 'Must be a string.');
      }
    default:
      return;
  }
  immutableJsonMap(<String, Object?>{'value': value});
}

/// Validates a name operand as text, null, or an automation variable.
void _validateNameValue(Object? value, String name) {
  if (value != null && value is! String && !_isVariable(value)) {
    throw ArgumentError.value(
      value,
      name,
      'Must be a string, null, or variable reference.',
    );
  }
}

/// Validates a property operand as a JSON scalar or automation variable.
void _validatePropertyValue(Object? value, String name) {
  if (value != null &&
      value is! String &&
      value is! num &&
      value is! bool &&
      !_isVariable(value)) {
    throw ArgumentError.value(
      value,
      name,
      'Must be a JSON scalar or variable reference.',
    );
  }
  immutableJsonMap(<String, Object?>{'value': value});
}

/// Whether [value] is a single-key, non-empty `{"var": path}` reference.
bool _isVariable(Object? value) {
  if (value is! Map<String, Object?> || value.length != 1) return false;
  final Object? path = value['var'];
  return path is String && path.trim().isNotEmpty;
}

/// Validates graph reachability and branch-specific connection types.
void _validateGraph(
  List<AutomationStep> steps,
  List<AutomationConnection> connections,
) {
  final Set<String> keys = _validateSteps(steps);
  _validateConnections(connections, keys);

  // Compute a fixed-point traversal from the trigger without assuming that
  // the caller supplied steps or connections in topological order.
  final Set<String> reachable = <String>{steps.first.key};
  bool changed;
  do {
    changed = false;
    for (final AutomationConnection connection in connections) {
      if (reachable.contains(connection.from) && reachable.add(connection.to)) {
        changed = true;
      }
    }
  } while (changed);
  if (reachable.length != steps.length) {
    throw ArgumentError(
      'Every automation step must be reachable from trigger.',
    );
  }

  final Map<String, AutomationStep> byKey = <String, AutomationStep>{
    for (final AutomationStep step in steps) step.key: step,
  };
  for (final AutomationConnection connection in connections) {
    if (connection.to == steps.first.key) {
      throw ArgumentError('The trigger step cannot have incoming connections.');
    }
    final String sourceType = byKey[connection.from]!.type;
    final AutomationConnectionType effectiveType =
        connection.type ?? AutomationConnectionType.defaultConnection;
    if (sourceType == 'condition') {
      if (effectiveType != AutomationConnectionType.conditionMet &&
          effectiveType != AutomationConnectionType.conditionNotMet) {
        throw ArgumentError(
          'Condition connections must use a condition branch type.',
        );
      }
    } else if (sourceType == 'wait_for_event') {
      if (effectiveType != AutomationConnectionType.eventReceived &&
          effectiveType != AutomationConnectionType.timeout) {
        throw ArgumentError(
          'Wait-for-event connections must use an event branch type.',
        );
      }
    } else if (effectiveType != AutomationConnectionType.defaultConnection) {
      throw ArgumentError('Only branching steps may use branch connections.');
    }
  }
}

/// Validates trigger placement, size limits, and unique step keys.
Set<String> _validateSteps(List<AutomationStep> steps) {
  if (steps.isEmpty) {
    throw ArgumentError.value(steps, 'steps', 'Must not be empty.');
  }
  if (steps.length > 150) {
    throw RangeError.range(steps.length, 1, 150, 'steps.length');
  }
  if (steps.first.type != 'trigger') {
    throw ArgumentError('The first automation step must be a trigger.');
  }
  if (steps.where((AutomationStep step) => step.type == 'trigger').length !=
      1) {
    throw ArgumentError('An automation must contain exactly one trigger.');
  }
  final Set<String> keys = <String>{};
  for (final AutomationStep step in steps) {
    if (!keys.add(step.key)) {
      throw ArgumentError.value(step.key, 'steps', 'Step keys must be unique.');
    }
  }
  return keys;
}

/// Validates connection endpoints and rejects duplicate directed edges.
void _validateConnections(
  List<AutomationConnection> connections,
  Set<String>? stepKeys,
) {
  final Set<String> identities = <String>{};
  for (final AutomationConnection connection in connections) {
    if (stepKeys != null &&
        (!stepKeys.contains(connection.from) ||
            !stepKeys.contains(connection.to))) {
      throw ArgumentError('Every connection must reference an existing step.');
    }
    final String identity =
        '${connection.from}\u0000${connection.to}\u0000${connection.type?.value}';
    if (!identities.add(identity)) {
      throw ArgumentError('Automation connections must be unique.');
    }
  }
}

/// Validates [value] when present while preserving null omission semantics.
String? _optionalNonBlank(String? value, String name) {
  return value == null ? null : requireNonBlank(value, name);
}

/// Validates and freezes one JSON object decoded within [name].
JsonObject _jsonObject(Object? value, String name) {
  if (value is Map<String, Object?>) return immutableJsonMap(value);
  throw FormatException('Expected every $name item to be a JSON object.');
}
