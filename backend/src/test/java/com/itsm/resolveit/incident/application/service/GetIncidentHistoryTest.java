package com.itsm.resolveit.incident.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.ActorRole;
import com.itsm.resolveit.incident.application.port.in.IncidentHistoryView;
import com.itsm.resolveit.incident.application.port.out.IncidentAuditLog;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.application.port.out.UserDirectory;
import com.itsm.resolveit.incident.domain.model.Category;
import com.itsm.resolveit.incident.domain.model.Description;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentAccessDeniedException;
import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry;
import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry.IncidentAuditAction;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import com.itsm.resolveit.incident.domain.model.IncidentNotFoundException;
import com.itsm.resolveit.incident.domain.model.Priority;
import com.itsm.resolveit.incident.domain.model.TicketNumber;
import com.itsm.resolveit.incident.domain.model.Title;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class GetIncidentHistoryTest {

    private static final UUID ADMIN_ID = UUID.fromString("00000000-0000-4000-8000-000000000001");
    private static final UUID AGENT_ID = UUID.fromString("00000000-0000-4000-8000-000000000002");
    private static final UUID EMPLOYEE_ID = UUID.fromString("00000000-0000-4000-8000-000000000004");
    private static final UUID OTHER_EMPLOYEE_ID = UUID.fromString("00000000-0000-4000-8000-000000000005");

    private final InMemoryIncidents incidents = new InMemoryIncidents();
    private final InMemoryAuditLog auditLog = new InMemoryAuditLog();
    private final InMemoryUserDirectory users = new InMemoryUserDirectory();
    private GetIncidentHistoryService service;

    private IncidentId incidentId;

    @BeforeEach
    void setUp() {
        service = new GetIncidentHistoryService(incidents, auditLog, users);
        incidentId = new IncidentId(UUID.randomUUID());

        Incident incident = Incident.reconstitute(
                incidentId,
                new TicketNumber("INC-2026-00001"),
                new Title("Test incident"),
                new Description("Description"),
                Category.HARDWARE,
                Priority.LOW,
                com.itsm.resolveit.incident.domain.model.IncidentStatus.ASSIGNED,
                EMPLOYEE_ID,
                Instant.parse("2026-11-20T10:00:00Z"),
                Instant.parse("2026-11-20T10:05:00Z"),
                AGENT_ID
        );
        incidents.save(incident);

        users.add(ADMIN_ID, "ResolveIT Admin");
        users.add(AGENT_ID, "Agent One");
        users.add(EMPLOYEE_ID, "Employee One");

        // Add 2 audit entries: CREATED, then ASSIGNED
        auditLog.append(new IncidentAuditEntry(incidentId, EMPLOYEE_ID, IncidentAuditAction.CREATED, null, null,
                Instant.parse("2026-11-20T10:00:00Z")));
        auditLog.append(new IncidentAuditEntry(incidentId, ADMIN_ID, IncidentAuditAction.ASSIGNED, "OPEN", "ASSIGNED",
                Instant.parse("2026-11-20T10:05:00Z")));
    }

    @Test
    void adminSeesFullHistoryNewestFirst() {
        Actor admin = new Actor(ADMIN_ID, ActorRole.ADMIN);
        List<IncidentHistoryView> history = service.history(admin, incidentId);

        assertThat(history).hasSize(2);
        assertThat(history.get(0).action()).isEqualTo(IncidentAuditAction.ASSIGNED);
        assertThat(history.get(0).actorName()).isEqualTo("ResolveIT Admin");
        assertThat(history.get(0).oldValue()).isEqualTo("OPEN");
        assertThat(history.get(0).newValue()).isEqualTo("ASSIGNED");

        assertThat(history.get(1).action()).isEqualTo(IncidentAuditAction.CREATED);
        assertThat(history.get(1).actorName()).isEqualTo("Employee One");
    }

    @Test
    void employeeSeesOwnIncidentHistory() {
        Actor employee = new Actor(EMPLOYEE_ID, ActorRole.EMPLOYEE);
        List<IncidentHistoryView> history = service.history(employee, incidentId);

        assertThat(history).hasSize(2);
    }

    @Test
    void otherEmployeeIsDenied() {
        Actor other = new Actor(OTHER_EMPLOYEE_ID, ActorRole.EMPLOYEE);
        assertThatThrownBy(() -> service.history(other, incidentId))
                .isInstanceOf(IncidentAccessDeniedException.class);
    }

    @Test
    void nonExistentIncidentThrowsNotFound() {
        Actor admin = new Actor(ADMIN_ID, ActorRole.ADMIN);
        IncidentId nonExistent = new IncidentId(UUID.randomUUID());
        assertThatThrownBy(() -> service.history(admin, nonExistent))
                .isInstanceOf(IncidentNotFoundException.class);
    }

    private static class InMemoryIncidents implements IncidentRepository {
        private final Map<IncidentId, Incident> map = new HashMap<>();

        @Override
        public IncidentId nextId() {
            return new IncidentId(UUID.randomUUID());
        }

        @Override
        public void save(Incident incident) {
            map.put(incident.id(), incident);
        }

        @Override
        public Optional<Incident> findById(IncidentId id) {
            return Optional.ofNullable(map.get(id));
        }

        public Optional<Incident> findByTicketNumber(TicketNumber ticketNumber) {
            return map.values().stream().filter(i -> i.ticketNumber().equals(ticketNumber)).findFirst();
        }
    }

    private static class InMemoryAuditLog implements IncidentAuditLog {
        private final List<IncidentAuditEntry> entries = new ArrayList<>();

        @Override
        public void append(IncidentAuditEntry entry) {
            entries.add(entry);
        }

        @Override
        public List<IncidentAuditEntry> findByIncidentId(IncidentId incidentId) {
            return entries.stream()
                    .filter(e -> e.incidentId().equals(incidentId))
                    .sorted((a, b) -> b.occurredAt().compareTo(a.occurredAt()))
                    .toList();
        }
    }

    private static class InMemoryUserDirectory implements UserDirectory {
        private final Map<UUID, UserSummary> users = new HashMap<>();

        void add(UUID id, String name) {
            users.put(id, new UserSummary(id, name, "IT Support", true));
        }

        @Override
        public Optional<UserSummary> find(UUID userId) {
            return Optional.ofNullable(users.get(userId));
        }

        @Override
        public boolean isActiveSupportAgent(UUID userId) {
            return true;
        }
    }
}
