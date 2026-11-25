package com.itsm.resolveit.identity.config;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * Session settings ({@code resolveit.session.*}).
 *
 * @param signingKey               HS256 key for session tokens, from {@code RESOLVEIT_SESSION_SIGNING_KEY};
 *                                 at least 32 characters. Never committed, never logged.
 * @param lifetime                 how long a session lasts (common rules: 8 hours)
 * @param allowEphemeralSigningKey dev and test only: without a key, generate a random one at startup
 *                                 (sessions then end when the backend restarts)
 */
@ConfigurationProperties("resolveit.session")
public record SessionProperties(
        String signingKey,
        @DefaultValue("8h") Duration lifetime,
        @DefaultValue("false") boolean allowEphemeralSigningKey) {

    @Override
    public String toString() {
        return "SessionProperties[signingKey=***, lifetime=" + lifetime
                + ", allowEphemeralSigningKey=" + allowEphemeralSigningKey + "]";
    }
}
