package com.itsm.resolveit.incident.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.itsm.resolveit.identity.AccessDeniedException;
import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.ActorRole;
import com.itsm.resolveit.incident.application.port.in.ReportIncidentCommand;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.application.port.out.TicketNumberGenerator;
import com.itsm.resolveit.incident.domain.model.Category;
import com.itsm.resolveit.incident.domain.model.Description;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import com.itsm.resolveit.incident.domain.model.Priority;
import com.itsm.resolveit.incident.domain.model.TicketNumber;
import com.itsm.resolveit.incident.domain.model.Title;
import java.time.Clock;
import java.time.Instant;
import java.time.Year;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** RIT-US-09 use case with in-memory ports. */
class ReportIncidentServiceTest {

    private static final UUID EMPLOYEE = UUID.fromString("00000000-0000-4000-8000-000000000004");

    private final InMemoryIncidents incidents = new InMemoryIncidents();
    private final InMemoryTicketNumbers ticketNumbers = new InMemoryTicketNumbers();
    private final List<IncidentAuditEntry> audit = new ArrayList<>();

    @Test
    void anEmployeeReportsAnIncident() {
        var view = service(Instant.parse("2026-11-20T15:30:00Z")).report(command(ActorRole.EMPLOYEE));

        Incident incident = view.incident();
        assertThat(incident.ticketNumber().value()).isEqualTo("INC-2026-00001");
        assertThat(incident.createdBy()).isEqualTo(EMPLOYEE);
        assertThat(incidents.byId).containsKey(incident.id());
        assertThat(audit).singleElement().satisfies(entry -> {
            assertThat(entry.action()).isEqualTo(IncidentAuditEntry.IncidentAuditAction.CREATED);
            assertThat(entry.actorId()).isEqualTo(EMPLOYEE);
        });
    }

    @Test
    void anAdminMayReportAnIncident() {
        assertThat(service(Instant.parse("2026-11-20T15:30:00Z")).report(command(ActorRole.ADMIN))).isNotNull();
    }

    @Test
    void aSupportAgentIsRefusedBeforeAnythingIsWritten() {
        assertThatThrownBy(() -> service(Instant.parse("2026-11-20T15:30:00Z")).report(command(ActorRole.SUPPORT_AGENT)))
                .isInstanceOf(AccessDeniedException.class);
        assertThat(incidents.byId).isEmpty();
        assertThat(audit).isEmpty();
        assertThat(ticketNumbers.lastPerYear).as("no number used").isEmpty();
    }

    @Test
    void theTicketYearIsTheUtcYearOfCreation() {
        // 23:30 on 31 Dec in UTC is already 1 January in India; the ticket year follows UTC.
        Instant newYearsEveUtc = Instant.parse("2026-12-31T23:30:00Z");
        Clock indiaClock = Clock.fixed(newYearsEveUtc, ZoneId.of("Asia/Kolkata"));
        var service = new ReportIncidentService(incidents, ticketNumbers, audit::add, indiaClock);

        assertThat(service.report(command(ActorRole.EMPLOYEE)).incident().ticketNumber().value())
                .isEqualTo("INC-2026-00001");
    }

    private ReportIncidentService service(Instant now) {
        return new ReportIncidentService(incidents, ticketNumbers, audit::add, Clock.fixed(now, ZoneId.of("UTC")));
    }

    private static ReportIncidentCommand command(ActorRole role) {
        return new ReportIncidentCommand(new Actor(EMPLOYEE, role), new Title("Laptop won't start"),
                new Description("Black screen"), Category.HARDWARE, Priority.HIGH);
    }

    private static final class InMemoryIncidents implements IncidentRepository {
        final Map<IncidentId, Incident> byId = new HashMap<>();

        @Override
        public IncidentId nextId() {
            return new IncidentId(UUID.randomUUID());
        }

        @Override
        public void save(Incident incident) {
            byId.put(incident.id(), incident);
        }

        @Override
        public Optional<Incident> findById(IncidentId id) {
            return Optional.ofNullable(byId.get(id));
        }
    }

    private static final class InMemoryTicketNumbers implements TicketNumberGenerator {
        final Map<Year, Integer> lastPerYear = new HashMap<>();

        @Override
        public TicketNumber next(Year year) {
            return TicketNumber.of(year, lastPerYear.merge(year, 1, Integer::sum));
        }
    }
}
