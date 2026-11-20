package com.itsm.resolveit.incident.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * One append-only entry of an incident's audit history (common rules, Audit): actor, action, old
 * value, new value, UTC timestamp.
 */
public record IncidentAuditEntry(IncidentId incidentId, UUID actorId, IncidentAuditAction action, String oldValue,
                                 String newValue, Instant occurredAt) {

    public IncidentAuditEntry {
        Objects.requireNonNull(incidentId, "incidentId");
        Objects.requireNonNull(actorId, "actorId");
        Objects.requireNonNull(action, "action");
        Objects.requireNonNull(occurredAt, "occurredAt");
    }

    /** The incident actions of the common rules. */
    public enum IncidentAuditAction {
        CREATED,
        ASSIGNED,
        REASSIGNED,
        STARTED,
        RESOLVED,
        REOPENED,
        CLOSED,
        PRIORITY_CHANGED
    }
}
