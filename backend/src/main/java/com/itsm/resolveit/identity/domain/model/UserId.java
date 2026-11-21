package com.itsm.resolveit.identity.domain.model;

import java.util.Objects;
import java.util.UUID;

/** Identity of a {@link User}. Other bounded contexts refer to users by this UUID only. */
public record UserId(UUID value) {

    public UserId {
        Objects.requireNonNull(value, "value");
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
