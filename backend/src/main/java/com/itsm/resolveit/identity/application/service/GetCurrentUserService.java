package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.in.CurrentUserView;
import com.itsm.resolveit.identity.application.port.in.GetCurrentUserUseCase;
import com.itsm.resolveit.identity.application.port.out.SessionTokenVerifier;
import com.itsm.resolveit.identity.application.port.out.SessionTokenVerifier.SessionClaims;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.application.port.out.UserSessionRepository;
import com.itsm.resolveit.identity.domain.model.NotAuthenticatedException;
import com.itsm.resolveit.identity.domain.model.SessionToken;
import com.itsm.resolveit.identity.domain.model.User;
import java.time.Clock;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;
import org.springframework.transaction.annotation.Transactional;

/** Resolves the logged-in user from the session token, re-checking the session and the account. */
public class GetCurrentUserService implements GetCurrentUserUseCase {

    private final SessionTokenVerifier tokens;
    private final UserSessionRepository sessions;
    private final UserRepository users;
    private final Clock clock;

    public GetCurrentUserService(SessionTokenVerifier tokens, UserSessionRepository sessions, UserRepository users,
                                 Clock clock) {
        this.tokens = Objects.requireNonNull(tokens, "tokens");
        this.sessions = Objects.requireNonNull(sessions, "sessions");
        this.users = Objects.requireNonNull(users, "users");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional(readOnly = true)
    @Override
    public CurrentUserView currentUser(Optional<SessionToken> token) {
        Instant now = clock.instant();
        SessionClaims claims = token.flatMap(tokens::verify).orElseThrow(NotAuthenticatedException::new);
        sessions.findById(claims.sessionId())
                .filter(session -> session.isValidFor(claims.userId(), now))
                .orElseThrow(NotAuthenticatedException::new);
        User user = users.findById(claims.userId())
                .filter(User::isActive)
                .orElseThrow(NotAuthenticatedException::new);
        return CurrentUserView.of(user);
    }
}
