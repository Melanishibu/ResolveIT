package com.itsm.resolveit.identity.domain.model;

import java.util.Objects;
import java.util.UUID;

/** Identity of an {@link Invitation}. */
public record InvitationId(UUID value) {

    public InvitationId {
        Objects.requireNonNull(value, "value");
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
