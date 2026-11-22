package com.itsm.resolveit.identity.domain.event;

import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.InvitationId;
import com.itsm.resolveit.identity.domain.model.InvitationToken;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.util.Objects;

/**
 * A user requested a password reset (RIT-US-23). Handled after commit to send the email.
 * Never logged or stored with raw token.
 */
public record PasswordResetRequested(UserId userId, InvitationId invitationId, EmailAddress email, DisplayName name,
                                     InvitationToken token) {

    public PasswordResetRequested {
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(invitationId, "invitationId");
        Objects.requireNonNull(email, "email");
        Objects.requireNonNull(name, "name");
        Objects.requireNonNull(token, "token");
    }
}
