package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import java.util.Objects;
import java.util.UUID;

/** An Admin assigns or reassigns an incident to a Support Agent (RIT-US-14). */
public record AssignIncidentCommand(Actor actor, IncidentId incidentId, UUID agentId) {

    public AssignIncidentCommand {
        Objects.requireNonNull(actor, "actor");
        Objects.requireNonNull(incidentId, "incidentId");
        Objects.requireNonNull(agentId, "agentId");
    }
}
