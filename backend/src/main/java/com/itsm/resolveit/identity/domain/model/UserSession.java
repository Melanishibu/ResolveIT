package com.itsm.resolveit.identity.domain.model;

import java.time.Duration;
import java.time.Instant;
import java.util.Objects;

/**
 * Aggregate root: one logged-in session of a user (common rules: 8 hours).
 *
 * <p>The session token (JWT) only refers to this record. Logging out deletes the record, so a
 * token that someone kept after logout no longer works.
 */
public final class UserSession {

    private final SessionId id;
    private final UserId userId;
    private final Instant createdAt;
    private final Instant expiresAt;

    private UserSession(SessionId id, UserId userId, Instant createdAt, Instant expiresAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.expiresAt = Objects.requireNonNull(expiresAt, "expiresAt");
        if (!expiresAt.isAfter(createdAt)) {
            throw new IllegalArgumentException("A session must expire after it starts");
        }
    }

    /** Starts a new session for {@code userId} that lasts {@code lifetime}. */
    public static UserSession start(SessionId id, UserId userId, Instant now, Duration lifetime) {
        Objects.requireNonNull(lifetime, "lifetime");
        return new UserSession(id, userId, now, now.plus(lifetime));
    }

    public static UserSession reconstitute(SessionId id, UserId userId, Instant createdAt, Instant expiresAt) {
        return new UserSession(id, userId, createdAt, expiresAt);
    }

    /** Whether the session still counts at {@code now} and belongs to {@code user}. */
    public boolean isValidFor(UserId user, Instant now) {
        return userId.equals(user) && now.isBefore(expiresAt);
    }

    public SessionId id() {
        return id;
    }

    public UserId userId() {
        return userId;
    }

    public Instant createdAt() {
        return createdAt;
    }

    public Instant expiresAt() {
        return expiresAt;
    }
}
