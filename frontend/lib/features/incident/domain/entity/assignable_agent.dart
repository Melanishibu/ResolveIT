/// An active Technician an Admin can assign an incident to (RIT-US-14).
final class AssignableAgent {
  const AssignableAgent({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;
}
