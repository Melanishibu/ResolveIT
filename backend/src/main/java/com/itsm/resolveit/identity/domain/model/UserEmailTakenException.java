package com.itsm.resolveit.identity.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** A user with this email already exists, compared case-insensitively ({@code USER_EMAIL_TAKEN}, 409). */
public final class UserEmailTakenException extends DomainException {

    public UserEmailTakenException(EmailAddress email) {
        super(IdentityErrorCode.USER_EMAIL_TAKEN, Map.of("email", email.value()));
    }
}
