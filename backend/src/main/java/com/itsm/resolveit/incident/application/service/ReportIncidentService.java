package com.itsm.resolveit.incident.application.service;

import com.itsm.resolveit.identity.Permission;
import com.itsm.resolveit.incident.application.port.in.ReportIncidentCommand;
import com.itsm.resolveit.incident.application.port.in.ReportIncidentUseCase;
import com.itsm.resolveit.incident.application.port.in.ReportedIncidentView;
import com.itsm.resolveit.incident.application.port.out.IncidentAuditLog;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.application.port.out.TicketNumberGenerator;
import com.itsm.resolveit.incident.domain.model.Incident;
import java.time.Clock;
import java.time.Instant;
import java.time.Year;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/** Reports an incident: ticket number, incident and CREATED audit entry in one transaction. */
public class ReportIncidentService implements ReportIncidentUseCase {

    private final IncidentRepository incidents;
    private final TicketNumberGenerator ticketNumbers;
    private final IncidentAuditLog auditLog;
    private final Clock clock;

    public ReportIncidentService(IncidentRepository incidents, TicketNumberGenerator ticketNumbers,
                                 IncidentAuditLog auditLog, Clock clock) {
        this.incidents = Objects.requireNonNull(incidents, "incidents");
        this.ticketNumbers = Objects.requireNonNull(ticketNumbers, "ticketNumbers");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional
    @Override
    public ReportedIncidentView report(ReportIncidentCommand command) {
        command.actor().require(Permission.CREATE_INCIDENT);
        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS); // TIMESTAMPTZ precision
        Year year = Year.from(now.atZone(ZoneOffset.UTC));
        Incident incident = Incident.report(incidents.nextId(), ticketNumbers.next(year), command.title(),
                command.description(), command.category(), command.priority(), command.actor().userId(), now);
        incidents.save(incident);
        auditLog.append(incident.creationEntry());
        return new ReportedIncidentView(incident);
    }
}
