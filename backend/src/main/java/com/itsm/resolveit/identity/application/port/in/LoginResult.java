package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.model.SessionToken;
import java.time.Instant;
import java.util.Objects;

/**
 * A successful login: who logged in and the session token for the {@code RIT_SESSION} cookie.
 *
 * @param user      the logged-in user
 * @param token     the session token
 * @param expiresAt when the session ends (8 hours after login)
 */
public record LoginResult(CurrentUserView user, SessionToken token, Instant expiresAt) {

    public LoginResult {
        Objects.requireNonNull(user, "user");
        Objects.requireNonNull(token, "token");
        Objects.requireNonNull(expiresAt, "expiresAt");
    }
}
