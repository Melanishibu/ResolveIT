package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.CsrfExempt;
import com.itsm.resolveit.identity.PublicEndpoint;
import com.itsm.resolveit.identity.application.port.in.CurrentUserView;
import com.itsm.resolveit.identity.application.port.in.GetCurrentUserUseCase;
import com.itsm.resolveit.identity.domain.model.SessionToken;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.lang.annotation.Annotation;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.Optional;
import java.util.Set;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Protects every ResolveIT endpoint (RIT-US-05, common security rules).
 *
 * <ol>
 *   <li>Session: unless the endpoint is {@link PublicEndpoint}, the {@code RIT_SESSION} cookie must
 *       belong to a valid, unexpired session of an active user, otherwise 401
 *       {@code AUTH_UNAUTHENTICATED}. The current user is then available to the controller.</li>
 *   <li>CSRF: a state-changing request (POST, PUT, PATCH, DELETE) needs an {@code X-XSRF-TOKEN} header
 *       equal to the {@code XSRF-TOKEN} cookie, otherwise 403 {@code AUTH_CSRF_INVALID}. Only
 *       {@link CsrfExempt} endpoints (login) skip it.</li>
 * </ol>
 * It runs only for mapped ResolveIT controller methods: unknown paths still answer 404, wrong methods
 * 405, and framework endpoints (health, OpenAPI) are untouched.
 */
class RequestProtectionInterceptor implements HandlerInterceptor {

    static final String CURRENT_USER_ATTRIBUTE = RequestProtectionInterceptor.class.getName() + ".currentUser";
    static final String XSRF_HEADER = "X-XSRF-TOKEN";

    private static final String RESOLVEIT_PACKAGE = "com.itsm.resolveit.";
    private static final Set<String> STATE_CHANGING = Set.of("POST", "PUT", "PATCH", "DELETE");

    private final GetCurrentUserUseCase currentUser;

    RequestProtectionInterceptor(GetCurrentUserUseCase currentUser) {
        this.currentUser = currentUser;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (!(handler instanceof HandlerMethod method) || !method.getBeanType().getName().startsWith(RESOLVEIT_PACKAGE)) {
            return true;
        }
        // Session first, so an anonymous caller always gets 401 (permission table: unauthenticated → 401).
        if (!annotated(method, PublicEndpoint.class)) {
            CurrentUserView user = currentUser.currentUser(cookie(request, SessionCookies.SESSION_COOKIE).map(SessionToken::new));
            request.setAttribute(CURRENT_USER_ATTRIBUTE, user);
        }
        if (STATE_CHANGING.contains(request.getMethod()) && !annotated(method, CsrfExempt.class)) {
            verifyCsrfToken(request);
        }
        return true;
    }

    private static void verifyCsrfToken(HttpServletRequest request) {
        String header = request.getHeader(XSRF_HEADER);
        Optional<String> cookie = cookie(request, SessionCookies.XSRF_COOKIE);
        if (header == null || header.isBlank() || cookie.isEmpty()
                || !MessageDigest.isEqual(header.getBytes(StandardCharsets.UTF_8), cookie.get().getBytes(StandardCharsets.UTF_8))) {
            throw new CsrfTokenInvalidException();
        }
    }

    private static Optional<String> cookie(HttpServletRequest request, String name) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) {
            return Optional.empty();
        }
        return Arrays.stream(cookies)
                .filter(cookie -> name.equals(cookie.getName()))
                .map(Cookie::getValue)
                .filter(value -> value != null && !value.isBlank())
                .findFirst();
    }

    private static boolean annotated(HandlerMethod method, Class<? extends Annotation> annotation) {
        return method.hasMethodAnnotation(annotation) || method.getBeanType().isAnnotationPresent(annotation);
    }
}
