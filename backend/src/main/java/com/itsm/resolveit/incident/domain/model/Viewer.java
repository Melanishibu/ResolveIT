package com.itsm.resolveit.incident.domain.model;

import java.util.Objects;
import java.util.UUID;

/**
 * Who looks at an incident, in the incident context's own terms (RIT-US-10): the user's id and role.
 * The application layer maps the identity context's actor to this value, so the domain stays independent.
 *
 * @param userId the user's id
 * @param role   the user's role
 */
public record Viewer(UUID userId, Role role) {

    /** The roles of the permission table (common rules). */
    public enum Role {
        ADMIN, SUPPORT_AGENT, EMPLOYEE
    }

    public Viewer {
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(role, "role");
    }
}
