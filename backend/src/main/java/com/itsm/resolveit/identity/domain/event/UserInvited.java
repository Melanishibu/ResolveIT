package com.itsm.resolveit.identity.domain.event;

import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.InvitationId;
import com.itsm.resolveit.identity.domain.model.InvitationToken;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.util.Objects;
import java.util.UUID;

/**
 * A user was invited (RIT-US-06). Handled after the commit to send the invitation email.
 *
 * <p>Carries the raw token only in memory, so the email can contain the link; it is never stored or
 * logged ({@link InvitationToken#toString()} hides it).
 */
public record UserInvited(UserId userId, InvitationId invitationId, EmailAddress email, DisplayName name, Role role,
                          InvitationToken token, UUID actorId, boolean resend) {

    public UserInvited(UserId userId, InvitationId invitationId, EmailAddress email, DisplayName name, Role role,
                       InvitationToken token, UUID actorId) {
        this(userId, invitationId, email, name, role, token, actorId, false);
    }

    public UserInvited {
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(invitationId, "invitationId");
        Objects.requireNonNull(email, "email");
        Objects.requireNonNull(name, "name");
        Objects.requireNonNull(role, "role");
        Objects.requireNonNull(token, "token");
    }
}
