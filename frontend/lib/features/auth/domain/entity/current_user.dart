import 'package:resolveit/core/domain/role.dart';

/// The signed-in user as the client knows them.
final class CurrentUser {
  CurrentUser({
    required this.id,
    required this.displayName,
    required this.role,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be blank');
    }
    if (displayName.trim().isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'must not be blank',
      );
    }
  }

  final String id;
  final String displayName;
  final Role role;

  /// Up to two initials for the avatar, e.g. "Sarah Johnson" → "SJ".
  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    final letters = words
        .take(2)
        .map((word) => word.substring(0, 1).toUpperCase());
    return letters.join();
  }

  @override
  bool operator ==(Object other) =>
      other is CurrentUser &&
      other.id == id &&
      other.displayName == displayName &&
      other.role == role;

  @override
  int get hashCode => Object.hash(id, displayName, role);
}
