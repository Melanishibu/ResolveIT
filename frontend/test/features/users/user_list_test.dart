import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/users/users.dart';

import '../../support/auth_fakes.dart';
import '../../support/test_app.dart';

/// RIT-US-08 (AB#50) user-list screen, through the real composition root.
void main() {
  testWidgets('Admin sees all users with their status', (tester) async {
    final directory = FakeDirectory(_users(25));
    await _openList(tester, directory);

    expect(directory.requests.last.page, 0);
    expect(find.byKey(const Key('user-list-table')), findsOneWidget);
    expect(find.text('user01@resolveit.local'), findsOneWidget);
    expect(
      find.text('user21@resolveit.local'),
      findsNothing,
      reason: '20 per page',
    );
    expect(
      find.textContaining('25'),
      findsWidgets,
      reason: 'total in the footer',
    );
    expect(
      find.text(l10nEn.roleSupportAgent),
      findsWidgets,
      reason: 'Technician',
    );
    expect(find.text(l10nEn.userInactive), findsWidgets);
    expect(find.text(l10nEn.invitationPending), findsWidgets);
  });

  testWidgets('Admin deactivates an Agent', (tester) async {
    final directory = FakeDirectory(_users(3));
    await _openList(tester, directory);

    await tester.tap(
      find.byKey(const Key('user-deactivate-user01@resolveit.local')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(l10nEn.userListDeactivateMessage),
      findsOneWidget,
      reason: 'confirm dialog',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10nEn.userListDeactivate).last,
    );
    await tester.pumpAndSettle();

    expect(directory.statusCalls.single, ('id-01', false));
    expect(
      find.byKey(const Key('user-activate-user01@resolveit.local')),
      findsOneWidget,
    );
    expect(find.text(l10nEn.userListDeactivated('User 01')), findsOneWidget);
  });

  testWidgets('Admin reactivates a user', (tester) async {
    final directory = FakeDirectory(_users(3));
    await _openList(tester, directory);

    await tester.tap(
      find.byKey(const Key('user-activate-user02@resolveit.local')),
    );
    await tester.pumpAndSettle();

    expect(directory.statusCalls.single, ('id-02', true));
    expect(
      find.byKey(const Key('user-deactivate-user02@resolveit.local')),
      findsOneWidget,
    );
    expect(find.text(l10nEn.userListActivated('User 02')), findsOneWidget);
  });

  testWidgets('Admin cannot deactivate themselves', (tester) async {
    final directory = FakeDirectory(
      [
        ..._users(2),
        const UserSummary(
          id: 'u-2',
          name: 'Agent One',
          email: 'me@resolveit.local',
          role: Role.admin,
          department: 'IT',
          isActive: true,
          invitationStatus: InvitationStatus.accepted,
        ),
      ],
      failure: ApiFailure(code: 'USER_CANNOT_DEACTIVATE_SELF', httpStatus: 409),
    );
    await _openList(tester, directory);

    expect(
      find.byKey(const Key('user-deactivate-me@resolveit.local')),
      findsNothing,
      reason: 'no Deactivate on the signed-in Admin row',
    );
    await tester.tap(
      find.byKey(const Key('user-deactivate-user01@resolveit.local')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, l10nEn.userListDeactivate).last,
    );
    await tester.pumpAndSettle();
    expect(
      find.text(l10nEn.errorUserCannotDeactivateSelfTitle),
      findsOneWidget,
      reason: 'a refusal from the backend is explained',
    );
  });

  testWidgets('Only Admins see the user list', (tester) async {
    await _pumpApp(
      tester,
      FakeIdentityBackend.signedInAs(Role.employee),
      FakeDirectory(_users(1)),
    );

    _router(tester).go('/admin/users');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-allowed-page')), findsOneWidget);
  });
}

List<UserSummary> _users(int count) => [
  for (var i = 1; i <= count; i++)
    UserSummary(
      id: 'id-${i.toString().padLeft(2, '0')}',
      name: 'User ${i.toString().padLeft(2, '0')}',
      email: 'user${i.toString().padLeft(2, '0')}@resolveit.local',
      role: i.isOdd ? Role.supportAgent : Role.employee,
      department: 'IT',
      isActive: i.isOdd,
      invitationStatus: i.isOdd
          ? InvitationStatus.accepted
          : InvitationStatus.pending,
    ),
];

final class FakeDirectory implements UserDirectoryRepository {
  FakeDirectory(this.users, {this.failure});

  final List<UserSummary> users;
  final ApiFailure? failure;
  final requests = <UserListFilter>[];
  final statusCalls = <(String, bool)>[];

  @override
  Future<Result<UserPage>> listUsers(UserListFilter filter) async {
    requests.add(filter);
    final start = filter.page * UserListFilter.pageSize;
    return Success(
      UserPage(
        items: users.skip(start).take(UserListFilter.pageSize).toList(),
        totalItems: users.length,
      ),
    );
  }

  @override
  Future<Result<UserSummary>> setActive(
    String userId, {
    required bool active,
  }) async {
    final refused = failure;
    if (refused != null) return Failure(refused);
    statusCalls.add((userId, active));
    final user = users.firstWhere((u) => u.id == userId);
    return Success(
      UserSummary(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        department: user.department,
        isActive: active,
        invitationStatus: user.invitationStatus,
      ),
    );
  }
}

Future<void> _openList(WidgetTester tester, FakeDirectory directory) async {
  await _pumpApp(tester, FakeIdentityBackend.signedInAs(Role.admin), directory);
  _router(tester).go('/admin/users');
  await tester.pumpAndSettle();
}

Future<void> _pumpApp(
  WidgetTester tester,
  FakeIdentityBackend backend,
  FakeDirectory directory,
) async {
  // Wide enough for all seven columns; narrower windows scroll the table sideways.
  tester.view.physicalSize = const Size(2200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserRepositoryProvider.overrideWithValue(backend),
        sessionRepositoryProvider.overrideWithValue(backend),
        userDirectoryRepositoryProvider.overrideWithValue(directory),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));
