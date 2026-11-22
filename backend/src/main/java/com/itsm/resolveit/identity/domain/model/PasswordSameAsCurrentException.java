package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** Thrown when the new password is the same as the current password (RIT-US-27). */
public final class PasswordSameAsCurrentException extends DomainException {

    public PasswordSameAsCurrentException() {
        super(IdentityErrorCode.PASSWORD_SAME_AS_CURRENT, Map.of());
    }
}
