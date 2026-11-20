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
    AUTH_UNAUTHENTICATED(Set.of()),
    /** A state-changing request without a matching X-XSRF-TOKEN header and XSRF-TOKEN cookie (RIT-US-05). */
    AUTH_CSRF_INVALID(Set.of()),
    /** A user with this email already exists (case-insensitive) (RIT-US-06). */
    USER_EMAIL_TAKEN(Set.of("email")),
    /** Admins can only create Support Agents and Employees (RIT-US-06). */
    USER_ROLE_NOT_ALLOWED(Set.of("role")),
    /** The set-password link is unknown or was already used (RIT-US-07). */
    AUTH_TOKEN_INVALID(Set.of()),
    /** The set-password link is older than 24 hours (RIT-US-07). */
    AUTH_TOKEN_EXPIRED(Set.of()),
    /** The new password breaks the policy: 12–128 characters, a letter and a digit, not the email (RIT-US-07). */
    PASSWORD_POLICY_VIOLATION(Set.of());

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
