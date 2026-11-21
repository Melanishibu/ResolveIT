package com.itsm.resolveit.identity.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * One append-only entry of the user audit log (common rules, Audit): actor, action, old value, new
 * value, UTC timestamp. Never contains passwords, tokens or links.
 *
 * @param userId     the user the entry is about
 * @param actorId    who did it (null for actions without a logged-in actor)
 * @param action     what happened
 * @param oldValue   the value before, if any
 * @param newValue   the value after, if any
 * @param occurredAt when it happened (UTC)
 */
public record UserAuditEntry(UserId userId, UUID actorId, UserAuditAction action, String oldValue, String newValue,
                             Instant occurredAt) {

    public UserAuditEntry {
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(action, "action");
        Objects.requireNonNull(occurredAt, "occurredAt");
    }

    /** The user actions of the common rules. */
    public enum UserAuditAction {
        USER_CREATED,
        INVITATION_SENT,
        INVITATION_RESENT,
        PASSWORD_SET,
        USER_DEACTIVATED,
        USER_ACTIVATED,
        PASSWORD_RESET_REQUESTED
    }
}
