/// Incident priority, as defined by the backend API.
enum Priority {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH'),
  critical('CRITICAL');

  const Priority(this.code);

  final String code;

  /// Parses an API priority code; throws [ArgumentError] for an unknown code.
  static Priority fromCode(String code) => values.firstWhere(
    (priority) => priority.code == code,
    orElse: () => throw ArgumentError.value(code, 'code', 'unknown priority'),
  );
}
