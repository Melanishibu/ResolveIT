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

    /** Password reset link is valid for 1 hour (RIT-US-23). */
    public static final Duration RESET_VALIDITY = Duration.ofHours(1);

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

    /** Issues a new password reset for {@code token}; valid for 1 hour (RIT-US-23). */
    public static Invitation issueReset(InvitationId id, UserId userId, InvitationToken token, Instant now) {
        return new Invitation(id, userId, token.hash(), now, now.plus(RESET_VALIDITY), InvitationStatus.PENDING);
    }

    public static Invitation reconstitute(InvitationId id, UserId userId, String tokenHash, Instant createdAt,
                                          Instant expiresAt, InvitationStatus status) {
        return new Invitation(id, userId, tokenHash, createdAt, expiresAt, status);
    }

    /** The email was handed to the mail server. */
    public void markSent() {
        if (status != InvitationStatus.USED) { // a link used meanwhile stays used (RIT-US-07)
            status = InvitationStatus.SENT;
        }
    }

    /** Sending failed; the user stays created. */
    public void markSendFailed() {
        if (status != InvitationStatus.USED) {
            status = InvitationStatus.SEND_FAILED;
        }
    }

    /**
     * The user sets their password with this invitation (RIT-US-07): single use, valid for 24 hours.
     * Works whether the email was sent or not (PENDING, SENT, SEND_FAILED).
     *
     * @throws InvitationTokenInvalidException if it was already used
     * @throws InvitationTokenExpiredException if it is older than 24 hours
     */
    public void use(Instant now) {
        if (status == InvitationStatus.USED) {
            throw new InvitationTokenInvalidException();
        }
        if (isExpiredAt(now)) {
            throw new InvitationTokenExpiredException();
        }
        status = InvitationStatus.USED;
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
