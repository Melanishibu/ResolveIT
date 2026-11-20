package com.itsm.resolveit.incident.domain.model;

/** Incident lifecycle statuses (common rules, incident model). New incidents start OPEN. */
public enum IncidentStatus {
    OPEN,
    ASSIGNED,
    IN_PROGRESS,
    RESOLVED,
    CLOSED
}
