import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// A contact's subscription preference for a topic.
enum TopicSubscription implements ResendWireValue {
  /// The contact is subscribed.
  optIn('opt_in'),

  /// The contact is unsubscribed.
  optOut('opt_out');

  const TopicSubscription(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// Controls whether a topic appears on the public unsubscribe page.
enum TopicVisibility implements ResendWireValue {
  /// Visible to every contact on the unsubscribe page.
  public('public'),

  /// Visible only to contacts who are already opted in.
  private('private');

  const TopicVisibility(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// Parameters for creating a subscription topic.
final class CreateTopicRequest implements ResendRequest {
  /// Creates topic parameters.
  CreateTopicRequest({
    required String name,
    required this.defaultSubscription,
    String? description,
    this.visibility,
  }) : name = _validatedName(name),
       description = _validatedDescription(description);

  /// Human-readable topic name.
  final String name;

  /// Subscription applied to contacts without an explicit preference.
  final TopicSubscription defaultSubscription;

  /// Optional explanation shown for the topic.
  final String? description;

  /// Visibility on the unsubscribe page. Resend defaults this to private.
  final TopicVisibility? visibility;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'name': name,
    'default_subscription': defaultSubscription.value,
    'description': description,
    'visibility': visibility?.value,
  });
}

/// Parameters for updating a subscription topic.
final class UpdateTopicRequest implements ResendRequest {
  /// Creates topic-update parameters.
  UpdateTopicRequest({String? name, String? description, this.visibility})
    : name = name == null ? null : _validatedName(name),
      description = _validatedDescription(description) {
    if (name == null && description == null && visibility == null) {
      throw ArgumentError('At least one topic field must be updated.');
    }
  }

  /// Replacement topic name.
  final String? name;

  /// Replacement topic description.
  final String? description;

  /// Replacement visibility on the unsubscribe page.
  final TopicVisibility? visibility;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => compactJson(<String, Object?>{
    'name': name,
    'description': description,
    'visibility': visibility?.value,
  });
}

/// A subscription topic returned by Resend.
final class Topic extends ResendModel {
  /// Decodes a topic.
  Topic.fromJson(super.json);

  /// The topic ID.
  String get id => field<String>('id');

  /// The topic name.
  String get name => field<String>('name');

  /// The topic description, when set.
  String? get description => optionalField<String>('description');

  /// The raw default-subscription value, preserved for forward compatibility.
  String get defaultSubscription => field<String>('default_subscription');

  /// The raw visibility value, preserved for forward compatibility.
  String get visibility => field<String>('visibility');

  /// When the topic was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// The raw object discriminator, when returned by Resend.
  String? get object => optionalField<String>('object');
}

/// Operations for managing subscription topics.
final class TopicsResource {
  /// Creates a topics resource client.
  TopicsResource(this._transport);

  /// Transport used to execute topic endpoint requests.
  final ResendTransport _transport;

  /// Creates a topic.
  Future<ResendResponse<ResendId>> create(CreateTopicRequest request) {
    return _transport.post<ResendId>(
      pathSegments: <String>['topics'],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Lists topics.
  Future<ResendResponse<ResendPage<Topic>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<Topic>>(
      pathSegments: <String>['topics'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<Topic>.fromJson(json, Topic.fromJson),
    );
  }

  /// Retrieves a topic by [id].
  Future<ResendResponse<Topic>> retrieve(String id) {
    return _transport.get<Topic>(
      pathSegments: <String>['topics', requireNonBlank(id, 'id')],
      decode: Topic.fromJson,
    );
  }

  /// Updates a topic by [id].
  Future<ResendResponse<ResendId>> update(
    String id,
    UpdateTopicRequest request,
  ) {
    return _transport.patch<ResendId>(
      pathSegments: <String>['topics', requireNonBlank(id, 'id')],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Deletes a topic by [id].
  Future<ResendResponse<ResendDeletion>> delete(String id) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>['topics', requireNonBlank(id, 'id')],
      decode: ResendDeletion.fromJson,
    );
  }
}

/// Validates a topic name against the API's length limit.
String _validatedName(String value) {
  final String name = requireNonBlank(value, 'name');
  if (name.length > 50) {
    throw ArgumentError.value(value, 'name', 'Must be at most 50 characters.');
  }
  return name;
}

/// Validates an optional topic description against its length limit.
String? _validatedDescription(String? value) {
  if (value != null && value.length > 200) {
    throw ArgumentError.value(
      value,
      'description',
      'Must be at most 200 characters.',
    );
  }
  return value;
}
