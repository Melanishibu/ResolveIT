import 'package:resolveit/core/domain/role.dart';

/// Whether [role] may create incidents. From the permission table in the common rules (AB#14):
/// Admin yes, Support Agent no, Employee yes. The backend enforces it (`Permission.CREATE_INCIDENT`);
/// the UI uses it to decide where users may go and which actions it shows (bug AB#181).
bool mayCreateIncident(Role role) =>
    role == Role.admin || role == Role.employee;
