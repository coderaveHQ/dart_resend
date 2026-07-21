import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// The event or action that added an address to the suppression list.
enum SuppressionOrigin implements ResendWireValue {
  /// A delivery bounce.
  bounce('bounce'),

  /// A recipient spam complaint.
  complaint('complaint'),

  /// A manually added suppression.
  manual('manual');

  const SuppressionOrigin(this.value);

  /// Wire value used when encoding this enum member.
  @override
  final String value;
}

/// A Resend suppression-list entry.
final class Suppression extends ResendModel {
  /// Decodes a suppression.
  Suppression.fromJson(super.json);

  /// The suppression ID.
  String get id => field<String>('id');

  /// The suppressed email address.
  String get email => field<String>('email');

  /// The raw suppression origin, kept forward-compatible with new values.
  String get origin => field<String>('origin');

  /// The email or event that caused the suppression, when available.
  String? get sourceId => optionalField<String>('source_id');

  /// When the suppression was created.
  DateTime get createdAt => dateTimeField('created_at');
}

/// Selects suppressions to remove in a batch.
final class RemoveSuppressionsRequest implements ResendRequest {
  /// Creates a removal payload containing exactly one identifier kind.
  RemoveSuppressionsRequest._({this.emails, this.ids});

  /// Removes suppressions matching email addresses.
  factory RemoveSuppressionsRequest.byEmails(List<String> emails) {
    return RemoveSuppressionsRequest._(
      emails: _validatedBatch(emails, 'emails'),
    );
  }

  /// Removes suppressions matching suppression IDs.
  factory RemoveSuppressionsRequest.byIds(List<String> ids) {
    return RemoveSuppressionsRequest._(ids: _validatedBatch(ids, 'ids'));
  }

  /// Email addresses selected for removal, when using [byEmails].
  final List<String>? emails;

  /// Suppression IDs selected for removal, when using [byIds].
  final List<String>? ids;

  /// Encodes this value as a Resend API JSON object.
  @override
  JsonObject toJson() =>
      compactJson(<String, Object?>{'emails': emails, 'ids': ids});
}

/// Suppression-list operations.
///
/// Resend currently labels this API as private beta. Availability therefore
/// depends on the authenticated team's feature access.
final class SuppressionsResource {
  /// Creates a suppressions resource client.
  SuppressionsResource(this._transport);

  /// Transport used to execute suppression endpoint requests.
  final ResendTransport _transport;

  /// Adds [email] to the suppression list.
  Future<ResendResponse<ResendId>> add(String email) {
    return _transport.post<ResendId>(
      pathSegments: <String>['suppressions'],
      body: <String, Object?>{'email': requireNonBlank(email, 'email')},
      decode: ResendId.fromJson,
    );
  }

  /// Adds between 1 and 100 [emails] in one request.
  Future<ResendResponse<ResendCollection<ResendId>>> addBatch(
    List<String> emails,
  ) {
    return _transport.post<ResendCollection<ResendId>>(
      pathSegments: <String>['suppressions', 'batch', 'add'],
      body: <String, Object?>{'emails': _validatedBatch(emails, 'emails')},
      decode: (JsonObject json) =>
          ResendCollection<ResendId>.fromJson(json, ResendId.fromJson),
    );
  }

  /// Retrieves a suppression by ID or email address.
  Future<ResendResponse<Suppression>> retrieve(String idOrEmail) {
    return _transport.get<Suppression>(
      pathSegments: <String>[
        'suppressions',
        requireNonBlank(idOrEmail, 'idOrEmail'),
      ],
      decode: Suppression.fromJson,
    );
  }

  /// Lists suppressions, optionally filtered by [origin].
  Future<ResendResponse<ResendPage<Suppression>>> list({
    SuppressionOrigin? origin,
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<Suppression>>(
      pathSegments: <String>['suppressions'],
      query: <String, String>{
        ...?pagination?.toQuery(),
        if (origin != null) 'origin': origin.value,
      },
      decode: (JsonObject json) =>
          ResendPage<Suppression>.fromJson(json, Suppression.fromJson),
    );
  }

  /// Removes one suppression by ID or email address.
  Future<ResendResponse<ResendDeletion>> remove(String idOrEmail) {
    return _transport.delete<ResendDeletion>(
      pathSegments: <String>[
        'suppressions',
        requireNonBlank(idOrEmail, 'idOrEmail'),
      ],
      decode: ResendDeletion.fromJson,
    );
  }

  /// Removes up to 100 suppressions selected by email address or ID.
  Future<ResendResponse<ResendCollection<ResendDeletion>>> removeBatch(
    RemoveSuppressionsRequest request,
  ) {
    return _transport.post<ResendCollection<ResendDeletion>>(
      pathSegments: <String>['suppressions', 'batch', 'remove'],
      body: request.toJson(),
      decode: (JsonObject json) => ResendCollection<ResendDeletion>.fromJson(
        json,
        ResendDeletion.fromJson,
      ),
    );
  }
}

/// Validates, copies, and freezes a bounded suppression batch.
List<String> _validatedBatch(List<String> values, String name) {
  if (values.isEmpty || values.length > 100) {
    throw RangeError.range(values.length, 1, 100, name);
  }
  return List<String>.unmodifiable(
    values.map((String value) => requireNonBlank(value, name)),
  );
}
