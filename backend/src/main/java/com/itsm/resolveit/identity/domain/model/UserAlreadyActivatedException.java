package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** The user has already set a password and cannot be re-invited ({@code USER_ALREADY_ACTIVATED}, 409). */
public final class UserAlreadyActivatedException extends DomainException {

    public UserAlreadyActivatedException(UserId userId) {
        super(IdentityErrorCode.USER_ALREADY_ACTIVATED, Map.of("id", userId.value().toString()));
    }
}
