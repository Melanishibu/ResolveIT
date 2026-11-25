package com.itsm.resolveit.incident.domain.model;

import java.util.Objects;
import java.util.UUID;

/** Identity of an {@link Incident}. */
public record IncidentId(UUID value) {

    public IncidentId {
        Objects.requireNonNull(value, "value");
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
