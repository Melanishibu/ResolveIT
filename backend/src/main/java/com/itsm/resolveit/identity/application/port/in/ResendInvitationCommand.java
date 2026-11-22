package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.util.Objects;

public record ResendInvitationCommand(Actor actor, UserId userId) {
    public ResendInvitationCommand {
        Objects.requireNonNull(actor, "actor");
        Objects.requireNonNull(userId, "userId");
    }
}
