import 'package:dart_resend/dart_resend.dart';

/// Builds examples of every documented automation condition operator.
List<AutomationCondition> buildAutomationConditionExamples() {
  return <AutomationCondition>[
    AutomationCondition.rule(
      field: 'event.plan',
      operator: AutomationConditionOperator.equal,
      value: 'pro',
    ),
    AutomationCondition.rule(
      field: 'contact.unsubscribed',
      operator: AutomationConditionOperator.notEqual,
      value: true,
    ),
    AutomationCondition.rule(
      field: 'event.seats',
      operator: AutomationConditionOperator.greaterThan,
      value: 1,
    ),
    AutomationCondition.rule(
      field: 'event.seats',
      operator: AutomationConditionOperator.greaterThanOrEqual,
      value: 2,
    ),
    AutomationCondition.rule(
      field: 'event.seats',
      operator: AutomationConditionOperator.lessThan,
      value: 100,
    ),
    AutomationCondition.rule(
      field: 'event.seats',
      operator: AutomationConditionOperator.lessThanOrEqual,
      value: 99,
    ),
    AutomationCondition.rule(
      field: 'contact.email',
      operator: AutomationConditionOperator.contains,
      value: '@example.com',
    ),
    AutomationCondition.rule(
      field: 'contact.first_name',
      operator: AutomationConditionOperator.startsWith,
      value: 'A',
    ),
    AutomationCondition.rule(
      field: 'contact.email',
      operator: AutomationConditionOperator.endsWith,
      value: '.com',
    ),
    AutomationCondition.rule(
      field: 'event.order_id',
      operator: AutomationConditionOperator.exists,
    ),
    AutomationCondition.rule(
      field: 'contact.last_name',
      operator: AutomationConditionOperator.isEmpty,
    ),
  ];
}

/// Builds a forward-compatible step for a newly introduced server feature.
AutomationStep buildCustomAutomationStep() {
  return AutomationStep.custom(
    key: 'future_action',
    type: 'future_action',
    config: <String, Object?>{'enabled': true},
  );
}

/// Creates a complete automation graph with every documented standard step.
Future<ResendResponse<ResendId>> createAutomation(Resend resend) {
  final List<AutomationCondition> conditions =
      buildAutomationConditionExamples();
  final AutomationCondition eventFilter = AutomationCondition.any(
    <AutomationCondition>[conditions[6], conditions[9]],
  );
  final AutomationCondition branch = AutomationCondition.all(
    <AutomationCondition>[conditions[1], conditions[2]],
  );

  final List<AutomationStep> steps = <AutomationStep>[
    AutomationStep.trigger(key: 'trigger', eventName: 'trial.started'),
    AutomationStep.waitForEvent(
      key: 'wait',
      eventName: 'trial.activated',
      timeout: '3 days',
      filter: eventFilter,
    ),
    AutomationStep.condition(key: 'eligible', condition: branch),
    AutomationStep.sendEmail(
      key: 'welcome',
      templateId: 'trial-welcome',
      variables: <String, Object?>{
        'first_name': automationVariable('contact.first_name'),
        'plan': automationVariable('event.plan'),
      },
      subject: 'Welcome to your trial',
      from: 'Acme <onboarding@example.com>',
      replyTo: 'support@example.com',
    ),
    AutomationStep.delay(key: 'delay', duration: '1 day'),
    AutomationStep.updateContact(
      key: 'update_contact',
      firstName: automationVariable('event.first_name'),
      unsubscribed: false,
      properties: <String, Object?>{'plan': automationVariable('event.plan')},
    ),
    AutomationStep.addToSegment(
      key: 'add_segment',
      segmentId: 'seg_trial_users',
    ),
    AutomationStep.deleteContact(key: 'cleanup'),
  ];
  final List<AutomationConnection> connections = <AutomationConnection>[
    AutomationConnection(from: 'trigger', to: 'wait'),
    AutomationConnection(
      from: 'wait',
      to: 'eligible',
      type: AutomationConnectionType.eventReceived,
    ),
    AutomationConnection(
      from: 'wait',
      to: 'cleanup',
      type: AutomationConnectionType.timeout,
    ),
    AutomationConnection(
      from: 'eligible',
      to: 'welcome',
      type: AutomationConnectionType.conditionMet,
    ),
    AutomationConnection(
      from: 'eligible',
      to: 'update_contact',
      type: AutomationConnectionType.conditionNotMet,
    ),
    AutomationConnection(from: 'welcome', to: 'delay'),
    AutomationConnection(from: 'delay', to: 'cleanup'),
    AutomationConnection(from: 'update_contact', to: 'add_segment'),
    AutomationConnection(from: 'add_segment', to: 'cleanup'),
  ];

  return resend.automations.create(
    CreateAutomationRequest(
      name: 'Trial onboarding',
      status: AutomationStatus.disabled,
      steps: steps,
      connections: connections,
    ),
  );
}

/// Lists enabled or disabled automations.
Future<ResendResponse<ResendPage<Automation>>> listAutomations(Resend resend) {
  return resend.automations.list(
    status: AutomationStatus.enabled,
    pagination: PaginationOptions(limit: 25),
  );
}

/// Retrieves an automation and its complete graph.
Future<ResendResponse<AutomationDetails>> retrieveAutomation(
  Resend resend,
  String automationId,
) {
  return resend.automations.retrieve(automationId);
}

/// Updates an automation's name and enabled state.
Future<ResendResponse<ResendId>> updateAutomation(
  Resend resend,
  String automationId,
) {
  return resend.automations.update(
    automationId,
    UpdateAutomationRequest(
      name: 'Trial onboarding v2',
      status: AutomationStatus.enabled,
    ),
  );
}

/// Stops an automation so it cannot accept new runs.
Future<ResendResponse<StoppedAutomation>> stopAutomation(
  Resend resend,
  String automationId,
) {
  return resend.automations.stop(automationId);
}

/// Deletes an automation.
Future<ResendResponse<ResendDeletion>> deleteAutomation(
  Resend resend,
  String automationId,
) {
  return resend.automations.delete(automationId);
}

/// Lists runs for an automation and filters by run status.
Future<ResendResponse<ResendPage<AutomationRunSummary>>> listAutomationRuns(
  Resend resend,
  String automationId,
) {
  return resend.automations.runs.list(
    automationId,
    statuses: <AutomationRunStatus>[
      AutomationRunStatus.running,
      AutomationRunStatus.failed,
    ],
    pagination: PaginationOptions(limit: 25),
  );
}

/// Retrieves an automation run with step-level output and errors.
Future<ResendResponse<AutomationRun>> retrieveAutomationRun(
  Resend resend,
  String automationId,
  String runId,
) {
  return resend.automations.runs.retrieve(automationId, runId);
}
