import 'package:resolveit/features/identity/domain/role.dart';

/// A field of the create-user form.
enum NewUserField { name, email, role, department }

/// The roles an Admin may give a new user (RIT-US-06: Admins cannot create Admins).
const invitableRoles = [Role.supportAgent, Role.employee];

/// What the Admin typed into the create-user form (RIT-US-06).
///
/// Mirrors the backend's required-field rules for instant feedback; the backend still enforces them.
final class NewUser {
  const NewUser({
    required this.name,
    required this.email,
    required this.role,
    required this.department,
  });

  final String name;
  final String email;
  final Role? role;
  final String department;

  Set<NewUserField> get missingFields => {
    if (name.trim().isEmpty) NewUserField.name,
    if (email.trim().isEmpty) NewUserField.email,
    if (role == null) NewUserField.role,
    if (department.trim().isEmpty) NewUserField.department,
  };
}

/// The user the backend created; the invitation email goes to [email].
final class CreatedUser {
  const CreatedUser({required this.id, required this.email});

  final String id;
  final String email;
}
