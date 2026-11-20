package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.model.InvitationToken;
import java.util.Objects;

/** The token from the link and the raw new password (checked against the policy by the use case). */
public record SetPasswordCommand(InvitationToken token, String newPassword) {

    public SetPasswordCommand {
        Objects.requireNonNull(token, "token");
        Objects.requireNonNull(newPassword, "newPassword");
    }

    /** Never print the token or the password. */
    @Override
    public String toString() {
        return "SetPasswordCommand[***]";
    }
}
