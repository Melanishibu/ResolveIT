package com.itsm.resolveit.incident.domain.model;

/**
 * An action a user may take on an incident (RIT-US-10 {@code allowedActions}), named after the allowed
 * transitions and the permission table of the common rules.
 */
public enum IncidentAction {
    /** OPEN → ASSIGNED. */
    ASSIGN,
    /** ASSIGNED → ASSIGNED with another Support Agent. */
    REASSIGN,
    /** Start work: ASSIGNED → IN_PROGRESS. */
    START,
    /** IN_PROGRESS → RESOLVED, notes required. */
    RESOLVE,
    /** RESOLVED → IN_PROGRESS, reason required. */
    REOPEN,
    /** RESOLVED → CLOSED. */
    CLOSE,
    /** Change the priority of an incident that is not CLOSED. */
    CHANGE_PRIORITY
}
