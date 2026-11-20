package com.itsm.resolveit.identity.domain.model;

import java.time.Duration;
import java.time.Instant;
import java.util.Objects;

/**
 * Aggregate root: a person who can log in to ResolveIT.
 *
 * <p>Owns the lockout invariant (common rules): 5 consecutive failed logins lock the account for
 * 15 minutes, a successful login resets the counter, and a locked account refuses every attempt,
 * even with the correct password, until the lock expires. Inactive accounts never log in.
 */
public final class User {

    private final UserId id;
    private final EmailAddress email;
    private final DisplayName displayName;
    private final Role role;
    private final PasswordHash passwordHash;
    private final boolean active;
    private int failedLoginAttempts;
    private Instant lockedUntil;

    private User(UserId id, EmailAddress email, DisplayName displayName, Role role, PasswordHash passwordHash,
                 boolean active, int failedLoginAttempts, Instant lockedUntil) {
        this.id = Objects.requireNonNull(id, "id");
        this.email = Objects.requireNonNull(email, "email");
        this.displayName = Objects.requireNonNull(displayName, "displayName");
        this.role = Objects.requireNonNull(role, "role");
        this.passwordHash = Objects.requireNonNull(passwordHash, "passwordHash");
        if (failedLoginAttempts < 0) {
            throw new IllegalArgumentException("failedLoginAttempts must not be negative");
        }
        this.active = active;
        this.failedLoginAttempts = failedLoginAttempts;
        this.lockedUntil = lockedUntil;
    }

    /** Rebuilds a user from storage. Creating new users (invitations) is a later story. */
    public static User reconstitute(UserId id, EmailAddress email, DisplayName displayName, Role role,
                                    PasswordHash passwordHash, boolean active, int failedLoginAttempts,
                                    Instant lockedUntil) {
        return new User(id, email, displayName, role, passwordHash, active, failedLoginAttempts, lockedUntil);
    }

    /**
     * Records one login attempt and decides its outcome.
     *
     * @param passwordMatches whether the given password matches this user's hash
     * @param now             the time of the attempt
     * @param policy          the lockout rules
     */
    public LoginAttemptOutcome recordLoginAttempt(boolean passwordMatches, Instant now, LoginLockoutPolicy policy) {
        Objects.requireNonNull(now, "now");
        Objects.requireNonNull(policy, "policy");
        if (isLockedAt(now)) {
            return LoginAttemptOutcome.TEMPORARILY_BLOCKED;
        }
        if (lockedUntil != null) {
            // The previous lock has expired: the user starts again with a clean slate.
            lockedUntil = null;
            failedLoginAttempts = 0;
        }
        if (!passwordMatches) {
            failedLoginAttempts++;
            if (failedLoginAttempts >= policy.maxConsecutiveFailures()) {
                lockedUntil = now.plus(policy.lockDuration());
            }
            return LoginAttemptOutcome.INVALID_CREDENTIALS;
        }
        if (!active) {
            return LoginAttemptOutcome.INVALID_CREDENTIALS;
        }
        failedLoginAttempts = 0;
        return LoginAttemptOutcome.SUCCEEDED;
    }

    /** Whether the account is locked at {@code now}. */
    public boolean isLockedAt(Instant now) {
        return lockedUntil != null && now.isBefore(lockedUntil);
    }

    /** Whole minutes until the lock ends, rounded up (at least 1 while locked, 0 when not locked). */
    public long minutesUntilUnlocked(Instant now) {
        if (!isLockedAt(now)) {
            return 0;
        }
        long seconds = Duration.between(now, lockedUntil).toSeconds();
        return Math.max(1, (seconds + 59) / 60);
    }

    public UserId id() {
        return id;
    }

    public EmailAddress email() {
        return email;
    }

    public DisplayName displayName() {
        return displayName;
    }

    public Role role() {
        return role;
    }

    public PasswordHash passwordHash() {
        return passwordHash;
    }

    public boolean isActive() {
        return active;
    }

    public int failedLoginAttempts() {
        return failedLoginAttempts;
    }

    /** When the current or last lock ends; null if the account was never locked since the last reset. */
    public Instant lockedUntil() {
        return lockedUntil;
    }
}
