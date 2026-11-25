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

/// RIT-US-06 (AB#48) create-user screen, through the real composition root.
void main() {
  testWidgets('Admin creates a Technician from the form', (tester) async {
    final users = FakeUserAdmin();
    await _openForm(tester, users);

    await _enter(tester, 'create-user-name', 'Asha Rao');
    await _enter(tester, 'create-user-email', 'asha@resolveit.local');
    await _chooseRole(tester, l10nEn.roleSupportAgent);
    await _enter(tester, 'create-user-department', 'IT Support');
    await tester.tap(find.byKey(const Key('create-user-submit')));
    await tester.pumpAndSettle();

    expect(users.created.single.role, Role.supportAgent);
    expect(users.created.single.department, 'IT Support');
    expect(
      find.text(l10nEn.createUserSuccess('asha@resolveit.local')),
      findsOneWidget,
    );
    expect(_router(tester).state.uri.path, '/admin/users');
  });

  testWidgets('The role dropdown offers only Technician and Employee', (
    tester,
  ) async {
    await _openForm(tester, FakeUserAdmin());

    await tester.tap(find.byKey(const Key('create-user-role')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.roleSupportAgent), findsWidgets);
    expect(find.text(l10nEn.roleEmployee), findsWidgets);
    expect(
      find.text(l10nEn.roleAdmin),
      findsOneWidget,
      reason: 'only the top bar of the signed-in Admin, not an option',
    );
  });

  testWidgets('Required fields are checked before anything is sent', (
    tester,
  ) async {
    final users = FakeUserAdmin();
    await _openForm(tester, users);

    await tester.tap(find.byKey(const Key('create-user-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.createUserNameRequired), findsOneWidget);
    expect(find.text(l10nEn.createUserEmailRequired), findsOneWidget);
    expect(find.text(l10nEn.createUserRoleRequired), findsOneWidget);
    expect(find.text(l10nEn.createUserDepartmentRequired), findsOneWidget);
    expect(users.created, isEmpty);
  });

  testWidgets('A taken email is explained through the error panel', (
    tester,
  ) async {
    final users = FakeUserAdmin(
      failure: ApiFailure(
        code: 'USER_EMAIL_TAKEN',
        params: const {'email': 'employee1@resolveit.local'},
        httpStatus: 409,
      ),
    );
    await _openForm(tester, users);

    await _enter(tester, 'create-user-name', 'Someone');
    await _enter(tester, 'create-user-email', 'EMPLOYEE1@resolveit.local');
    await _chooseRole(tester, l10nEn.roleEmployee);
    await _enter(tester, 'create-user-department', 'Finance');
    await tester.tap(find.byKey(const Key('create-user-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-user-error')), findsOneWidget);
    expect(find.text(l10nEn.errorUserEmailTakenTitle), findsOneWidget);
    expect(_router(tester).state.uri.path, '/admin/users/new');
  });

  testWidgets('Only Admins can open the form', (tester) async {
    await _pumpApp(
      tester,
      FakeIdentityBackend.signedInAs(Role.supportAgent),
      FakeUserAdmin(),
    );

    _router(tester).go('/admin/users/new');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-allowed-page')), findsOneWidget);
  });

  testWidgets('Cancel returns to user list without creating a user', (
    tester,
  ) async {
    final users = FakeUserAdmin();
    await _openForm(tester, users);

    await tester.tap(find.byKey(const Key('create-user-cancel')));
    await tester.pumpAndSettle();

    expect(_router(tester).state.uri.path, '/admin/users');
    expect(users.created, isEmpty);
  });

  testWidgets('Back button returns to user list', (tester) async {
    final users = FakeUserAdmin();
    await _openForm(tester, users);

    await tester.tap(find.byKey(const Key('create-user-back')));
    await tester.pumpAndSettle();

    expect(_router(tester).state.uri.path, '/admin/users');
  });
}

final class FakeUserAdmin implements UserAdminRepository {
  FakeUserAdmin({this.failure});

  final ApiFailure? failure;
  final created = <NewUser>[];

  @override
  Future<Result<CreatedUser>> createUser(NewUser user) async {
    final refused = failure;
    if (refused != null) return Failure(refused);
    created.add(user);
    return Success(CreatedUser(id: 'u-9', email: user.email.trim()));
  }
}

Future<void> _openForm(WidgetTester tester, FakeUserAdmin users) async {
  await _pumpApp(tester, FakeIdentityBackend.signedInAs(Role.admin), users);
  _router(tester).go('/admin/users/new');
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('create-user-submit')), findsOneWidget);
}

Future<void> _pumpApp(
  WidgetTester tester,
  FakeIdentityBackend backend,
  FakeUserAdmin users,
) async {
  tester.view.physicalSize = const Size(1440, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserRepositoryProvider.overrideWithValue(backend),
        sessionRepositoryProvider.overrideWithValue(backend),
        userAdminRepositoryProvider.overrideWithValue(users),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String fieldKey, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(Key(fieldKey)),
      matching: find.byType(EditableText),
    ),
    text,
  );
  await tester.pump();
}

Future<void> _chooseRole(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('create-user-role')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));
