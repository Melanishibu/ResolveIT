import 'package:resolveit/core/domain/role.dart';

/// The user profile (RIT-US-27, GET /users/me).
final class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.roleLabel,
    required this.department,
    required this.memberSince,
  });

  final String name;
  final String email;
  final Role role;
  final String roleLabel;
  final String department;
  final DateTime memberSince;

  /// Up to two initials for the avatar (first letters of first and last word in name).
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
