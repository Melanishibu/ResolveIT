package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.ErrorCode;
import java.util.Set;

/** Error codes of the identity context. Each is registered in {@code ErrorCodeRegistry} (error gate). */
public enum IdentityErrorCode implements ErrorCode {

    /** Wrong email or password, unknown email, or inactive account: one generic message (common rules). */
    AUTH_INVALID_CREDENTIALS(Set.of()),
    /** 5 consecutive failures lock the account for 15 minutes. */
    AUTH_LOGIN_TEMPORARILY_BLOCKED(Set.of("retryAfterMinutes")),
    /** No valid session (missing, expired, logged out, or the user was deactivated). */
    AUTH_UNAUTHENTICATED(Set.of());

    private final Set<String> requiredParams;

    IdentityErrorCode(Set<String> requiredParams) {
        this.requiredParams = requiredParams;
    }

    @Override
    public String code() {
        return name();
    }

    @Override
    public Set<String> requiredParams() {
        return requiredParams;
    }
}
