package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import java.util.Objects;

/** Open the incident {@code incidentId} as {@code actor} (RIT-US-10). */
public record GetIncidentDetailsQuery(Actor actor, IncidentId incidentId) {

    public GetIncidentDetailsQuery {
        Objects.requireNonNull(actor, "actor");
        Objects.requireNonNull(incidentId, "incidentId");
    }
}
