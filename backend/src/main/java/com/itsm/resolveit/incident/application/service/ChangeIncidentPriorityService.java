package com.itsm.resolveit.incident.application.service;

import com.itsm.resolveit.identity.Permission;
import com.itsm.resolveit.incident.application.port.in.ChangeIncidentPriorityCommand;
import com.itsm.resolveit.incident.application.port.in.ChangeIncidentPriorityUseCase;
import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsQuery;
import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsUseCase;
import com.itsm.resolveit.incident.application.port.in.IncidentDetailsView;
import com.itsm.resolveit.incident.application.port.out.IncidentAuditLog;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry;
import com.itsm.resolveit.incident.domain.model.IncidentNotFoundException;
import java.time.Clock;
import java.util.Objects;
import java.util.Optional;
import org.springframework.transaction.annotation.Transactional;

/** Change incident priority (RIT-US-19): Admin only, not allowed on CLOSED. */
public class ChangeIncidentPriorityService implements ChangeIncidentPriorityUseCase {

    private final IncidentRepository incidents;
    private final IncidentAuditLog auditLog;
    private final GetIncidentDetailsUseCase details;
    private final Clock clock;

    public ChangeIncidentPriorityService(IncidentRepository incidents, IncidentAuditLog auditLog,
                                         GetIncidentDetailsUseCase details, Clock clock) {
        this.incidents = Objects.requireNonNull(incidents, "incidents");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.details = Objects.requireNonNull(details, "details");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional
    @Override
    public IncidentDetailsView changePriority(ChangeIncidentPriorityCommand command) {
        command.actor().require(Permission.CHANGE_PRIORITY);
        Incident incident = incidents.findById(command.incidentId()).orElseThrow(IncidentNotFoundException::new);
        Optional<IncidentAuditEntry> auditEntry = incident.changePriority(command.priority(), command.actor().userId(),
                clock.instant());
        if (auditEntry.isPresent()) {
            auditLog.append(auditEntry.get());
            incidents.save(incident);
        }
        return details.details(new GetIncidentDetailsQuery(command.actor(), command.incidentId()));
    }
}
