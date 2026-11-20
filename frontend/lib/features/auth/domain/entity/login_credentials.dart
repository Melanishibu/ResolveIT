/// A field of the login form.
enum LoginField { email, password }

/// What the user typed into the login form.
///
/// Mirrors the backend's required-field rule for instant feedback; the backend still enforces it.
final class LoginCredentials {
  const LoginCredentials({required this.email, required this.password});

  final String email;
  final String password;

  /// The fields that are empty. A login request is only sent when this is empty.
  Set<LoginField> get missingFields => {
    if (email.trim().isEmpty) LoginField.email,
    if (password.isEmpty) LoginField.password,
  };

  @override
  String toString() => 'LoginCredentials(email: $email, password: ***)';
}
