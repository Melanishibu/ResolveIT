package com.itsm.resolveit.identity.domain.model;

import java.util.Objects;
import java.util.UUID;

/** Identity of a {@link UserSession}. */
public record SessionId(UUID value) {

    public SessionId {
        Objects.requireNonNull(value, "value");
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
