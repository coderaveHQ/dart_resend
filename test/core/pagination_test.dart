import 'package:dart_resend/src/core/pagination.dart';
import 'package:test/test.dart';

/// Registers this file's test cases with the package:test runner.
void main() {
  // Covers: PaginationOptions.
  group('PaginationOptions', () {
    // Verifies: serializes empty and bounded limits.
    test('serializes empty and bounded limits', () {
      expect(PaginationOptions().toQuery(), isEmpty);
      expect(PaginationOptions(limit: 1).toQuery(), <String, String>{
        'limit': '1',
      });
      final Map<String, String> query = PaginationOptions(limit: 100).toQuery();
      expect(query, <String, String>{'limit': '100'});
      expect(() => query['other'] = 'value', throwsUnsupportedError);
    });

    // Verifies: serializes either cursor.
    test('serializes either cursor', () {
      expect(PaginationOptions(after: 'next').toQuery(), <String, String>{
        'after': 'next',
      });
      expect(PaginationOptions(before: 'previous').toQuery(), <String, String>{
        'before': 'previous',
      });
    });

    // Verifies: rejects out-of-range limits.
    test('rejects out-of-range limits', () {
      expect(() => PaginationOptions(limit: 0), throwsRangeError);
      expect(() => PaginationOptions(limit: 101), throwsRangeError);
    });

    // Verifies: rejects empty and conflicting cursors.
    test('rejects empty and conflicting cursors', () {
      expect(() => PaginationOptions(after: ''), throwsArgumentError);
      expect(() => PaginationOptions(before: ''), throwsArgumentError);
      expect(
        () => PaginationOptions(after: 'next', before: 'previous'),
        throwsArgumentError,
      );
    });
  });
}
