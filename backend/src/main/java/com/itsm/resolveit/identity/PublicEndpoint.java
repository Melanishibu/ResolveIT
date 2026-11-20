package com.itsm.resolveit.identity;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks a ResolveIT endpoint that needs no session (RIT-US-05). Every other ResolveIT endpoint
 * requires a valid session and answers 401 {@code AUTH_UNAUTHENTICATED} without one. CSRF
 * protection still applies to public state-changing endpoints unless they are {@link CsrfExempt}.
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
public @interface PublicEndpoint {
}
