package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** No user with this id ({@code USER_NOT_FOUND}, 404). */
public final class UserNotFoundException extends DomainException {

    public UserNotFoundException(UserId id) {
        super(IdentityErrorCode.USER_NOT_FOUND, Map.of("id", id.value().toString()));
    }
}
