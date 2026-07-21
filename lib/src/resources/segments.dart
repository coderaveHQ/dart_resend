import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';
import 'contacts.dart';

/// Parameters for creating a contact segment.
final class CreateSegmentRequest implements ResendRequest {
  /// Creates segment parameters.
  CreateSegmentRequest({required String name})
    : name = requireNonBlank(name, 'name');

  /// The segment's human-readable name.
  final String name;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() => <String, Object?>{'name': name};
}

/// A contact segment returned by Resend.
final class Segment extends ResendModel {
  /// Decodes a segment.
  Segment.fromJson(super.json);

  /// The segment ID.
  String get id => field<String>('id');

  /// The segment name.
  String get name => field<String>('name');

  /// When the segment was created.
  DateTime get createdAt => dateTimeField('created_at');

  /// The raw object discriminator, when returned by Resend.
  String? get object => optionalField<String>('object');
}

/// Operations for managing contact segments and their contacts.
final class SegmentsResource {
  /// Creates a segments resource client.
  SegmentsResource(this._transport);

  /// Transport used to execute segment endpoint requests.
  final ResendTransport _transport;

  /// Creates a segment.
  Future<ResendResponse<ResendId>> create(CreateSegmentRequest request) {
    return _transport.post<ResendId>(
      pathSegments: <String>['segments'],
      body: request.toJson(),
      decode: ResendId.fromJson,
    );
  }

  /// Lists segments using cursor pagination.
  Future<ResendResponse<ResendPage<Segment>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<Segment>>(
      pathSegments: <String>['segments'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<Segment>.fromJson(json, Segment.fromJson),
    );
  }

  /// Retrieves a segment by [id].
  Future<ResendResponse<Segment>> retrieve(String id) {
    return _transport.get<Segment>(
      pathSegments: <String>['segments', requireNonBlank(id, 'id')],
      decode: Segment.fromJson,
    );
  }

  /// Deletes a segment by [id].
  Future<ResendResponse<ResendDeletion>> delete(String id) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>['segments', requireNonBlank(id, 'id')],
      decode: ResendDeletion.fromJson,
    );
  }

  /// Lists the contacts that belong to the segment identified by [id].
  Future<ResendResponse<ResendPage<Contact>>> listContacts(
    String id, {
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<Contact>>(
      pathSegments: <String>['segments', requireNonBlank(id, 'id'), 'contacts'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<Contact>.fromJson(json, Contact.fromJson),
    );
  }
}
