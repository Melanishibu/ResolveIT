package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.model.SessionId;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.util.Objects;

/** Command to change a user's password while logged in (RIT-US-27). */
public record ChangePasswordCommand(
        UserId userId,
        SessionId currentSessionId,
        String currentPassword,
        String newPassword) {

    public ChangePasswordCommand {
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(currentSessionId, "currentSessionId");
        Objects.requireNonNull(currentPassword, "currentPassword");
        Objects.requireNonNull(newPassword, "newPassword");
    }
}
