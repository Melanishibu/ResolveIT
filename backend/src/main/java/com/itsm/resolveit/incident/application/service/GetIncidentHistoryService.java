package com.itsm.resolveit.incident.application.service;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.application.port.in.GetIncidentHistoryUseCase;
import com.itsm.resolveit.incident.application.port.in.IncidentHistoryView;
import com.itsm.resolveit.incident.application.port.out.IncidentAuditLog;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.application.port.out.UserDirectory;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentAccessDeniedException;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import com.itsm.resolveit.incident.domain.model.IncidentNotFoundException;
import com.itsm.resolveit.incident.domain.model.Viewer;
import java.util.List;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/**
 * Loads the audit history of an incident (RIT-US-13).
 * Follows the same visibility rule as the incident itself.
 */
public class GetIncidentHistoryService implements GetIncidentHistoryUseCase {

    private final IncidentRepository incidents;
    private final IncidentAuditLog auditLog;
    private final UserDirectory users;

    public GetIncidentHistoryService(IncidentRepository incidents, IncidentAuditLog auditLog, UserDirectory users) {
        this.incidents = Objects.requireNonNull(incidents, "incidents");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.users = Objects.requireNonNull(users, "users");
    }

    @Transactional(readOnly = true)
    @Override
    public List<IncidentHistoryView> history(Actor actor, IncidentId incidentId) {
        Incident incident = incidents.findById(incidentId).orElseThrow(IncidentNotFoundException::new);
        Viewer viewer = GetIncidentDetailsService.viewerOf(actor);
        if (!incident.isVisibleTo(viewer)) {
            throw new IncidentAccessDeniedException();
        }

        return auditLog.findByIncidentId(incidentId).stream()
                .map(entry -> new IncidentHistoryView(
                        entry.incidentId().value(),
                        entry.actorId(),
                        users.find(entry.actorId()).map(UserDirectory.UserSummary::name).orElse(null),
                        entry.action(),
                        entry.oldValue(),
                        entry.newValue(),
                        entry.occurredAt()
                ))
                .toList();
    }
}
