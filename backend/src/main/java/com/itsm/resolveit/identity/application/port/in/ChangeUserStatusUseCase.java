package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.UserRow;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.util.Objects;

/**
 * Use case: an Admin activates or deactivates a user (RIT-US-08). Admins cannot deactivate
 * themselves ({@code USER_CANNOT_DEACTIVATE_SELF}); an unknown id gives {@code USER_NOT_FOUND}.
 */
public interface ChangeUserStatusUseCase {

    /** Returns the user's row after the change. */
    UserRow changeStatus(Command command);

    record Command(Actor actor, UserId userId, boolean active) {

        public Command {
            Objects.requireNonNull(actor, "actor");
            Objects.requireNonNull(userId, "userId");
        }
    }
}
