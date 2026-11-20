package com.itsm.resolveit.identity.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The lockout invariant of the User aggregate (common rules: 5 failures → 15 minutes). */
class UserTest {

    private static final Instant NOW = Instant.parse("2026-11-20T10:00:00Z");
    private static final LoginLockoutPolicy POLICY = LoginLockoutPolicy.STANDARD;

    @Test
    void correctPasswordOnAnActiveAccountSucceeds() {
        User user = activeUser();

        assertThat(user.recordLoginAttempt(true, NOW, POLICY)).isEqualTo(LoginAttemptOutcome.SUCCEEDED);
        assertThat(user.failedLoginAttempts()).isZero();
    }

    @Test
    void wrongPasswordIsInvalidAndCounted() {
        User user = activeUser();

        assertThat(user.recordLoginAttempt(false, NOW, POLICY)).isEqualTo(LoginAttemptOutcome.INVALID_CREDENTIALS);
        assertThat(user.failedLoginAttempts()).isEqualTo(1);
        assertThat(user.isLockedAt(NOW)).isFalse();
    }

    @Test
    void theFifthConsecutiveFailureLocksTheAccountForFifteenMinutes() {
        User user = activeUser();
        for (int attempt = 1; attempt <= 4; attempt++) {
            user.recordLoginAttempt(false, NOW, POLICY);
            assertThat(user.isLockedAt(NOW)).as("not locked after %d failures", attempt).isFalse();
        }

        assertThat(user.recordLoginAttempt(false, NOW, POLICY))
                .as("the 5th failure itself is still reported as invalid credentials")
                .isEqualTo(LoginAttemptOutcome.INVALID_CREDENTIALS);
        assertThat(user.isLockedAt(NOW)).isTrue();
        assertThat(user.lockedUntil()).isEqualTo(NOW.plus(Duration.ofMinutes(15)));
    }

    @Test
    void aLockedAccountRefusesEvenTheCorrectPasswordWithinFifteenMinutes() {
        User user = lockedUserAt(NOW);

        assertThat(user.recordLoginAttempt(true, NOW.plus(Duration.ofMinutes(14)), POLICY))
                .isEqualTo(LoginAttemptOutcome.TEMPORARILY_BLOCKED);
        assertThat(user.recordLoginAttempt(false, NOW.plus(Duration.ofMinutes(14)), POLICY))
                .isEqualTo(LoginAttemptOutcome.TEMPORARILY_BLOCKED);
    }

    @Test
    void afterTheLockExpiresTheCorrectPasswordSucceedsAndTheCounterIsReset() {
        User user = lockedUserAt(NOW);

        assertThat(user.recordLoginAttempt(true, NOW.plus(Duration.ofMinutes(15)), POLICY))
                .isEqualTo(LoginAttemptOutcome.SUCCEEDED);
        assertThat(user.failedLoginAttempts()).isZero();
        assertThat(user.lockedUntil()).isNull();
    }

    @Test
    void afterTheLockExpiresCountingStartsAgainFromZero() {
        User user = lockedUserAt(NOW);

        user.recordLoginAttempt(false, NOW.plus(Duration.ofMinutes(16)), POLICY);

        assertThat(user.failedLoginAttempts()).isEqualTo(1);
        assertThat(user.isLockedAt(NOW.plus(Duration.ofMinutes(16)))).isFalse();
    }

    @Test
    void aSuccessfulLoginResetsTheCounter() {
        User user = activeUser();
        user.recordLoginAttempt(false, NOW, POLICY);
        user.recordLoginAttempt(false, NOW, POLICY);

        user.recordLoginAttempt(true, NOW, POLICY);

        assertThat(user.failedLoginAttempts()).isZero();
    }

    @Test
    void anInactiveAccountIsRefusedWithTheGenericOutcomeEvenWithTheCorrectPassword() {
        User user = user(false, 0, null);

        assertThat(user.recordLoginAttempt(true, NOW, POLICY)).isEqualTo(LoginAttemptOutcome.INVALID_CREDENTIALS);
    }

    @Test
    void minutesUntilUnlockedRoundsUp() {
        User user = lockedUserAt(NOW);

        assertThat(user.minutesUntilUnlocked(NOW)).isEqualTo(15);
        assertThat(user.minutesUntilUnlocked(NOW.plusSeconds(14 * 60 + 1))).isEqualTo(1);
        assertThat(user.minutesUntilUnlocked(NOW.plus(Duration.ofMinutes(15)))).isZero();
    }

    @Test
    void aNegativeFailureCountIsRejected() {
        assertThatThrownBy(() -> user(true, -1, null)).isInstanceOf(IllegalArgumentException.class);
    }

    private static User activeUser() {
        return user(true, 0, null);
    }

    private static User lockedUserAt(Instant lockedAt) {
        return user(true, 5, lockedAt.plus(Duration.ofMinutes(15)));
    }

    private static User user(boolean active, int failures, Instant lockedUntil) {
        return User.reconstitute(new UserId(UUID.randomUUID()), new EmailAddress("employee1@resolveit.local"),
                new DisplayName("Employee One"), Role.EMPLOYEE, new Department("Finance"), new PasswordHash("$2a$10$hash"),
                active, failures, lockedUntil);
    }
}
