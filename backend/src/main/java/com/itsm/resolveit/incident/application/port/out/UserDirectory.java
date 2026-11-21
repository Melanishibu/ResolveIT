package com.itsm.resolveit.incident.application.port.out;

import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * What the incident context needs to know about a user at display time (RIT-US-10): name, department and
 * whether the account is active. Implemented by an adapter on top of the identity context's published API.
 */
public interface UserDirectory {

    Optional<UserSummary> find(UUID userId);

    /** A user as shown on an incident. */
    record UserSummary(UUID id, String name, String department, boolean active) {

        public UserSummary {
            Objects.requireNonNull(id, "id");
            Objects.requireNonNull(name, "name");
            Objects.requireNonNull(department, "department");
        }
    }
}
