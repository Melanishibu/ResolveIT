package com.itsm.resolveit.identity.domain.model;

/** The result of one login attempt, decided by {@link User#recordLoginAttempt}. */
public enum LoginAttemptOutcome {
    /** Correct password, active account, not locked: a session may start. */
    SUCCEEDED,
    /** Wrong password, or an inactive account. The user gets the same generic message either way. */
    INVALID_CREDENTIALS,
    /** The account is locked after too many failures; the password was not considered. */
    TEMPORARILY_BLOCKED
}
