package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.application.port.out.DashboardReadModel.Counts;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** The dashboard for the caller's role scope (RIT-US-21). */
public interface DashboardUseCase {

    Counts summary(Actor actor);

    List<ActivityView> recentActivity(Actor actor, int limit);

    /** One recent change; actorName is null if that user no longer exists. */
    record ActivityView(UUID incidentId, String ticketNumber, String action, String actorName, Instant occurredAt) {
    }
}
