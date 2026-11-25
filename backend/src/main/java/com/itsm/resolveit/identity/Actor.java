package com.itsm.resolveit.identity;

import java.util.Objects;
import java.util.UUID;

/**
 * The authenticated user behind a request (published API of the identity context).
 *
 * <p>Controllers get it as a method parameter; use cases receive it in their command and check it
 * before doing any work (method-level authorisation in the application layer, RIT-US-05):
 * {@code command.actor().require(Permission.MANAGE_USERS)}.
 *
 * @param userId the user's id (other contexts refer to users by this UUID only)
 * @param role   the user's role
 */
public record Actor(UUID userId, ActorRole role) {

    public Actor {
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(role, "role");
    }

    public boolean may(Permission permission) {
        return permission.isGrantedTo(role);
    }

    /** Throws {@link AccessDeniedException} ({@code AUTH_FORBIDDEN}, 403) unless the role has the permission. */
    public void require(Permission permission) {
        if (!may(permission)) {
            throw new AccessDeniedException();
        }
    }
}
