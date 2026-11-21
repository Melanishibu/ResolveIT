package com.itsm.resolveit.identity.domain.model;

import java.time.Duration;
import java.time.Instant;
import java.util.Objects;

/**
 * Failed login attempts for an email address that has no account (bug AB#180).
 *
 * <p>Applies the same lockout rules as {@link User}: 5 consecutive failures lock the address for 15 minutes
 * and an expired lock starts again with a clean slate. So an unknown email answers exactly like a real
 * account, and the lockout doesn't reveal whether an email address is registered.
 */
public final class FailedLoginCounter {

    private final EmailAddress email;
    private int failedAttempts;
    private Instant lockedUntil;

    private FailedLoginCounter(EmailAddress email, int failedAttempts, Instant lockedUntil) {
        this.email = Objects.requireNonNull(email, "email");
        if (failedAttempts < 0) {
            throw new IllegalArgumentException("failedAttempts must not be negative");
        }
        this.failedAttempts = failedAttempts;
        this.lockedUntil = lockedUntil;
    }

    /** A counter with no failures yet. */
    public static FailedLoginCounter start(EmailAddress email) {
        return new FailedLoginCounter(email, 0, null);
    }

    /** Rebuilds a stored counter. */
    public static FailedLoginCounter reconstitute(EmailAddress email, int failedAttempts, Instant lockedUntil) {
        return new FailedLoginCounter(email, failedAttempts, lockedUntil);
    }

    /**
     * Records one login attempt for this unknown email. It can never succeed, so the outcome is
     * {@link LoginAttemptOutcome#TEMPORARILY_BLOCKED} while locked and otherwise
     * {@link LoginAttemptOutcome#INVALID_CREDENTIALS}.
     */
    public LoginAttemptOutcome recordFailedAttempt(Instant now, LoginLockoutPolicy policy) {
        Objects.requireNonNull(now, "now");
        Objects.requireNonNull(policy, "policy");
        if (isLockedAt(now)) {
            return LoginAttemptOutcome.TEMPORARILY_BLOCKED;
        }
        if (lockedUntil != null) {
            // The previous lock has expired: start again with a clean slate, as for a real account.
            lockedUntil = null;
            failedAttempts = 0;
        }
        failedAttempts++;
        if (failedAttempts >= policy.maxConsecutiveFailures()) {
            lockedUntil = now.plus(policy.lockDuration());
        }
        return LoginAttemptOutcome.INVALID_CREDENTIALS;
    }

    /** Whether the address is locked at {@code now}. */
    public boolean isLockedAt(Instant now) {
        return lockedUntil != null && now.isBefore(lockedUntil);
    }

    /** Whole minutes until the lock ends, rounded up, computed exactly as {@link User#minutesUntilUnlocked}. */
    public long minutesUntilUnlocked(Instant now) {
        if (!isLockedAt(now)) {
            return 0;
        }
        long seconds = Duration.between(now, lockedUntil).toSeconds();
        return Math.max(1, (seconds + 59) / 60);
    }

    public EmailAddress email() {
        return email;
    }

    public int failedAttempts() {
        return failedAttempts;
    }

    /** When the current or last lock ends; null if the address was never locked since the last reset. */
    public Instant lockedUntil() {
        return lockedUntil;
    }
}
