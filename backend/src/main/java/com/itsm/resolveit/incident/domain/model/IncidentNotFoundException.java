package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** No incident with the requested id ({@code INCIDENT_NOT_FOUND}, 404). */
public final class IncidentNotFoundException extends DomainException {

    public IncidentNotFoundException() {
        super(IncidentErrorCode.INCIDENT_NOT_FOUND, Map.of());
    }
}
