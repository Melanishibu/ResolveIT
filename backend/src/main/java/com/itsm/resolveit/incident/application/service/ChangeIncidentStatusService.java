package com.itsm.resolveit.incident.application.service;

import com.itsm.resolveit.identity.AccessDeniedException;
import com.itsm.resolveit.incident.application.port.in.ChangeIncidentStatusCommand;
import com.itsm.resolveit.incident.application.port.in.ChangeIncidentStatusUseCase;
import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsQuery;
import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsUseCase;
import com.itsm.resolveit.incident.application.port.in.IncidentDetailsView;
import com.itsm.resolveit.incident.application.port.out.IncidentAuditLog;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentAccessDeniedException;
import com.itsm.resolveit.incident.domain.model.IncidentAction;
import com.itsm.resolveit.incident.domain.model.IncidentInvalidTransitionException;
import com.itsm.resolveit.incident.domain.model.IncidentNotFoundException;
import com.itsm.resolveit.incident.domain.model.Viewer;
import java.time.Clock;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/**
 * One endpoint for all status changes (RIT-US-15). Order of checks: the incident must be visible (403
 * INCIDENT_ACCESS_DENIED), the target must be an allowed transition (409), and the caller's role must allow that
 * action on this incident (403 AUTH_FORBIDDEN). Only start work is built; resolve, reopen and close follow in
 * RIT-US-16 to RIT-US-18 and are answered as invalid transitions until then.
 */
public class ChangeIncidentStatusService implements ChangeIncidentStatusUseCase {

    private final IncidentRepository incidents;
    private final IncidentAuditLog auditLog;
    private final GetIncidentDetailsUseCase details;
    private final Clock clock;

    public ChangeIncidentStatusService(IncidentRepository incidents, IncidentAuditLog auditLog,
                                       GetIncidentDetailsUseCase details, Clock clock) {
        this.incidents = Objects.requireNonNull(incidents, "incidents");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.details = Objects.requireNonNull(details, "details");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional
    @Override
    public IncidentDetailsView changeStatus(ChangeIncidentStatusCommand command) {
        Incident incident = incidents.findById(command.incidentId()).orElseThrow(IncidentNotFoundException::new);
        Viewer viewer = GetIncidentDetailsService.viewerOf(command.actor());
        if (!incident.isVisibleTo(viewer)) {
            throw new IncidentAccessDeniedException();
        }
        IncidentAction action = incident.statusActionFor(command.targetStatus());
        if (!incident.allowedActionsFor(viewer).contains(action)) {
            throw new AccessDeniedException();
        }
        if (action != IncidentAction.START) {
            throw new IncidentInvalidTransitionException(incident.status());
        }
        auditLog.append(incident.startWork(viewer.userId(), clock.instant()));
        incidents.save(incident);
        return details.details(new GetIncidentDetailsQuery(command.actor(), command.incidentId()));
    }
}
