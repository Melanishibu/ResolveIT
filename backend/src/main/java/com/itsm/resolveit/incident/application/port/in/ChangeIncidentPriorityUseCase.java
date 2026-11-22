package com.itsm.resolveit.incident.application.port.in;

/**
 * Changes an incident's priority (RIT-US-19): Admin only, not allowed on CLOSED. Audited as
 * PRIORITY_CHANGED.
 */
public interface ChangeIncidentPriorityUseCase {

    IncidentDetailsView changePriority(ChangeIncidentPriorityCommand command);
}
