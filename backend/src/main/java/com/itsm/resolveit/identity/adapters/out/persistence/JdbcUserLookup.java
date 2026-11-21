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
    public Optional<UserCard> findById(UUID userId) {
        return jdbc.sql("SELECT id, display_name, department, active FROM identity.app_user WHERE id = :id")
                .param("id", userId)
                .query((row, rowNumber) -> new UserCard(row.getObject("id", UUID.class), row.getString("display_name"),
                        row.getString("department"), row.getBoolean("active")))
                .optional();
    }
}
