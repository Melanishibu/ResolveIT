package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** The request has no valid session: missing, expired, logged out, or the user is no longer active. */
public final class NotAuthenticatedException extends DomainException {

    public NotAuthenticatedException() {
        super(IdentityErrorCode.AUTH_UNAUTHENTICATED, Map.of());
    }
}
