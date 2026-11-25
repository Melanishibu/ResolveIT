package com.itsm.resolveit.incident.domain.model;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** RIT-US-10 (AB#38): who sees an incident and which actions the permission table allows. */
class IncidentAccessTest {

    private static final UUID REPORTER = UUID.randomUUID();
    private final Viewer reporter = new Viewer(REPORTER, Viewer.Role.EMPLOYEE);
    private final Viewer otherEmployee = new Viewer(UUID.randomUUID(), Viewer.Role.EMPLOYEE);
    private final Viewer admin = new Viewer(UUID.randomUUID(), Viewer.Role.ADMIN);

    @Test
    void actionsFollowThePermissionTable() {
        assertThat(incident(IncidentStatus.RESOLVED).allowedActionsFor(reporter))
                .containsExactlyInAnyOrder(IncidentAction.REOPEN, IncidentAction.CLOSE);
        assertThat(incident(IncidentStatus.OPEN).allowedActionsFor(reporter)).isEmpty();
        assertThat(incident(IncidentStatus.OPEN).allowedActionsFor(admin))
                .containsExactlyInAnyOrder(IncidentAction.ASSIGN, IncidentAction.CHANGE_PRIORITY);
        assertThat(incident(IncidentStatus.ASSIGNED).allowedActionsFor(admin))
                .containsExactlyInAnyOrder(IncidentAction.REASSIGN, IncidentAction.CHANGE_PRIORITY);
        assertThat(incident(IncidentStatus.CLOSED).allowedActionsFor(admin)).isEmpty();
    }

    @Test
    void onlyTheReporterAndAdminsSeeAnUnassignedIncident() {
        Incident incident = incident(IncidentStatus.OPEN);
        assertThat(incident.isVisibleTo(reporter)).isTrue();
        assertThat(incident.isVisibleTo(admin)).isTrue();
        assertThat(incident.isVisibleTo(otherEmployee)).isFalse();
        assertThat(incident.isVisibleTo(new Viewer(UUID.randomUUID(), Viewer.Role.SUPPORT_AGENT))).isFalse();
    }

    private static Incident incident(IncidentStatus status) {
        return Incident.reconstitute(new IncidentId(UUID.randomUUID()), new TicketNumber("INC-2026-00001"),
                new Title("Printer jams"), new Description("Paper jam"), Category.HARDWARE, Priority.LOW, status,
                REPORTER, Instant.parse("2026-11-21T09:00:00Z"));
    }
}
