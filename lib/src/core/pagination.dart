/// Cursor-based pagination options accepted by Resend list endpoints.
final class PaginationOptions {
  /// Creates pagination options.
  ///
  /// [limit] must be between 1 and 100. [after] and [before] are mutually
  /// exclusive because they represent opposite traversal directions.
  PaginationOptions({this.limit, this.after, this.before}) {
    final int? value = limit;
    if (value != null && (value < 1 || value > 100)) {
      throw RangeError.range(value, 1, 100, 'limit');
    }
    if (after != null && after!.isEmpty) {
      throw ArgumentError.value(after, 'after', 'must not be empty');
    }
    if (before != null && before!.isEmpty) {
      throw ArgumentError.value(before, 'before', 'must not be empty');
    }
    if (after != null && before != null) {
      throw ArgumentError('Only one of after and before may be provided.');
    }
  }

  /// Maximum number of items to return.
  final int? limit;

  /// Cursor after which results are returned.
  final String? after;

  /// Cursor before which results are returned.
  final String? before;

  /// Converts these options to HTTP query parameters.
  Map<String, String> toQuery() {
    final Map<String, String> result = <String, String>{};
    if (limit != null) {
      result['limit'] = limit.toString();
    }
    if (after != null) {
      result['after'] = after!;
    }
    if (before != null) {
      result['before'] = before!;
    }
    return Map<String, String>.unmodifiable(result);
  }
}
