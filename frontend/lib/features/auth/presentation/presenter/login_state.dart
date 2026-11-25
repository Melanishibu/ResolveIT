import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/features/auth/domain/entity/login_credentials.dart';

/// State of the login screen.
final class LoginState {
  const LoginState({
    this.missingFields = const {},
    this.isSubmitting = false,
    this.failure,
  });

  /// Required fields that were empty on submit.
  final Set<LoginField> missingFields;

  /// A login request is in flight.
  final bool isSubmitting;

  /// The backend refused the login (shown through the structured error panel).
  final ApiFailure? failure;
}
