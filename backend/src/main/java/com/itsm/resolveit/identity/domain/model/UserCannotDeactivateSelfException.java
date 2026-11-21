package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** An Admin tried to deactivate their own account ({@code USER_CANNOT_DEACTIVATE_SELF}, 409). */
public final class UserCannotDeactivateSelfException extends DomainException {

    public UserCannotDeactivateSelfException() {
        super(IdentityErrorCode.USER_CANNOT_DEACTIVATE_SELF, Map.of());
    }
}
