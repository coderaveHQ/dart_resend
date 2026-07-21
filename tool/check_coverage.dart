import 'dart:io';

/// Validates that an LCOV report records complete Dart line coverage.
void main(List<String> arguments) {
  // Accept an explicit report path for tests and CI while retaining the
  // conventional coverage output as the command-line default.
  final String path = arguments.isEmpty ? 'coverage/lcov.info' : arguments[0];
  final File report = File(path);
  if (!report.existsSync()) {
    stderr.writeln('Coverage report not found: $path');
    exitCode = 1;
    return;
  }

  var linesFound = 0;
  var linesHit = 0;
  // Aggregate all LCOV source records because each file contributes its own
  // lines-found and lines-hit counters.
  for (final String line in report.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      linesFound += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      linesHit += int.parse(line.substring(3));
    }
  }

  if (linesFound == 0) {
    stderr.writeln('Coverage report does not contain executable Dart lines.');
    exitCode = 1;
    return;
  }

  // Compute the display value only after guarding against a zero denominator.
  final double percentage = linesHit * 100 / linesFound;
  stdout.writeln(
    'Line coverage: $linesHit/$linesFound '
    '(${percentage.toStringAsFixed(2)}%)',
  );
  if (linesHit != linesFound) {
    stderr.writeln('Expected 100.00% line coverage.');
    exitCode = 1;
  }
}
