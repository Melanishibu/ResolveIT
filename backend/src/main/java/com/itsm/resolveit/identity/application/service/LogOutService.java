package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.in.LogOutUseCase;
import com.itsm.resolveit.identity.application.port.out.SessionTokenVerifier;
import com.itsm.resolveit.identity.application.port.out.UserSessionRepository;
import com.itsm.resolveit.identity.domain.model.SessionToken;
import java.util.Objects;
import java.util.Optional;
import org.springframework.transaction.annotation.Transactional;

/** Ends a session: its record is deleted, so the token stops working everywhere. */
public class LogOutService implements LogOutUseCase {

    private final UserSessionRepository sessions;
    private final SessionTokenVerifier tokens;

    public LogOutService(UserSessionRepository sessions, SessionTokenVerifier tokens) {
        this.sessions = Objects.requireNonNull(sessions, "sessions");
        this.tokens = Objects.requireNonNull(tokens, "tokens");
    }

    @Transactional
    @Override
    public void logOut(Optional<SessionToken> token) {
        token.flatMap(tokens::verify).ifPresent(claims -> sessions.delete(claims.sessionId()));
    }
}
