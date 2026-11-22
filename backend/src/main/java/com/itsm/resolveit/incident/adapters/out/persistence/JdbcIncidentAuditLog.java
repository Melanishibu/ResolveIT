package com.itsm.resolveit.incident.adapters.out.persistence;

import com.itsm.resolveit.incident.application.port.out.IncidentAuditLog;
import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry;
import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry.IncidentAuditAction;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;

/** {@link IncidentAuditLog} on {@code incident.incident_audit_log}: INSERT only; the database refuses changes. */
public class JdbcIncidentAuditLog implements IncidentAuditLog {

    private final JdbcClient jdbc;

    public JdbcIncidentAuditLog(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void append(IncidentAuditEntry entry) {
        jdbc.sql("""
                INSERT INTO incident.incident_audit_log
                    (id, incident_id, actor_id, action, old_value, new_value, occurred_at)
                VALUES (:id, :incidentId, :actorId, :action, :oldValue, :newValue, :occurredAt)
                """)
                .param("id", UUID.randomUUID())
                .param("incidentId", entry.incidentId().value())
                .param("actorId", entry.actorId())
                .param("action", entry.action().name())
                .param("oldValue", entry.oldValue())
                .param("newValue", entry.newValue())
                .param("occurredAt", entry.occurredAt().atOffset(ZoneOffset.UTC))
                .update();
    }

    @Override
    public List<IncidentAuditEntry> findByIncidentId(IncidentId incidentId) {
        return jdbc.sql("""
                SELECT incident_id, actor_id, action, old_value, new_value, occurred_at
                FROM incident.incident_audit_log
                WHERE incident_id = :incidentId
                ORDER BY occurred_at DESC, id DESC
                """)
                .param("incidentId", incidentId.value())
                .query((row, n) -> new IncidentAuditEntry(
                        new IncidentId(row.getObject("incident_id", UUID.class)),
                        row.getObject("actor_id", UUID.class),
                        IncidentAuditAction.valueOf(row.getString("action")),
                        row.getString("old_value"),
                        row.getString("new_value"),
                        row.getObject("occurred_at", OffsetDateTime.class).toInstant()))
                .list();
    }
}
