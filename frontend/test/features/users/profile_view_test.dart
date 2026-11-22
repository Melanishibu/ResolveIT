import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/dashboard/dashboard.dart';
import 'package:resolveit/features/users/users.dart';

import '../../support/auth_fakes.dart';
import '../../support/test_app.dart';

/// RIT-US-27 (AB#50) My Profile and Change Password screen.
void main() {
  group('Scenario: User sees their profile', () {
    testWidgets(
      'Given the logged-in Employee in Finance, when they open Profile, then they see their details',
      (tester) async {
        final profile = UserProfile(
          name: 'Employee One',
          email: 'employee1@resolveit.local',
          role: Role.employee,
          roleLabel: 'Employee',
          department: 'Finance',
          memberSince: DateTime.utc(2026, 1, 15, 10, 0),
        );
        await _openProfile(
          tester,
          profiles: FakeUserProfileRepository(profile: profile),
        );

        // Summary Card
        expect(find.byKey(const Key('profile-avatar')), findsOneWidget);
        expect(find.text('EO'), findsOneWidget);
        expect(find.byKey(const Key('profile-summary-name')), findsOneWidget);
        expect(find.text('Employee One'), findsWidgets);
        expect(find.byKey(const Key('profile-summary-email')), findsOneWidget);
        expect(find.text('employee1@resolveit.local'), findsWidgets);
        expect(find.byKey(const Key('profile-role-chip')), findsOneWidget);

        // Personal Info Tab
        expect(find.byKey(const Key('profile-name-value')), findsOneWidget);
        expect(find.byKey(const Key('profile-email-value')), findsOneWidget);
        expect(find.byKey(const Key('profile-role-value')), findsOneWidget);
        expect(find.text(l10nEn.roleEmployee), findsWidgets);
        expect(
          find.byKey(const Key('profile-department-value')),
          findsOneWidget,
        );
        expect(find.text('Finance'), findsOneWidget);
        expect(
          find.byKey(const Key('profile-member-since-value')),
          findsOneWidget,
        );
      },
    );
  });

  group('Scenario: User changes their password', () {
    testWidgets(
      'When entering valid current and matching new password, password is changed',
      (tester) async {
        final passwords = FakePasswords();
        await _openProfile(tester, passwords: passwords);

        // Switch to Security tab
        await tester.tap(find.byKey(const Key('profile-tab-security')));
        await tester.pumpAndSettle();

        await _enter(tester, 'profile-current-password', 'OldPass123456');
        await _enter(tester, 'profile-new-password', 'NewPass123456');
        await _enter(tester, 'profile-confirm-password', 'NewPass123456');

        await tester.tap(
          find.byKey(const Key('profile-change-password-submit')),
        );
        await tester.pumpAndSettle();

        expect(passwords.changeCalls.length, 1);
        expect(passwords.changeCalls.single, (
          'OldPass123456',
          'NewPass123456',
        ));
        expect(find.text(l10nEn.profilePasswordChangedSuccess), findsOneWidget);
      },
    );
  });

  group('Scenario: Wrong current password', () {
    testWidgets(
      'When entering wrong current password, 400 AUTH_CURRENT_PASSWORD_WRONG is shown',
      (tester) async {
        final passwords = FakePasswords(
          failure: ApiFailure(
            code: 'AUTH_CURRENT_PASSWORD_WRONG',
            httpStatus: 400,
          ),
        );
        await _openProfile(tester, passwords: passwords);

        await tester.tap(find.byKey(const Key('profile-tab-security')));
        await tester.pumpAndSettle();

        await _enter(tester, 'profile-current-password', 'WrongPassword1');
        await _enter(tester, 'profile-new-password', 'NewPass123456');
        await _enter(tester, 'profile-confirm-password', 'NewPass123456');

        await tester.tap(
          find.byKey(const Key('profile-change-password-submit')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile-password-error')), findsOneWidget);
        expect(
          find.text(l10nEn.errorAuthCurrentPasswordWrongTitle),
          findsOneWidget,
        );
      },
    );
  });

  group('Scenario: New password must follow the policy', () {
    testWidgets(
      'When new password is abc, 400 PASSWORD_POLICY_VIOLATION is shown',
      (tester) async {
        final passwords = FakePasswords(
          failure: ApiFailure(
            code: 'PASSWORD_POLICY_VIOLATION',
            httpStatus: 400,
          ),
        );
        await _openProfile(tester, passwords: passwords);

        await tester.tap(find.byKey(const Key('profile-tab-security')));
        await tester.pumpAndSettle();

        await _enter(tester, 'profile-current-password', 'CurrentPass123');
        await _enter(tester, 'profile-new-password', 'abc');
        await _enter(tester, 'profile-confirm-password', 'abc');

        await tester.tap(
          find.byKey(const Key('profile-change-password-submit')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile-password-error')), findsOneWidget);
        expect(
          find.text(l10nEn.errorPasswordPolicyViolationTitle),
          findsOneWidget,
        );
      },
    );
  });

  group('Scenario: New password must differ from the current one', () {
    testWidgets(
      'When new password equals current password, 400 PASSWORD_SAME_AS_CURRENT is shown',
      (tester) async {
        final passwords = FakePasswords(
          failure: ApiFailure(
            code: 'PASSWORD_SAME_AS_CURRENT',
            httpStatus: 400,
          ),
        );
        await _openProfile(tester, passwords: passwords);

        await tester.tap(find.byKey(const Key('profile-tab-security')));
        await tester.pumpAndSettle();

        await _enter(tester, 'profile-current-password', 'CurrentPass123');
        await _enter(tester, 'profile-new-password', 'CurrentPass123');
        await _enter(tester, 'profile-confirm-password', 'CurrentPass123');

        await tester.tap(
          find.byKey(const Key('profile-change-password-submit')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile-password-error')), findsOneWidget);
        expect(
          find.text(l10nEn.errorPasswordSameAsCurrentTitle),
          findsOneWidget,
        );
      },
    );
  });

  group('Client-side validation', () {
    testWidgets(
      'When new and confirm passwords do not match, inline error is shown and nothing is sent',
      (tester) async {
        final passwords = FakePasswords();
        await _openProfile(tester, passwords: passwords);

        await tester.tap(find.byKey(const Key('profile-tab-security')));
        await tester.pumpAndSettle();

        await _enter(tester, 'profile-current-password', 'CurrentPass123');
        await _enter(tester, 'profile-new-password', 'NewPassword123');
        await _enter(tester, 'profile-confirm-password', 'DifferentPass123');

        await tester.tap(
          find.byKey(const Key('profile-change-password-submit')),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10nEn.profilePasswordsDoNotMatch), findsOneWidget);
        expect(passwords.changeCalls, isEmpty);
      },
    );
  });

  group('Profile loading failure', () {
    testWidgets('Displays error panel when profile cannot be loaded', (
      tester,
    ) async {
      await _openProfile(
        tester,
        profiles: FakeUserProfileRepository(
          failure: ApiFailure(code: 'INTERNAL_SERVER_ERROR', httpStatus: 500),
        ),
      );

      expect(find.byKey(const Key('profile-load-error')), findsOneWidget);
    });
  });
}

final class FakeUserProfileRepository implements UserProfileRepository {
  FakeUserProfileRepository({this.profile, this.failure});

  final UserProfile? profile;
  final ApiFailure? failure;

  @override
  Future<Result<UserProfile>> getMyProfile() async {
    final refused = failure;
    if (refused != null) return Failure(refused);
    return Success(
      profile ??
          UserProfile(
            name: 'Employee One',
            email: 'employee1@resolveit.local',
            role: Role.employee,
            roleLabel: 'Employee',
            department: 'Finance',
            memberSince: DateTime.utc(2026, 1, 15, 10, 0),
          ),
    );
  }
}

final class FakePasswords implements PasswordRepository {
  FakePasswords({this.failure});

  final ApiFailure? failure;
  final changeCalls = <(String, String)>[];

  @override
  Future<Result<void>> setPassword({
    required String token,
    required String newPassword,
  }) async => const Success(null);

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final refused = failure;
    if (refused != null) return Failure(refused);
    changeCalls.add((currentPassword, newPassword));
    return const Success(null);
  }
}

Future<void> _openProfile(
  WidgetTester tester, {
  FakeUserProfileRepository? profiles,
  FakePasswords? passwords,
  Role role = Role.employee,
}) async {
  final backend = FakeIdentityBackend.signedInAs(role);
  tester.view.physicalSize = const Size(1440, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserRepositoryProvider.overrideWithValue(backend),
        sessionRepositoryProvider.overrideWithValue(backend),
        userProfileRepositoryProvider.overrideWithValue(
          profiles ??
              FakeUserProfileRepository(
                profile: UserProfile(
                  name: 'Employee One',
                  email: 'employee1@resolveit.local',
                  role: role,
                  roleLabel: role == Role.supportAgent
                      ? 'Technician'
                      : (role == Role.admin ? 'Administrator' : 'Employee'),
                  department: 'Finance',
                  memberSince: DateTime.utc(2026, 1, 15, 10, 0),
                ),
              ),
        ),
        passwordRepositoryProvider.overrideWithValue(
          passwords ?? FakePasswords(),
        ),
        dashboardRepositoryProvider.overrideWithValue(const _FakeDashboard()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  _router(tester).go('/profile');
  await tester.pumpAndSettle();
}

final class _FakeDashboard implements DashboardRepository {
  const _FakeDashboard();

  @override
  Future<Result<DashboardCounts>> counts() async => const Success(
    DashboardCounts(
      total: 8,
      open: 3,
      assigned: 2,
      inProgress: 1,
      resolved: 1,
      critical: 2,
    ),
  );

  @override
  Future<Result<List<ActivityEntry>>> activity({int limit = 10}) async =>
      const Success([]);

  @override
  Future<Result<List<RecentIncident>>> recentAssigned({int limit = 5}) async =>
      const Success([]);
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

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));
