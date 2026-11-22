package com.itsm.resolveit.incident.application.service;

import com.itsm.resolveit.incident.application.port.in.IncidentListPage;
import com.itsm.resolveit.incident.application.port.in.ListIncidentsQuery;
import com.itsm.resolveit.incident.application.port.in.ListIncidentsUseCase;
import com.itsm.resolveit.incident.application.port.out.IncidentListReadModel;
import com.itsm.resolveit.incident.application.port.out.IncidentListReadModel.Scope;
import com.itsm.resolveit.incident.application.port.out.UserDirectory;
import com.itsm.resolveit.incident.domain.model.Viewer;
import java.util.Objects;
import java.util.Optional;
import org.springframework.transaction.annotation.Transactional;

/** Lists incidents scoped by the "See incidents" row of the permission table (RIT-US-11). */
public class ListIncidentsService implements ListIncidentsUseCase {

    private final IncidentListReadModel readModel;
    private final UserDirectory users;

    public ListIncidentsService(IncidentListReadModel readModel, UserDirectory users) {
        this.readModel = Objects.requireNonNull(readModel, "readModel");
        this.users = Objects.requireNonNull(users, "users");
    }

    @Transactional(readOnly = true)
    @Override
    public IncidentListPage list(ListIncidentsQuery query) {
        Viewer viewer = GetIncidentDetailsService.viewerOf(query.actor());
        Scope scope = scopeFor(viewer);
        IncidentListReadModel.Rows rows = readModel.page(scope,
                new IncidentListReadModel.Filter(query.q(), query.statuses(), query.priorities(), query.categories(),
                        query.createdFrom(), query.createdTo()), query.page(), query.size(),
                query.sort(), query.ascending());
        return toPage(query, rows);
    }

    /** The "See incidents" row of the permission table as a read-model scope (also used by the dashboard). */
    static Scope scopeFor(Viewer viewer) {
        return switch (viewer.role()) {
            case ADMIN -> Scope.all();
            case EMPLOYEE -> Scope.createdBy(viewer.userId());
            case SUPPORT_AGENT -> Scope.assignedTo(viewer.userId());
        };
    }

    private IncidentListPage toPage(ListIncidentsQuery query, IncidentListReadModel.Rows rows) {
        return new IncidentListPage(rows.rows().stream()
                .map(row -> new IncidentListPage.Item(row.id(), row.ticketNumber(), row.title(), row.category(),
                        row.priority(), row.status(),
                        row.assignedTo() == null ? Optional.empty() : users.find(row.assignedTo()),
                        row.createdAt(), row.updatedAt()))
                .toList(), query.page(), query.size(), rows.totalItems());
    }
}
