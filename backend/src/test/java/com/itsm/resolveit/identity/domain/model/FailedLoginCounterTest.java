package com.itsm.resolveit.identity.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import java.time.Instant;
import org.junit.jupiter.api.Test;

/** Bug AB#180: the failed-login counter of an unknown email follows the same lockout rules as a user. */
class FailedLoginCounterTest {

    private static final Instant NOW = Instant.parse("2026-11-21T09:00:00Z");
    private final FailedLoginCounter counter = FailedLoginCounter.start(new EmailAddress("nobody@resolveit.local"));

    @Test
    void fiveFailuresLockTheAddressForFifteenMinutes() {
        for (int attempt = 1; attempt <= 5; attempt++) {
            assertThat(counter.recordFailedAttempt(NOW, LoginLockoutPolicy.STANDARD))
                    .isEqualTo(LoginAttemptOutcome.INVALID_CREDENTIALS);
        }

        assertThat(counter.recordFailedAttempt(NOW.plusSeconds(60), LoginLockoutPolicy.STANDARD))
                .isEqualTo(LoginAttemptOutcome.TEMPORARILY_BLOCKED);
        assertThat(counter.minutesUntilUnlocked(NOW.plusSeconds(60))).isEqualTo(14);
        assertThat(counter.lockedUntil()).isEqualTo(NOW.plus(Duration.ofMinutes(15)));
    }

    @Test
    void anExpiredLockStartsAgainWithACleanSlate() {
        for (int attempt = 1; attempt <= 5; attempt++) {
            counter.recordFailedAttempt(NOW, LoginLockoutPolicy.STANDARD);
        }

        assertThat(counter.recordFailedAttempt(NOW.plus(Duration.ofMinutes(15)), LoginLockoutPolicy.STANDARD))
                .isEqualTo(LoginAttemptOutcome.INVALID_CREDENTIALS);
        assertThat(counter.failedAttempts()).isEqualTo(1);
        assertThat(counter.lockedUntil()).isNull();
    }

    @Test
    void aNegativeFailureCountIsRejected() {
        assertThatThrownBy(() -> FailedLoginCounter.reconstitute(new EmailAddress("x@resolveit.local"), -1, null))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
