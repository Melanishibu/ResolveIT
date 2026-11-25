package com.itsm.resolveit.incident.application.port.in;

/** Changes an incident's status and returns it as the caller now sees it (RIT-US-15). */
public interface ChangeIncidentStatusUseCase {

    IncidentDetailsView changeStatus(ChangeIncidentStatusCommand command);
}
