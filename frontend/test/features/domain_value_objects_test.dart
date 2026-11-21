import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/incident/incident.dart';

void main() {
  group('Role', () {
    test('parses API codes, case-insensitively', () {
      expect(Role.tryParse('ADMIN'), Role.admin);
      expect(Role.tryParse('support_agent'), Role.supportAgent);
      expect(Role.tryParse(' EMPLOYEE '), Role.employee);
    });

    test('returns null for an unknown code', () {
      expect(
        Role.tryParse('TECHNICIAN'),
        isNull,
        reason: 'Technician is a UI label, not a code',
      );
    });
  });

  group('CurrentUser', () {
    CurrentUser user(String name) =>
        CurrentUser(id: 'u-1', displayName: name, role: Role.employee);

    test('initials use the first two words', () {
      expect(user('Sarah Johnson').initials, 'SJ');
      expect(user('anna maria lopez').initials, 'AM');
      expect(user('Cher').initials, 'C');
      expect(user('  David   Chen ').initials, 'DC');
    });

    test('rejects a blank id or name', () {
      expect(
        () => CurrentUser(id: ' ', displayName: 'A', role: Role.admin),
        throwsArgumentError,
      );
      expect(
        () => CurrentUser(id: 'u', displayName: '', role: Role.admin),
        throwsArgumentError,
      );
    });
  });

  group('Priority and IncidentStatus', () {
    test('parse every API code', () {
      expect(
        Priority.values.map((p) => Priority.fromCode(p.code)),
        Priority.values,
      );
      expect(IncidentStatus.fromCode('IN_PROGRESS'), IncidentStatus.inProgress);
      expect(
        IncidentStatus.values.map((s) => IncidentStatus.fromCode(s.code)),
        IncidentStatus.values,
      );
    });

    test('reject unknown codes', () {
      expect(() => Priority.fromCode('URGENT'), throwsArgumentError);
      expect(() => IncidentStatus.fromCode('REOPENED'), throwsArgumentError);
    });
  });

  group('ApiFailure', () {
    test(
      '4xx is a warning; 5xx, missing status and network failures are errors',
      () {
        expect(
          ApiFailure(code: 'X', httpStatus: 404).severity,
          FailureSeverity.warning,
        );
        expect(
          ApiFailure(code: 'X', httpStatus: 500).severity,
          FailureSeverity.error,
        );
        expect(ApiFailure(code: 'X').severity, FailureSeverity.error);
        expect(ApiFailure.networkUnavailable().severity, FailureSeverity.error);
      },
    );

    test('exposes the trace id and rejects a blank code', () {
      expect(
        ApiFailure(code: 'INTERNAL_ERROR', params: {'traceId': 't-1'}).traceId,
        't-1',
      );
      expect(() => ApiFailure(code: ' '), throwsArgumentError);
    });
  });
}
