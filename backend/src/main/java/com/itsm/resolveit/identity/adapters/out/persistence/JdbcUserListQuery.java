package com.itsm.resolveit.identity.adapters.out.persistence;

import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.Criteria;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.InvitationState;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.SortField;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.UserPage;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.UserRow;
import com.itsm.resolveit.identity.application.port.out.UserListReadModel;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.simple.JdbcClient;

/**
 * {@link UserListReadModel} on {@code identity.app_user} with each user's latest invitation (one query,
 * {@code LEFT JOIN LATERAL}). Only fixed column names reach the SQL text; every value is a parameter.
 */
public class JdbcUserListQuery implements UserListReadModel {

    private static final String SELECT = """
            SELECT u.id, u.display_name, u.email, u.role, u.department, u.active,
                   u.password_hash IS NOT NULL AS has_password, i.status AS invitation_status,
                   i.expires_at AS invitation_expires_at
            FROM identity.app_user u
            LEFT JOIN LATERAL (
                SELECT status, expires_at FROM identity.invitation
                WHERE user_id = u.id ORDER BY created_at DESC LIMIT 1
            ) i ON true
            """;

    private static final Map<SortField, String> SORT_COLUMNS = Map.of(
            SortField.NAME, "lower(u.display_name)",
            SortField.EMAIL, "u.email",
            SortField.ROLE, "u.role",
            SortField.DEPARTMENT, "lower(u.department)");

    private final JdbcClient jdbc;

    public JdbcUserListQuery(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public UserPage find(Criteria criteria, Instant now) {
        StringBuilder where = new StringBuilder(" WHERE true");
        Map<String, Object> params = new HashMap<>();
        criteria.role().ifPresent(role -> {
            where.append(" AND u.role = :role");
            params.put("role", role.name());
        });
        criteria.active().ifPresent(active -> {
            where.append(" AND u.active = :active");
            params.put("active", active);
        });
        criteria.search().map(String::strip).filter(s -> !s.isEmpty()).ifPresent(search -> {
            where.append(" AND (lower(u.display_name) LIKE :q ESCAPE '\\' OR u.email LIKE :q ESCAPE '\\')");
            params.put("q", "%" + escapeLike(search.toLowerCase(Locale.ROOT)) + "%");
        });
        long total = jdbc.sql("SELECT count(*) FROM identity.app_user u" + where)
                .params(params).query(Long.class).single();
        String order = " ORDER BY " + SORT_COLUMNS.get(criteria.sortField()) + (criteria.ascending() ? " ASC" : " DESC")
                + ", u.id LIMIT :size OFFSET :offset";
        params.put("size", criteria.size());
        params.put("offset", (long) criteria.page() * criteria.size());
        List<UserRow> rows = jdbc.sql(SELECT + where + order).params(params).query(rowMapper(now)).list();
        int totalPages = (int) ((total + criteria.size() - 1) / criteria.size());
        return new UserPage(rows, criteria.page(), criteria.size(), total, totalPages);
    }

    @Override
    public Optional<UserRow> findRow(UserId id, Instant now) {
        return jdbc.sql(SELECT + " WHERE u.id = :id").param("id", id.value()).query(rowMapper(now)).optional();
    }

    private static RowMapper<UserRow> rowMapper(Instant now) {
        return (ResultSet row, int rowNumber) -> new UserRow(
                row.getObject("id", UUID.class),
                row.getString("display_name"),
                row.getString("email"),
                Role.valueOf(row.getString("role")),
                row.getString("department"),
                row.getBoolean("active"),
                invitationState(row, now));
    }

    /** Plan question 1: the shown status, derived from the latest invitation. */
    private static Optional<InvitationState> invitationState(ResultSet row, Instant now) throws SQLException {
        String stored = row.getString("invitation_status");
        if (stored == null) {
            // No invitation (the dev seed users): a user with a password has accepted.
            return row.getBoolean("has_password") ? Optional.of(InvitationState.ACCEPTED) : Optional.empty();
        }
        if (stored.equals("USED")) {
            return Optional.of(InvitationState.ACCEPTED);
        }
        Instant expiresAt = row.getObject("invitation_expires_at", OffsetDateTime.class).toInstant();
        if (!now.isBefore(expiresAt)) {
            return Optional.of(InvitationState.EXPIRED);
        }
        return Optional.of(stored.equals("SEND_FAILED") ? InvitationState.SEND_FAILED : InvitationState.PENDING);
    }

    private static String escapeLike(String value) {
        return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }
}
