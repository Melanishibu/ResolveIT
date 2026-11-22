package com.itsm.resolveit.incident.adapters.out.persistence;

import com.itsm.resolveit.incident.application.port.in.ListIncidentsQuery.SortField;
import com.itsm.resolveit.incident.application.port.out.IncidentListReadModel;
import com.itsm.resolveit.incident.domain.model.Category;
import com.itsm.resolveit.incident.domain.model.IncidentStatus;
import com.itsm.resolveit.incident.domain.model.Priority;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;

/** {@link IncidentListReadModel} on table {@code incident.incident}; sort columns come from a fixed map only. */
public class JdbcIncidentListQuery implements IncidentListReadModel {

    private static final Map<SortField, String> ORDER = Map.of(
            SortField.CREATED_AT, "created_at",
            SortField.UPDATED_AT, "updated_at",
            SortField.TICKET_NUMBER, "ticket_number",
            SortField.PRIORITY,
            "CASE priority WHEN 'LOW' THEN 1 WHEN 'MEDIUM' THEN 2 WHEN 'HIGH' THEN 3 ELSE 4 END",
            SortField.STATUS, "CASE status WHEN 'OPEN' THEN 1 WHEN 'ASSIGNED' THEN 2 WHEN 'IN_PROGRESS' THEN 3"
                    + " WHEN 'RESOLVED' THEN 4 ELSE 5 END");

    private final JdbcClient jdbc;

    public JdbcIncidentListQuery(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Rows page(Scope scope, Filter filter, int page, int size, SortField sort, boolean ascending) {
        StringBuilder where = new StringBuilder(" WHERE (CAST(:createdBy AS uuid) IS NULL OR created_by = :createdBy)"
                + " AND (CAST(:assignedTo AS uuid) IS NULL OR assigned_to = :assignedTo)");

        List<String> statuses = filter.statuses().stream().map(Enum::name).toList();
        List<String> priorities = filter.priorities().stream().map(Enum::name).toList();
        List<String> categories = filter.categories().stream().map(Enum::name).toList();
        boolean hasQ = filter.q() != null && !filter.q().isBlank();
        boolean hasFrom = filter.createdFrom() != null;
        boolean hasTo = filter.createdTo() != null;

        if (!statuses.isEmpty()) {
            where.append(" AND status IN (:statuses)");
        }
        if (!priorities.isEmpty()) {
            where.append(" AND priority IN (:priorities)");
        }
        if (!categories.isEmpty()) {
            where.append(" AND category IN (:categories)");
        }
        if (hasQ) {
            where.append(" AND (LOWER(ticket_number) = :qExact OR LOWER(title) LIKE :titlePattern)");
        }
        if (hasFrom) {
            where.append(" AND created_at >= :createdFrom");
        }
        if (hasTo) {
            where.append(" AND created_at <= :createdTo");
        }

        var countSpec = jdbc.sql("SELECT count(*) FROM incident.incident" + where)
                .param("createdBy", scope.createdBy())
                .param("assignedTo", scope.assignedTo());
        if (!statuses.isEmpty()) countSpec.param("statuses", statuses);
        if (!priorities.isEmpty()) countSpec.param("priorities", priorities);
        if (!categories.isEmpty()) countSpec.param("categories", categories);
        if (hasQ) {
            String qTrim = filter.q().trim().toLowerCase();
            countSpec.param("qExact", qTrim).param("titlePattern", "%" + qTrim + "%");
        }
        if (hasFrom) countSpec.param("createdFrom", OffsetDateTime.ofInstant(filter.createdFrom(), ZoneOffset.UTC));
        if (hasTo) countSpec.param("createdTo", OffsetDateTime.ofInstant(filter.createdTo(), ZoneOffset.UTC));

        long total = countSpec.query(Long.class).single();

        String direction = ascending ? " ASC" : " DESC";
        var rowsSpec = jdbc.sql("SELECT id, ticket_number, title, category, priority, status, assigned_to, created_at,"
                        + " updated_at FROM incident.incident" + where
                        + " ORDER BY " + ORDER.get(sort) + direction + ", created_at DESC, id"
                        + " LIMIT :limit OFFSET :offset")
                .param("createdBy", scope.createdBy())
                .param("assignedTo", scope.assignedTo());
        if (!statuses.isEmpty()) rowsSpec.param("statuses", statuses);
        if (!priorities.isEmpty()) rowsSpec.param("priorities", priorities);
        if (!categories.isEmpty()) rowsSpec.param("categories", categories);
        if (hasQ) {
            String qTrim = filter.q().trim().toLowerCase();
            rowsSpec.param("qExact", qTrim).param("titlePattern", "%" + qTrim + "%");
        }
        if (hasFrom) rowsSpec.param("createdFrom", OffsetDateTime.ofInstant(filter.createdFrom(), ZoneOffset.UTC));
        if (hasTo) rowsSpec.param("createdTo", OffsetDateTime.ofInstant(filter.createdTo(), ZoneOffset.UTC));
        rowsSpec.param("limit", size).param("offset", (long) page * size);

        var rows = rowsSpec.query((row, n) -> new Row(row.getObject("id", UUID.class), row.getString("ticket_number"),
                        row.getString("title"), Category.valueOf(row.getString("category")),
                        Priority.valueOf(row.getString("priority")), IncidentStatus.valueOf(row.getString("status")),
                        row.getObject("assigned_to", UUID.class),
                        row.getObject("created_at", OffsetDateTime.class).toInstant(),
                        row.getObject("updated_at", OffsetDateTime.class).toInstant()))
                .list();
        return new Rows(rows, total);
    }
}
