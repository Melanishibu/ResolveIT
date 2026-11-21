package com.itsm.resolveit.incident.adapters.out.persistence;

import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.domain.model.Category;
import com.itsm.resolveit.incident.domain.model.Description;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import com.itsm.resolveit.incident.domain.model.IncidentStatus;
import com.itsm.resolveit.incident.domain.model.Priority;
import com.itsm.resolveit.incident.domain.model.ResolutionNotes;
import com.itsm.resolveit.incident.domain.model.TicketNumber;
import com.itsm.resolveit.incident.domain.model.Title;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;

/** {@link IncidentRepository} on PostgreSQL table {@code incident.incident}. */
public class JdbcIncidentRepository implements IncidentRepository {

    private static final String COLUMNS =
            "id, ticket_number, title, description, category, priority, status, created_by, created_at, updated_at, assigned_to,"
            + " resolution_notes";

    private final JdbcClient jdbc;

    public JdbcIncidentRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public IncidentId nextId() {
        return new IncidentId(UUID.randomUUID());
    }

    @Override
    public void save(Incident incident) {
        jdbc.sql("""
                INSERT INTO incident.incident
                    (id, ticket_number, title, description, category, priority, status, created_by, created_at, updated_at,
                     assigned_to, resolution_notes)
                VALUES (:id, :ticketNumber, :title, :description, :category, :priority, :status, :createdBy, :createdAt, :updatedAt,
                        :assignedTo, :resolutionNotes)
                ON CONFLICT (id) DO UPDATE SET
                    title = EXCLUDED.title,
                    description = EXCLUDED.description,
                    category = EXCLUDED.category,
                    priority = EXCLUDED.priority,
                    status = EXCLUDED.status,
                    updated_at = EXCLUDED.updated_at,
                    assigned_to = EXCLUDED.assigned_to,
                    resolution_notes = EXCLUDED.resolution_notes
                """)
                .param("id", incident.id().value())
                .param("ticketNumber", incident.ticketNumber().value())
                .param("title", incident.title().value())
                .param("description", incident.description().value())
                .param("category", incident.category().name())
                .param("priority", incident.priority().name())
                .param("status", incident.status().name())
                .param("createdBy", incident.createdBy())
                .param("createdAt", incident.createdAt().atOffset(ZoneOffset.UTC))
                .param("updatedAt", incident.updatedAt().atOffset(ZoneOffset.UTC))
                .param("assignedTo", incident.assignedTo().orElse(null))
                .param("resolutionNotes", incident.resolutionNotes().map(ResolutionNotes::value).orElse(null))
                .update();
    }

    @Override
    public Optional<Incident> findById(IncidentId id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM incident.incident WHERE id = :id")
                .param("id", id.value())
                .query(JdbcIncidentRepository::toIncident)
                .optional();
    }

    private static Incident toIncident(ResultSet row, int rowNumber) throws SQLException {
        return Incident.reconstitute(
                new IncidentId(row.getObject("id", UUID.class)),
                new TicketNumber(row.getString("ticket_number")),
                new Title(row.getString("title")),
                new Description(row.getString("description")),
                Category.valueOf(row.getString("category")),
                Priority.valueOf(row.getString("priority")),
                IncidentStatus.valueOf(row.getString("status")),
                row.getObject("created_by", UUID.class),
                row.getObject("created_at", OffsetDateTime.class).toInstant(),
                row.getObject("updated_at", OffsetDateTime.class).toInstant(),
                row.getObject("assigned_to", UUID.class),
                row.getString("resolution_notes") == null ? null
                        : new ResolutionNotes(row.getString("resolution_notes")));
    }
}
