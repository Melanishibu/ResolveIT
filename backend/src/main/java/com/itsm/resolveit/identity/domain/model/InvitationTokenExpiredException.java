package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** The set-password link is older than 24 hours ({@code AUTH_TOKEN_EXPIRED}, 400). */
public final class InvitationTokenExpiredException extends DomainException {

    public InvitationTokenExpiredException() {
        super(IdentityErrorCode.AUTH_TOKEN_EXPIRED, Map.of());
    }
}
