package com.itsm.resolveit.incident.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry.IncidentAuditAction;
import java.time.Instant;
import java.time.Year;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** RIT-US-09 domain rules: value objects, ticket number format, new incidents start OPEN with a CREATED entry. */
class IncidentTest {

    private static final UUID EMPLOYEE = UUID.fromString("00000000-0000-4000-8000-000000000004");
    private static final Instant NOW = Instant.parse("2026-11-20T15:30:00Z");

    @Test
    void aReportedIncidentIsOpenAndCreatedByTheReporter() {
        Incident incident = Incident.report(new IncidentId(UUID.randomUUID()), TicketNumber.of(Year.of(2026), 1),
                new Title("Laptop won't start"), new Description("Black screen"), Category.HARDWARE, Priority.HIGH,
                EMPLOYEE, NOW);

        assertThat(incident.status()).isEqualTo(IncidentStatus.OPEN);
        assertThat(incident.createdBy()).isEqualTo(EMPLOYEE);
        assertThat(incident.ticketNumber().value()).isEqualTo("INC-2026-00001");

        IncidentAuditEntry created = incident.creationEntry();
        assertThat(created.action()).isEqualTo(IncidentAuditAction.CREATED);
        assertThat(created.actorId()).isEqualTo(EMPLOYEE);
        assertThat(created.oldValue()).isNull();
        assertThat(created.newValue()).isEqualTo("INC-2026-00001, priority HIGH, category HARDWARE");
        assertThat(created.occurredAt()).isEqualTo(NOW);
    }

    @Test
    void ticketNumbersFollowTheFormatIncYearCounter() {
        assertThat(TicketNumber.of(Year.of(2027), 1).value()).isEqualTo("INC-2027-00001");
        assertThat(TicketNumber.of(Year.of(2026), 418).value()).isEqualTo("INC-2026-00418");
        assertThat(TicketNumber.of(Year.of(2026), 99_999).value()).isEqualTo("INC-2026-99999");
        assertThatThrownBy(() -> TicketNumber.of(Year.of(2026), 0)).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> TicketNumber.of(Year.of(2026), 100_000)).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new TicketNumber("INC-000001")).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void titleIsTrimmedRequiredAndAtMost120Characters() {
        assertThat(new Title("  Printer jam  ").value()).isEqualTo("Printer jam");
        assertThat(new Title("x".repeat(120)).value()).hasSize(120);
        assertThatThrownBy(() -> new Title("")).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new Title("   ")).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new Title(null)).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new Title("x".repeat(121))).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new Title("bad\u0007bell")).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void descriptionIsRequiredAtMost2000CharactersAndKeepsLineBreaks() {
        assertThat(new Description("line 1\nline 2").value()).isEqualTo("line 1\nline 2");
        assertThat(new Description("x".repeat(2000)).value()).hasSize(2000);
        assertThatThrownBy(() -> new Description(" ")).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new Description("x".repeat(2001))).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new Description("bad\u0000nul")).isInstanceOf(IllegalArgumentException.class);
    }
}
