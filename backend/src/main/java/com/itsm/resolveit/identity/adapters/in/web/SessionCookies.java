package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.domain.model.SessionToken;
import java.security.SecureRandom;
import java.time.Duration;
import java.util.Base64;
import java.util.Objects;
import org.springframework.http.ResponseCookie;

/**
 * Writes the two cookies of the common security rules.
 *
 * <ul>
 *   <li>{@code RIT_SESSION}: the session token. HttpOnly (scripts can't read it), Secure, SameSite=Strict.</li>
 *   <li>{@code XSRF-TOKEN}: a random CSRF token that the frontend reads and echoes in the
 *       {@code X-XSRF-TOKEN} header on state-changing requests. Readable by scripts by design, Secure,
 *       SameSite=Strict. Checking the header is RIT-US-05.</li>
 * </ul>
 * Browsers treat {@code http://localhost} as a secure context, so Secure cookies work in local development.
 */
public class SessionCookies {

    public static final String SESSION_COOKIE = "RIT_SESSION";
    public static final String XSRF_COOKIE = "XSRF-TOKEN";

    private static final Base64.Encoder TOKEN_ENCODING = Base64.getUrlEncoder().withoutPadding();

    private final Duration lifetime;
    private final SecureRandom random = new SecureRandom();

    public SessionCookies(Duration lifetime) {
        this.lifetime = Objects.requireNonNull(lifetime, "lifetime");
    }

    ResponseCookie session(SessionToken token) {
        return base(SESSION_COOKIE, token.value(), lifetime).httpOnly(true).build();
    }

    ResponseCookie newXsrfToken() {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        return base(XSRF_COOKIE, TOKEN_ENCODING.encodeToString(bytes), lifetime).httpOnly(false).build();
    }

    ResponseCookie clearedSession() {
        return base(SESSION_COOKIE, "", Duration.ZERO).httpOnly(true).build();
    }

    ResponseCookie clearedXsrfToken() {
        return base(XSRF_COOKIE, "", Duration.ZERO).httpOnly(false).build();
    }

    private static ResponseCookie.ResponseCookieBuilder base(String name, String value, Duration maxAge) {
        return ResponseCookie.from(name, value).secure(true).sameSite("Strict").path("/").maxAge(maxAge);
    }
}
