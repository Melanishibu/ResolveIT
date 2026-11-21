package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** The incident exists but the user may not see it ({@code INCIDENT_ACCESS_DENIED}, 403). */
public final class IncidentAccessDeniedException extends DomainException {

    public IncidentAccessDeniedException() {
        super(IncidentErrorCode.INCIDENT_ACCESS_DENIED, Map.of());
    }
}
