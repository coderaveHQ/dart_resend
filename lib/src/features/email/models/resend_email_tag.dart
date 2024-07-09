/// Email tag
class ResendEmailTag {
  /// The name of the email tag.
  /// It can only contain ASCII letters (a–z, A–Z), numbers (0–9), underscores (_), or dashes (-).
  /// It can contain no more than 256 characters.
  final String name;

  /// The value of the email tag.
  /// It can only contain ASCII letters (a–z, A–Z), numbers (0–9), underscores (_), or dashes (-).
  /// It can contain no more than 256 characters.
  final String value;

  /// Regex for checking the contents
  final RegExp _regex = RegExp(r'^[a-zA-Z0-9_-]+$');

  /// Constructor of ResendEmailTag
  ResendEmailTag({required this.name, required this.value}) {
    // Validation
    assert(_regex.hasMatch(name),
        'E-Mail tag name can only contain ASCII letters (a–z, A–Z), numbers (0–9), underscores (_), or dashes (-).');
    assert(name.length <= 256,
        'E-Mail tag name can only contain up to 256 characters.');
    assert(_regex.hasMatch(value),
        'E-Mail tag value can only contain ASCII letters (a–z, A–Z), numbers (0–9), underscores (_), or dashes (-).');
    assert(value.length <= 256,
        'E-Mail tag value can only contain up to 256 characters.');
  }
}
