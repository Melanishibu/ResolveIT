/// Incident lifecycle status, as defined by the backend API.
enum IncidentStatus {
  open('OPEN'),
  assigned('ASSIGNED'),
  inProgress('IN_PROGRESS'),
  resolved('RESOLVED'),
  closed('CLOSED');

  const IncidentStatus(this.code);

  final String code;

  /// Parses an API status code; throws [ArgumentError] for an unknown code.
  static IncidentStatus fromCode(String code) => values.firstWhere(
    (status) => status.code == code,
    orElse: () => throw ArgumentError.value(code, 'code', 'unknown status'),
  );
}
