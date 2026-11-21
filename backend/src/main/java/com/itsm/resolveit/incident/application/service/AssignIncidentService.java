package com.itsm.resolveit.incident.application.service;

import com.itsm.resolveit.identity.Permission;
import com.itsm.resolveit.incident.application.port.in.AssignIncidentCommand;
import com.itsm.resolveit.incident.application.port.in.AssignIncidentUseCase;
import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsQuery;
import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsUseCase;
import com.itsm.resolveit.incident.application.port.in.IncidentDetailsView;
import com.itsm.resolveit.incident.application.port.out.IncidentAuditLog;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.application.port.out.UserDirectory;
import com.itsm.resolveit.incident.domain.model.AssigneeNotActiveAgentException;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentNotFoundException;
import java.time.Clock;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/** Assign / reassign (RIT-US-14): Admin only, active Support Agent only, transition rules in the aggregate. */
public class AssignIncidentService implements AssignIncidentUseCase {

    private final IncidentRepository incidents;
    private final UserDirectory users;
    private final IncidentAuditLog auditLog;
    private final GetIncidentDetailsUseCase details;
    private final Clock clock;

    public AssignIncidentService(IncidentRepository incidents, UserDirectory users, IncidentAuditLog auditLog,
                                 GetIncidentDetailsUseCase details, Clock clock) {
        this.incidents = Objects.requireNonNull(incidents, "incidents");
        this.users = Objects.requireNonNull(users, "users");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.details = Objects.requireNonNull(details, "details");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional
    @Override
    public IncidentDetailsView assign(AssignIncidentCommand command) {
        command.actor().require(Permission.ASSIGN_INCIDENT);
        Incident incident = incidents.findById(command.incidentId()).orElseThrow(IncidentNotFoundException::new);
        if (!users.isActiveSupportAgent(command.agentId())) {
            throw new AssigneeNotActiveAgentException();
        }
        auditLog.append(incident.assignTo(command.agentId(), command.actor().userId(), clock.instant()));
        incidents.save(incident);
        return details.details(new GetIncidentDetailsQuery(command.actor(), command.incidentId()));
    }
}
