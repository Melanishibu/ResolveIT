package com.itsm.resolveit.incident.application.port.out;

import com.itsm.resolveit.incident.application.port.out.IncidentListReadModel.Scope;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Read model for the dashboard (CQRS-lite, RIT-US-21): counts and recent audit entries inside a visibility scope. */
public interface DashboardReadModel {

    /** One aggregate query over the scope. */
    Counts counts(Scope scope);

    /** The latest incident audit entries in the scope, newest first. */
    List<Activity> recentActivity(Scope scope, int limit);

    /** critical = priority CRITICAL and status not CLOSED; total counts every status. */
    record Counts(long total, long open, long assigned, long inProgress, long resolved, long critical) {
    }

    record Activity(UUID incidentId, String ticketNumber, String action, UUID actorId, Instant occurredAt) {
    }
}
