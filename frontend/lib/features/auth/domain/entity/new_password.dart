/// Why the set-password form can't be sent yet.
enum NewPasswordProblem { passwordMissing, confirmationMissing, mismatch }

/// What the user typed into the set-password form (RIT-US-07). The backend checks the password policy;
/// the form only makes sure both fields are filled and match, so nothing is sent otherwise.
final class NewPassword {
  const NewPassword({
    required this.token,
    required this.password,
    required this.confirmation,
  });

  /// From the link's `token` query parameter.
  final String token;
  final String password;
  final String confirmation;

  Set<NewPasswordProblem> get problems => {
    if (password.isEmpty) NewPasswordProblem.passwordMissing,
    if (confirmation.isEmpty) NewPasswordProblem.confirmationMissing,
    if (password.isNotEmpty &&
        confirmation.isNotEmpty &&
        password != confirmation)
      NewPasswordProblem.mismatch,
  };

  /// Never print the password.
  @override
  String toString() => 'NewPassword(***)';
}
