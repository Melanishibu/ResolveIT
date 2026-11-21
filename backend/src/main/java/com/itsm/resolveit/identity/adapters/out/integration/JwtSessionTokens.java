package com.itsm.resolveit.identity.adapters.out.integration;

import com.itsm.resolveit.identity.application.port.out.SessionTokenIssuer;
import com.itsm.resolveit.identity.application.port.out.SessionTokenVerifier;
import com.itsm.resolveit.identity.domain.model.SessionId;
import com.itsm.resolveit.identity.domain.model.SessionToken;
import com.itsm.resolveit.identity.domain.model.UserId;
import com.itsm.resolveit.identity.domain.model.UserSession;
import com.nimbusds.jose.jwk.source.ImmutableSecret;
import java.time.Clock;
import java.time.Duration;
import java.util.Optional;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtIssuerValidator;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

/**
 * Session tokens as HS256-signed JWTs (common rules: session = JWT, 8 h).
 *
 * <p>Claims: {@code iss} = resolveit, {@code sub} = user id, {@code jti} = session id, {@code iat},
 * {@code exp}. The token carries no role or personal data; the server re-reads both on every request.
 */
public class JwtSessionTokens implements SessionTokenIssuer, SessionTokenVerifier {

    static final String ISSUER = "resolveit";

    private final JwtEncoder encoder;
    private final JwtDecoder decoder;

    public JwtSessionTokens(SecretKey signingKey, Clock clock) {
        this.encoder = new NimbusJwtEncoder(new ImmutableSecret<>(signingKey));
        NimbusJwtDecoder nimbusDecoder = NimbusJwtDecoder.withSecretKey(signingKey)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
        JwtTimestampValidator expiry = new JwtTimestampValidator(Duration.ZERO);
        expiry.setClock(clock);
        nimbusDecoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(expiry, new JwtIssuerValidator(ISSUER)));
        this.decoder = nimbusDecoder;
    }

    @Override
    public SessionToken issue(UserSession session) {
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(ISSUER)
                .subject(session.userId().toString())
                .id(session.id().toString())
                .issuedAt(session.createdAt())
                .expiresAt(session.expiresAt())
                .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        return new SessionToken(encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue());
    }

    @Override
    public Optional<SessionClaims> verify(SessionToken token) {
        try {
            Jwt jwt = decoder.decode(token.value());
            if (jwt.getId() == null || jwt.getSubject() == null) {
                return Optional.empty();
            }
            return Optional.of(new SessionClaims(
                    new SessionId(UUID.fromString(jwt.getId())),
                    new UserId(UUID.fromString(jwt.getSubject()))));
        } catch (JwtException | IllegalArgumentException invalid) {
            // Forged, malformed, expired or missing claims: treated as "no session". Never logged (token content).
            return Optional.empty();
        }
    }
}
