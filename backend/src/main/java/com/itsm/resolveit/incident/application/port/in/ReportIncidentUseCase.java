package com.itsm.resolveit.incident.application.port.in;

/**
 * Use case: an Employee (or Admin) reports an incident (RIT-US-09). Refused for roles without
 * {@code CREATE_INCIDENT} ({@code AccessDeniedException}, 403).
 */
public interface ReportIncidentUseCase {

    ReportedIncidentView report(ReportIncidentCommand command);
}
