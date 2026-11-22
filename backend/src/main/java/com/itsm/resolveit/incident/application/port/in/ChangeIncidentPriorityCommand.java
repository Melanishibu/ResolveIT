package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import com.itsm.resolveit.incident.domain.model.Priority;
import java.util.Objects;

/** Command for {@link ChangeIncidentPriorityUseCase} (RIT-US-19). */
public record ChangeIncidentPriorityCommand(Actor actor, IncidentId incidentId, Priority priority) {

    public ChangeIncidentPriorityCommand {
        Objects.requireNonNull(actor, "actor");
        Objects.requireNonNull(incidentId, "incidentId");
        Objects.requireNonNull(priority, "priority");
    }
}
