package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.SessionId;
import com.itsm.resolveit.identity.domain.model.SessionToken;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.util.Objects;
import java.util.Optional;

/** Verifies a session token's signature and expiry. */
public interface SessionTokenVerifier {

    /** The session and user the token refers to; empty if the token is forged, malformed or expired. */
    Optional<SessionClaims> verify(SessionToken token);

    /** What a valid token says. */
    record SessionClaims(SessionId sessionId, UserId userId) {

        public SessionClaims {
            Objects.requireNonNull(sessionId, "sessionId");
            Objects.requireNonNull(userId, "userId");
        }
    }
}
