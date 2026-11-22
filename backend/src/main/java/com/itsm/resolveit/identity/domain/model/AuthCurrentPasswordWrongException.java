package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** Thrown when the current password provided during password change is incorrect (RIT-US-27). */
public final class AuthCurrentPasswordWrongException extends DomainException {

    public AuthCurrentPasswordWrongException() {
        super(IdentityErrorCode.AUTH_CURRENT_PASSWORD_WRONG, Map.of());
    }
}
