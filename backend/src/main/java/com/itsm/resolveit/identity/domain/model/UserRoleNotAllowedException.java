package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** Admins can only create Support Agents and Employees ({@code USER_ROLE_NOT_ALLOWED}, 400). */
public final class UserRoleNotAllowedException extends DomainException {

    public UserRoleNotAllowedException(Role role) {
        super(IdentityErrorCode.USER_ROLE_NOT_ALLOWED, Map.of("role", role.name()));
    }
}
