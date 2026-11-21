package com.itsm.resolveit.incident.adapters.out.integration;

import com.itsm.resolveit.identity.UserLookup;
import com.itsm.resolveit.incident.application.port.out.UserDirectory;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * {@link UserDirectory} on the identity context's published {@link UserLookup} (anti-corruption layer): the
 * incident context never reads identity tables or internal types (RIT-US-10, common rules).
 */
public class IdentityUserDirectory implements UserDirectory {

    private final UserLookup userLookup;

    public IdentityUserDirectory(UserLookup userLookup) {
        this.userLookup = Objects.requireNonNull(userLookup, "userLookup");
    }

    @Override
    public boolean isActiveSupportAgent(UUID userId) {
        return userLookup.isActiveSupportAgent(userId);
    }

    @Override
    public Optional<UserSummary> find(UUID userId) {
        return userLookup.findById(userId)
                .map(card -> new UserSummary(card.id(), card.name(), card.department(), card.active()));
    }
}
