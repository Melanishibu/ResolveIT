package com.itsm.resolveit.identity.domain.model;

import java.time.Duration;
import java.time.Instant;
import java.util.Objects;

/**
 * Aggregate root: the one-time invitation that lets a new user set their password (RIT-US-06).
 *
 * <p>Stores only the SHA-256 hash of the token; valid for 24 hours; single use (RIT-US-07).
 */
public final class Invitation {

    /** Common rules: the invitation link is valid for 24 hours. */
    public static final Duration VALIDITY = Duration.ofHours(24);

    private final InvitationId id;
    private final UserId userId;
    private final String tokenHash;
    private final Instant createdAt;
    private final Instant expiresAt;
    private InvitationStatus status;

    private Invitation(InvitationId id, UserId userId, String tokenHash, Instant createdAt, Instant expiresAt,
                       InvitationStatus status) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        if (tokenHash == null || !tokenHash.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("tokenHash must be a SHA-256 hex digest");
        }
        this.tokenHash = tokenHash;
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.expiresAt = Objects.requireNonNull(expiresAt, "expiresAt");
        this.status = Objects.requireNonNull(status, "status");
    }

    /** Issues a new invitation for {@code token}; only the token's hash is kept. */
    public static Invitation issue(InvitationId id, UserId userId, InvitationToken token, Instant now) {
        return new Invitation(id, userId, token.hash(), now, now.plus(VALIDITY), InvitationStatus.PENDING);
    }

    public static Invitation reconstitute(InvitationId id, UserId userId, String tokenHash, Instant createdAt,
                                          Instant expiresAt, InvitationStatus status) {
        return new Invitation(id, userId, tokenHash, createdAt, expiresAt, status);
    }

    /** The email was handed to the mail server. */
    public void markSent() {
        status = InvitationStatus.SENT;
    }

    /** Sending failed; the user stays created. */
    public void markSendFailed() {
        status = InvitationStatus.SEND_FAILED;
    }

    public boolean isExpiredAt(Instant now) {
        return !now.isBefore(expiresAt);
    }

    public InvitationId id() {
        return id;
    }

    public UserId userId() {
        return userId;
    }

    public String tokenHash() {
        return tokenHash;
    }

    public Instant createdAt() {
        return createdAt;
    }

    public Instant expiresAt() {
        return expiresAt;
    }

    public InvitationStatus status() {
        return status;
    }
}
