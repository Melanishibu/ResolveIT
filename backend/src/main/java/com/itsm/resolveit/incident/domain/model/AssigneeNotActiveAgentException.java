package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** The chosen assignee is not an active Support Agent ({@code ASSIGNEE_NOT_ACTIVE_AGENT}, 422). */
public final class AssigneeNotActiveAgentException extends DomainException {

    public AssigneeNotActiveAgentException() {
        super(IncidentErrorCode.ASSIGNEE_NOT_ACTIVE_AGENT, Map.of());
    }
}
