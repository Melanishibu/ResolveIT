package com.itsm.resolveit.identity.adapters.out.persistence;

import com.itsm.resolveit.identity.UserLookup;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;

/** {@link UserLookup} (published API) on PostgreSQL table {@code identity.app_user}. */
public class JdbcUserLookup implements UserLookup {

    private final JdbcClient jdbc;

    public JdbcUserLookup(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public boolean isActiveSupportAgent(UUID userId) {
        return jdbc.sql("SELECT count(*) FROM identity.app_user WHERE id = :id AND role = 'SUPPORT_AGENT' AND active")
                .param("id", userId)
                .query(Long.class).single() > 0;
    }

    @Override
    public java.util.List<AgentCard> activeSupportAgents() {
        return jdbc.sql("SELECT id, display_name, email FROM identity.app_user"
                        + " WHERE role = 'SUPPORT_AGENT' AND active ORDER BY display_name, id")
                .query((row, n) -> new AgentCard(row.getObject("id", UUID.class), row.getString("display_name"),
                        row.getString("email")))
                .list();
    }

    @Override
    public Optional<UserCard> findById(UUID userId) {
        return jdbc.sql("SELECT id, display_name, department, active FROM identity.app_user WHERE id = :id")
                .param("id", userId)
                .query((row, rowNumber) -> new UserCard(row.getObject("id", UUID.class), row.getString("display_name"),
                        row.getString("department"), row.getBoolean("active")))
                .optional();
    }
}
