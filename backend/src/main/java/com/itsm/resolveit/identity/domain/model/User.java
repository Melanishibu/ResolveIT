package com.itsm.resolveit.identity.domain.model;

import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;

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
    private final Department department;
    private PasswordHash passwordHash;
    private boolean active;
    private int failedLoginAttempts;
    private Instant lockedUntil;
    private final Instant createdAt;

    private User(UserId id, EmailAddress email, DisplayName displayName, Role role, Department department,
                 PasswordHash passwordHash, boolean active, int failedLoginAttempts, Instant lockedUntil,
                 Instant createdAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.email = Objects.requireNonNull(email, "email");
        this.displayName = Objects.requireNonNull(displayName, "displayName");
        this.role = Objects.requireNonNull(role, "role");
        this.department = Objects.requireNonNull(department, "department");
        if (failedLoginAttempts < 0) {
            throw new IllegalArgumentException("failedLoginAttempts must not be negative");
        }
        this.passwordHash = passwordHash;
        this.active = active;
        this.failedLoginAttempts = failedLoginAttempts;
        this.lockedUntil = lockedUntil;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    /**
     * An Admin invites a new user (RIT-US-06): active, with no password until they set one from the
     * invitation link. Admins cannot create Admins.
     */
    public static User invite(UserId id, EmailAddress email, DisplayName displayName, Role role, Department department) {
        Objects.requireNonNull(role, "role");
        if (role == Role.ADMIN) {
            throw new UserRoleNotAllowedException(role);
        }
        return new User(id, email, displayName, role, department, null, true, 0, null, Instant.now());
    }

    /** Rebuilds a user from storage. {@code passwordHash} is null while an invited user has not set one. */
    public static User reconstitute(UserId id, EmailAddress email, DisplayName displayName, Role role,
                                    Department department, PasswordHash passwordHash, boolean active,
                                    int failedLoginAttempts, Instant lockedUntil) {
        return reconstitute(id, email, displayName, role, department, passwordHash, active, failedLoginAttempts,
                lockedUntil, Instant.now());
    }

    /** Rebuilds a user from storage including their creation timestamp (RIT-US-27). */
    public static User reconstitute(UserId id, EmailAddress email, DisplayName displayName, Role role,
                                    Department department, PasswordHash passwordHash, boolean active,
                                    int failedLoginAttempts, Instant lockedUntil, Instant createdAt) {
        return new User(id, email, displayName, role, department, passwordHash, active, failedLoginAttempts,
                lockedUntil, createdAt);
    }

    /**
     * An Admin deactivates this user (RIT-US-08): they can no longer log in, and their sessions are
     * refused on the next request. An Admin cannot deactivate themselves.
     *
     * @param by the Admin who deactivates
     * @return whether the state changed (deactivating an inactive user changes nothing)
     */
    public boolean deactivate(UserId by) {
        if (id.equals(by)) {
            throw new UserCannotDeactivateSelfException();
        }
        if (!active) {
            return false;
        }
        active = false;
        return true;
    }

    /**
     * An Admin activates this user again (RIT-US-08).
     *
     * @return whether the state changed (activating an active user changes nothing)
     */
    public boolean activate() {
        if (active) {
            return false;
        }
        active = true;
        return true;
    }

    /**
     * The user set a new password (RIT-US-07). A fresh password also ends any failed-login count and lock.
     */
    public void setPassword(PasswordHash newHash) {
        this.passwordHash = Objects.requireNonNull(newHash, "newHash");
        this.failedLoginAttempts = 0;
        this.lockedUntil = null;
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

    public Department department() {
        return department;
    }

    /** Empty while an invited user has not set a password yet; such a user cannot log in. */
    public Optional<PasswordHash> passwordHash() {
        return Optional.ofNullable(passwordHash);
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

    /** When the user was created (RIT-US-27, member since). */
    public Instant createdAt() {
        return createdAt;
    }
}
