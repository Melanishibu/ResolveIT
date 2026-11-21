package com.itsm.resolveit.incident.application.port.in;

/** Assigns or reassigns an incident and returns it as the Admin now sees it (RIT-US-14). */
public interface AssignIncidentUseCase {

    IncidentDetailsView assign(AssignIncidentCommand command);
}
