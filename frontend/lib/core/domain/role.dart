/// A user's role. The codes match the backend API; the UI shows SUPPORT_AGENT as "Technician".
enum Role {
  admin('ADMIN'),
  supportAgent('SUPPORT_AGENT'),
  employee('EMPLOYEE');

  const Role(this.code);

  final String code;

  /// Parses an API role code; returns null for an unknown code.
  static Role? tryParse(String code) {
    final normalised = code.trim().toUpperCase();
    for (final role in values) {
      if (role.code == normalised) return role;
    }
    return null;
  }
}
