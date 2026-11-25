package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** The action is not an allowed transition from the incident's status ({@code INCIDENT_INVALID_TRANSITION}, 409). */
public final class IncidentInvalidTransitionException extends DomainException {

    public IncidentInvalidTransitionException(IncidentStatus status) {
        super(IncidentErrorCode.INCIDENT_INVALID_TRANSITION, Map.of("status", status.name()));
    }
}
