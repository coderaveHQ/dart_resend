import 'dart:io';

import 'package:test/test.dart';

/// Registers this file's test cases with the package:test runner.
void main() {
  final Directory temporaryDirectory = Directory.systemTemp.createTempSync(
    'dart_resend_coverage_test.',
  );

  tearDownAll(() {
    temporaryDirectory.deleteSync(recursive: true);
  });

  // Verifies: coverage checker accepts a complete report.
  test('coverage checker accepts a complete report', () async {
    final File report = File('${temporaryDirectory.path}/complete.info')
      ..writeAsStringSync('LF:2\nLH:2\n');
    final ProcessResult result = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'tool/check_coverage.dart', report.path],
    );

    expect(result.exitCode, 0);
    expect(result.stdout, contains('100.00%'));
  });

  // Verifies: coverage checker rejects incomplete and empty reports.
  test('coverage checker rejects incomplete and empty reports', () async {
    final File incomplete = File('${temporaryDirectory.path}/incomplete.info')
      ..writeAsStringSync('LF:2\nLH:1\n');
    final ProcessResult incompleteResult = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'tool/check_coverage.dart', incomplete.path],
    );
    expect(incompleteResult.exitCode, 1);
    expect(incompleteResult.stderr, contains('Expected 100.00%'));

    final File empty = File('${temporaryDirectory.path}/empty.info')
      ..writeAsStringSync('TN:dart_resend\n');
    final ProcessResult emptyResult = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'tool/check_coverage.dart', empty.path],
    );
    expect(emptyResult.exitCode, 1);
    expect(emptyResult.stderr, contains('does not contain executable'));
  });

  // Verifies: coverage checker rejects a missing report.
  test('coverage checker rejects a missing report', () async {
    final ProcessResult result = await Process.run(
      Platform.resolvedExecutable,
      <String>[
        'run',
        'tool/check_coverage.dart',
        '${temporaryDirectory.path}/missing.info',
      ],
    );

    expect(result.exitCode, 1);
    expect(result.stderr, contains('Coverage report not found'));
  });
}
