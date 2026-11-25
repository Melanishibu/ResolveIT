package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.domain.model.IdentityErrorCode;
import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** A state-changing request whose CSRF token is missing or doesn't match ({@code AUTH_CSRF_INVALID}, 403). */
final class CsrfTokenInvalidException extends DomainException {

    CsrfTokenInvalidException() {
        super(IdentityErrorCode.AUTH_CSRF_INVALID, Map.of());
    }
}
