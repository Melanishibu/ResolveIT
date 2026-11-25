package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** The set-password link is unknown or was already used ({@code AUTH_TOKEN_INVALID}, 400). */
public final class InvitationTokenInvalidException extends DomainException {

    public InvitationTokenInvalidException() {
        super(IdentityErrorCode.AUTH_TOKEN_INVALID, Map.of());
    }
}
