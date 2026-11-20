package com.itsm.resolveit.identity.adapters.out.persistence;

import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.PasswordHash;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;

/** {@link UserRepository} on PostgreSQL table {@code identity.app_user}. */
public class JdbcUserRepository implements UserRepository {

    private static final String COLUMNS =
            "id, email, display_name, role, password_hash, active, failed_login_attempts, locked_until";

    private final JdbcClient jdbc;

    public JdbcUserRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<User> lockByEmail(EmailAddress email) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM identity.app_user WHERE email = :email FOR UPDATE")
                .param("email", email.value())
                .query(JdbcUserRepository::toUser)
                .optional();
    }

    @Override
    public Optional<User> findById(UserId id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM identity.app_user WHERE id = :id")
                .param("id", id.value())
                .query(JdbcUserRepository::toUser)
                .optional();
    }

    @Override
    public void save(User user) {
        jdbc.sql("""
                INSERT INTO identity.app_user
                    (id, email, display_name, role, password_hash, active, failed_login_attempts, locked_until)
                VALUES (:id, :email, :displayName, :role, :passwordHash, :active, :failedLoginAttempts, :lockedUntil)
                ON CONFLICT (id) DO UPDATE SET
                    email = EXCLUDED.email,
                    display_name = EXCLUDED.display_name,
                    role = EXCLUDED.role,
                    password_hash = EXCLUDED.password_hash,
                    active = EXCLUDED.active,
                    failed_login_attempts = EXCLUDED.failed_login_attempts,
                    locked_until = EXCLUDED.locked_until
                """)
                .param("id", user.id().value())
                .param("email", user.email().value())
                .param("displayName", user.displayName().value())
                .param("role", user.role().name())
                .param("passwordHash", user.passwordHash().value())
                .param("active", user.isActive())
                .param("failedLoginAttempts", user.failedLoginAttempts())
                .param("lockedUntil", toOffsetDateTime(user.lockedUntil()))
                .update();
    }

    private static User toUser(ResultSet row, int rowNumber) throws SQLException {
        OffsetDateTime lockedUntil = row.getObject("locked_until", OffsetDateTime.class);
        return User.reconstitute(
                new UserId(row.getObject("id", UUID.class)),
                new EmailAddress(row.getString("email")),
                new DisplayName(row.getString("display_name")),
                Role.valueOf(row.getString("role")),
                new PasswordHash(row.getString("password_hash")),
                row.getBoolean("active"),
                row.getInt("failed_login_attempts"),
                lockedUntil == null ? null : lockedUntil.toInstant());
    }

    private static OffsetDateTime toOffsetDateTime(Instant instant) {
        return instant == null ? null : instant.atOffset(ZoneOffset.UTC);
    }
}
