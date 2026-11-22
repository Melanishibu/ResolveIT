package com.itsm.resolveit.incident.application.service;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.application.port.in.DashboardUseCase;
import com.itsm.resolveit.incident.application.port.out.DashboardReadModel;
import com.itsm.resolveit.incident.application.port.out.DashboardReadModel.Counts;
import com.itsm.resolveit.incident.application.port.out.UserDirectory;
import java.util.List;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/** Dashboard counts and recent activity, scoped like the incident list (RIT-US-21). */
public class DashboardService implements DashboardUseCase {

    private final DashboardReadModel readModel;
    private final UserDirectory users;

    public DashboardService(DashboardReadModel readModel, UserDirectory users) {
        this.readModel = Objects.requireNonNull(readModel, "readModel");
        this.users = Objects.requireNonNull(users, "users");
    }

    @Transactional(readOnly = true)
    @Override
    public Counts summary(Actor actor) {
        return readModel.counts(ListIncidentsService.scopeFor(GetIncidentDetailsService.viewerOf(actor)));
    }

    @Transactional(readOnly = true)
    @Override
    public List<ActivityView> recentActivity(Actor actor, int limit) {
        return readModel.recentActivity(ListIncidentsService.scopeFor(GetIncidentDetailsService.viewerOf(actor)),
                        limit).stream()
                .map(entry -> new ActivityView(entry.incidentId(), entry.ticketNumber(), entry.action(),
                        users.find(entry.actorId()).map(UserDirectory.UserSummary::name).orElse(null),
                        entry.occurredAt()))
                .toList();
    }
}
