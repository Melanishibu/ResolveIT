package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** Reopening needs a reason of 10–500 characters ({@code INCIDENT_REOPEN_REASON_REQUIRED}, 400). */
public final class IncidentReopenReasonRequiredException extends DomainException {

    public IncidentReopenReasonRequiredException() {
        super(IncidentErrorCode.INCIDENT_REOPEN_REASON_REQUIRED,
                Map.of("min", String.valueOf(ReopenReason.MIN_LENGTH), "max",
                        String.valueOf(ReopenReason.MAX_LENGTH)));
    }
}
