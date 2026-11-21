package com.itsm.resolveit.identity;

import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Published API of the identity context: how other contexts read a user's display data by id (RIT-US-10).
 * They never read identity tables or internal types.
 */
public interface UserLookup {

    Optional<UserCard> findById(UUID userId);

    /** Whether the user exists, is a Support Agent and is active (assignment rule, RIT-US-14). */
    boolean isActiveSupportAgent(UUID userId);

    /** The active Support Agents, by name (assign dialog, RIT-US-14). */
    java.util.List<AgentCard> activeSupportAgents();

    /** An assignable Support Agent: name and email. */
    record AgentCard(UUID id, String name, String email) {
    }

    /** A user's display data: name, department and whether the account is active. */
    record UserCard(UUID id, String name, String department, boolean active) {

        public UserCard {
            Objects.requireNonNull(id, "id");
            Objects.requireNonNull(name, "name");
            Objects.requireNonNull(department, "department");
        }
    }
}
