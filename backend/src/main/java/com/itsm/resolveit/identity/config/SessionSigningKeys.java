package com.itsm.resolveit.identity.config;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** Turns the configured signing key into an HS256 key, or refuses to start without a safe one. */
public final class SessionSigningKeys {

    static final int MIN_KEY_BYTES = 32;
    private static final String ALGORITHM = "HmacSHA256";
    private static final Logger log = LoggerFactory.getLogger(SessionSigningKeys.class);

    private SessionSigningKeys() {
    }

    public static SecretKey resolve(SessionProperties properties) {
        String configured = properties.signingKey();
        if (configured == null || configured.isBlank()) {
            if (!properties.allowEphemeralSigningKey()) {
                throw new IllegalStateException("RESOLVEIT_SESSION_SIGNING_KEY is not set. Set it to a random value of at"
                        + " least " + MIN_KEY_BYTES + " characters (it signs the session tokens).");
            }
            log.warn("No RESOLVEIT_SESSION_SIGNING_KEY set: using a random signing key for this run only"
                    + " (dev/test). Sessions end when the backend restarts.");
            byte[] random = new byte[MIN_KEY_BYTES];
            new SecureRandom().nextBytes(random);
            return new SecretKeySpec(random, ALGORITHM);
        }
        byte[] bytes = configured.getBytes(StandardCharsets.UTF_8);
        if (bytes.length < MIN_KEY_BYTES) {
            throw new IllegalStateException("RESOLVEIT_SESSION_SIGNING_KEY is too short: use at least "
                    + MIN_KEY_BYTES + " characters.");
        }
        return new SecretKeySpec(bytes, ALGORITHM);
    }
}
