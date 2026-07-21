import '../core/pagination.dart';
import '../core/response.dart';
import '../core/transport.dart';
import '../models/base.dart';
import '../models/request.dart';

/// A Resend API request log.
final class ResendApiLog extends ResendModel {
  /// Decodes an API log.
  ResendApiLog.fromJson(super.json);

  /// The log ID.
  String get id => field<String>('id');

  /// When the request was recorded.
  DateTime get createdAt => dateTimeField('created_at');

  /// The called API endpoint.
  String get endpoint => field<String>('endpoint');

  /// The HTTP method used by the request.
  String get method => field<String>('method');

  /// The HTTP response status.
  int get responseStatus => field<int>('response_status');

  /// The request user agent, when reported.
  String? get userAgent => optionalField<String>('user_agent');

  /// The decoded request body, available on retrieve responses.
  Object? get requestBody => json['request_body'];

  /// The decoded response body, available on retrieve responses.
  Object? get responseBody => json['response_body'];
}

/// Operations for inspecting Resend API request logs.
final class LogsResource {
  /// Creates a logs resource client.
  LogsResource(this._transport);

  /// Transport used to execute API-log endpoint requests.
  final ResendTransport _transport;

  /// Lists API request logs.
  Future<ResendResponse<ResendPage<ResendApiLog>>> list({
    PaginationOptions? pagination,
  }) {
    return _transport.get<ResendPage<ResendApiLog>>(
      pathSegments: <String>['logs'],
      query: pagination?.toQuery(),
      decode: (JsonObject json) =>
          ResendPage<ResendApiLog>.fromJson(json, ResendApiLog.fromJson),
    );
  }

  /// Retrieves one API request log by [id].
  Future<ResendResponse<ResendApiLog>> retrieve(String id) {
    return _transport.get<ResendApiLog>(
      pathSegments: <String>['logs', requireNonBlank(id, 'id')],
      decode: ResendApiLog.fromJson,
    );
  }
}
