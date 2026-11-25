/// Incident category, as defined by the backend API.
enum IncidentCategory {
  hardware('HARDWARE'),
  software('SOFTWARE'),
  network('NETWORK'),
  access('ACCESS'),
  other('OTHER');

  const IncidentCategory(this.code);

  final String code;
}
