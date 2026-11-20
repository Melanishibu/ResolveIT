package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** Login refused with the generic "email or password is incorrect" message (never says which). */
public final class InvalidCredentialsException extends DomainException {

    public InvalidCredentialsException() {
        super(IdentityErrorCode.AUTH_INVALID_CREDENTIALS, Map.of());
    }
}
