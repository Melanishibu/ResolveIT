package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** Login refused because the account is locked after too many failed attempts. */
public final class LoginTemporarilyBlockedException extends DomainException {

    public LoginTemporarilyBlockedException(long retryAfterMinutes) {
        super(IdentityErrorCode.AUTH_LOGIN_TEMPORARILY_BLOCKED, Map.of("retryAfterMinutes", retryAfterMinutes));
    }
}
