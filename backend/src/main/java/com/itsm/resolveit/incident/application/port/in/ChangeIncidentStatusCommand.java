package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import com.itsm.resolveit.incident.domain.model.IncidentStatus;
import java.util.Objects;

/** Move an incident to {@code targetStatus} (RIT-US-15). Notes and reason are used by resolve and reopen. */
public record ChangeIncidentStatusCommand(Actor actor, IncidentId incidentId, IncidentStatus targetStatus,
                                          String resolutionNotes, String reason) {

    public ChangeIncidentStatusCommand {
        Objects.requireNonNull(actor, "actor");
        Objects.requireNonNull(incidentId, "incidentId");
        Objects.requireNonNull(targetStatus, "targetStatus");
    }
}
