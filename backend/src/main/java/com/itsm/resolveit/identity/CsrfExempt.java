package com.itsm.resolveit.identity;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Exempts a state-changing endpoint from the CSRF check. Only for {@code POST /auth/login}, which
 * issues the CSRF token in the first place (RIT-US-04 decision). Do not use it elsewhere.
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface CsrfExempt {
}
