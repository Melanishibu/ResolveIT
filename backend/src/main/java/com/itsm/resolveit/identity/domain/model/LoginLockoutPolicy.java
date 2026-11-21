package com.itsm.resolveit.identity.domain.model;

import java.time.Duration;
import java.util.Objects;

/**
 * How many consecutive failed logins lock an account, and for how long.
 *
 * @param maxConsecutiveFailures failures in a row that lock the account
 * @param lockDuration           how long the account stays locked
 */
public record LoginLockoutPolicy(int maxConsecutiveFailures, Duration lockDuration) {

    /** Common rules: 5 consecutive failed logins lock the account for 15 minutes. */
    public static final LoginLockoutPolicy STANDARD = new LoginLockoutPolicy(5, Duration.ofMinutes(15));

    public LoginLockoutPolicy {
        if (maxConsecutiveFailures < 1) {
            throw new IllegalArgumentException("maxConsecutiveFailures must be at least 1");
        }
        Objects.requireNonNull(lockDuration, "lockDuration");
        if (lockDuration.isNegative() || lockDuration.isZero()) {
            throw new IllegalArgumentException("lockDuration must be positive");
        }
    }
}
