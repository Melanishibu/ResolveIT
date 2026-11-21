package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** A CLOSED incident is final: it takes no comments (BR-013, {@code INCIDENT_CLOSED}, 409). */
public final class IncidentClosedException extends DomainException {

    public IncidentClosedException() {
        super(IncidentErrorCode.INCIDENT_CLOSED, Map.of());
    }
}
