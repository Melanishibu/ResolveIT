package com.itsm.resolveit.incident.adapters.out.persistence;

import com.itsm.resolveit.incident.application.port.out.DashboardReadModel;
import com.itsm.resolveit.incident.application.port.out.IncidentListReadModel.Scope;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;

/** {@link DashboardReadModel} on tables {@code incident.incident} and {@code incident.incident_audit_log}. */
public class JdbcDashboardQuery implements DashboardReadModel {

    private static final String SCOPE = " (CAST(:createdBy AS uuid) IS NULL OR i.created_by = :createdBy)"
            + " AND (CAST(:assignedTo AS uuid) IS NULL OR i.assigned_to = :assignedTo)";

    private final JdbcClient jdbc;

    public JdbcDashboardQuery(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Counts counts(Scope scope) {
        return jdbc.sql("""
                        SELECT count(*) AS total,
                               count(*) FILTER (WHERE status = 'OPEN') AS open,
                               count(*) FILTER (WHERE status = 'ASSIGNED') AS assigned,
                               count(*) FILTER (WHERE status = 'IN_PROGRESS') AS in_progress,
                               count(*) FILTER (WHERE status = 'RESOLVED') AS resolved,
                               count(*) FILTER (WHERE priority = 'CRITICAL' AND status <> 'CLOSED') AS critical
                        FROM incident.incident i WHERE""" + SCOPE)
                .param("createdBy", scope.createdBy()).param("assignedTo", scope.assignedTo())
                .query((row, n) -> new Counts(row.getLong("total"), row.getLong("open"), row.getLong("assigned"),
                        row.getLong("in_progress"), row.getLong("resolved"), row.getLong("critical")))
                .single();
    }

    @Override
    public List<Activity> recentActivity(Scope scope, int limit) {
        return jdbc.sql("SELECT a.incident_id, i.ticket_number, a.action, a.actor_id, a.occurred_at"
                        + " FROM incident.incident_audit_log a JOIN incident.incident i ON i.id = a.incident_id"
                        + " WHERE" + SCOPE + " ORDER BY a.occurred_at DESC, a.id LIMIT :limit")
                .param("createdBy", scope.createdBy()).param("assignedTo", scope.assignedTo())
                .param("limit", limit)
                .query((row, n) -> new Activity(row.getObject("incident_id", UUID.class),
                        row.getString("ticket_number"), row.getString("action"),
                        row.getObject("actor_id", UUID.class),
                        row.getObject("occurred_at", OffsetDateTime.class).toInstant()))
                .list();
    }
}
