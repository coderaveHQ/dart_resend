import 'package:dart_resend/dart_resend.dart';

/// Lists API request logs.
Future<ResendResponse<ResendPage<ResendApiLog>>> listApiLogs(Resend resend) {
  return resend.logs.list(pagination: PaginationOptions(limit: 25));
}

/// Retrieves one API request log, including its request and response bodies.
Future<ResendResponse<ResendApiLog>> retrieveApiLog(
  Resend resend,
  String logId,
) {
  return resend.logs.retrieve(logId);
}
