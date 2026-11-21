package com.itsm.resolveit.identity.adapters.out.integration;

import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.identity.application.port.out.SessionTokenVerifier.SessionClaims;
import com.itsm.resolveit.identity.domain.model.PasswordHash;
import com.itsm.resolveit.identity.domain.model.SessionId;
import com.itsm.resolveit.identity.domain.model.SessionToken;
import com.itsm.resolveit.identity.domain.model.UserId;
import com.itsm.resolveit.identity.domain.model.UserSession;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import javax.crypto.spec.SecretKeySpec;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/** BCrypt verification and HS256 session tokens. */
class SecurityAdaptersTest {

    private static final Instant NOW = Instant.parse("2026-11-20T09:00:00Z");
    private static final SecretKeySpec KEY = key("a-test-signing-key-of-at-least-32-bytes!");

    @Test
    void bcryptMatchesTheRightPasswordOnly() {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(4);
        BCryptPasswordVerifier verifier = new BCryptPasswordVerifier(encoder);
        PasswordHash hash = new PasswordHash(encoder.encode("ResolveIT-Dev-2026"));

        assertThat(verifier.matches("ResolveIT-Dev-2026", hash)).isTrue();
        assertThat(verifier.matches("resolveit-dev-2026", hash)).isFalse();
        assertThat(verifier.matches("x".repeat(100), hash)).as("over 72 bytes never matches").isFalse();
        verifier.verifyAgainstDummy("anything");
        verifier.verifyAgainstDummy("y".repeat(200));
    }

    @Test
    void anIssuedTokenVerifiesToItsSessionAndUser() {
        JwtSessionTokens tokens = new JwtSessionTokens(KEY, Clock.fixed(NOW.plusSeconds(60), ZoneOffset.UTC));
        UserSession session = session(NOW);

        SessionToken token = tokens.issue(session);

        assertThat(tokens.verify(token)).contains(new SessionClaims(session.id(), session.userId()));
    }

    @Test
    void forgedExpiredOrForeignTokensAreRejected() {
        UserSession session = session(NOW);
        SessionToken token = new JwtSessionTokens(KEY, Clock.systemUTC()).issue(session);

        JwtSessionTokens afterExpiry = new JwtSessionTokens(KEY, Clock.fixed(NOW.plus(Duration.ofHours(9)), ZoneOffset.UTC));
        JwtSessionTokens otherKey = new JwtSessionTokens(key("another-signing-key-of-at-least-32-bytes"),
                Clock.fixed(NOW, ZoneOffset.UTC));
        JwtSessionTokens sameKey = new JwtSessionTokens(KEY, Clock.fixed(NOW, ZoneOffset.UTC));

        assertThat(afterExpiry.verify(token)).as("expired").isEmpty();
        assertThat(otherKey.verify(token)).as("signed with another key").isEmpty();
        assertThat(sameKey.verify(new SessionToken("not.a.jwt"))).as("malformed").isEmpty();
        assertThat(sameKey.verify(new SessionToken(token.value() + "x"))).as("tampered signature").isEmpty();
    }

    private static UserSession session(Instant start) {
        return UserSession.start(new SessionId(UUID.randomUUID()), new UserId(UUID.randomUUID()), start,
                Duration.ofHours(8));
    }

    private static SecretKeySpec key(String value) {
        return new SecretKeySpec(value.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
    }
}
