package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.out.PasswordVerifier;
import com.itsm.resolveit.identity.application.port.out.SessionTokenIssuer;
import com.itsm.resolveit.identity.application.port.out.SessionTokenVerifier;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.application.port.out.UserSessionRepository;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.PasswordHash;
import com.itsm.resolveit.identity.domain.model.SessionId;
import com.itsm.resolveit.identity.domain.model.SessionToken;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserId;
import com.itsm.resolveit.identity.domain.model.UserSession;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Hand-written in-memory fakes for the identity outbound ports (java-spring.md §6). */
final class IdentityFakes {

    private IdentityFakes() {
    }

    static final class InMemoryUsers implements UserRepository {
        final Map<UserId, User> byId = new HashMap<>();
        int saves;

        InMemoryUsers with(User user) {
            byId.put(user.id(), user);
            return this;
        }

        @Override
        public Optional<User> lockByEmail(EmailAddress email) {
            return byId.values().stream().filter(user -> user.email().equals(email)).findFirst();
        }

        @Override
        public Optional<User> lockById(UserId id) {
            return findById(id);
        }

        @Override
        public Optional<User> findById(UserId id) {
            return Optional.ofNullable(byId.get(id));
        }

        @Override
        public void save(User user) {
            saves++;
            byId.put(user.id(), user);
        }

        @Override
        public boolean existsByEmail(EmailAddress email) {
            return lockByEmail(email).isPresent();
        }

        @Override
        public UserId nextId() {
            return new UserId(UUID.randomUUID());
        }
    }

    static final class InMemorySessions implements UserSessionRepository {
        final Map<SessionId, UserSession> byId = new HashMap<>();

        @Override
        public SessionId nextId() {
            return new SessionId(UUID.randomUUID());
        }

        @Override
        public void save(UserSession session) {
            byId.put(session.id(), session);
        }

        @Override
        public Optional<UserSession> findById(SessionId id) {
            return Optional.ofNullable(byId.get(id));
        }

        @Override
        public void delete(SessionId id) {
            byId.remove(id);
        }
    }

    /** "Hashes" are the password itself prefixed with "hash:"; counts dummy checks for the timing rule. */
    static final class PlainPasswords implements PasswordVerifier {
        int dummyChecks;

        static PasswordHash hashOf(String raw) {
            return new PasswordHash("hash:" + raw);
        }

        @Override
        public boolean matches(String rawPassword, PasswordHash hash) {
            return hash.value().equals("hash:" + rawPassword);
        }

        @Override
        public void verifyAgainstDummy(String rawPassword) {
            dummyChecks++;
        }
    }

    /** Tokens of the form "token:<sessionId>:<userId>"; anything else is invalid. */
    static final class TransparentTokens implements SessionTokenIssuer, SessionTokenVerifier {

        @Override
        public SessionToken issue(UserSession session) {
            return new SessionToken("token:" + session.id() + ":" + session.userId());
        }

        @Override
        public Optional<SessionClaims> verify(SessionToken token) {
            String[] parts = token.value().split(":");
            if (parts.length != 3 || !parts[0].equals("token")) {
                return Optional.empty();
            }
            return Optional.of(new SessionClaims(
                    new SessionId(UUID.fromString(parts[1])), new UserId(UUID.fromString(parts[2]))));
        }
    }

    /** A clock the test can move forward. */
    static final class MutableClock extends Clock {
        private Instant now;

        MutableClock(Instant start) {
            this.now = start;
        }

        void advance(java.time.Duration duration) {
            now = now.plus(duration);
        }

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    }
}
