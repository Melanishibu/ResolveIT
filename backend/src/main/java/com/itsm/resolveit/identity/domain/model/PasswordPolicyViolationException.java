package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** The new password breaks the password policy ({@code PASSWORD_POLICY_VIOLATION}, 400). */
public final class PasswordPolicyViolationException extends DomainException {

    public PasswordPolicyViolationException() {
        super(IdentityErrorCode.PASSWORD_POLICY_VIOLATION, Map.of());
    }
}
