package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry.IncidentAuditAction;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/** View of one audit history record for an incident (RIT-US-13). */
public record IncidentHistoryView(
        UUID incidentId,
        UUID actorId,
        String actorName,
        IncidentAuditAction action,
        String oldValue,
        String newValue,
        Instant occurredAt
) {
    public IncidentHistoryView {
        Objects.requireNonNull(incidentId, "incidentId");
        Objects.requireNonNull(actorId, "actorId");
        Objects.requireNonNull(action, "action");
        Objects.requireNonNull(occurredAt, "occurredAt");
    }
}
