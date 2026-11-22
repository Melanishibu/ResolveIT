package com.itsm.resolveit.identity.adapters.out.persistence;

import com.itsm.resolveit.identity.application.port.out.UserSessionRepository;
import com.itsm.resolveit.identity.domain.model.SessionId;
import com.itsm.resolveit.identity.domain.model.UserId;
import com.itsm.resolveit.identity.domain.model.UserSession;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;

/** {@link UserSessionRepository} on PostgreSQL table {@code identity.user_session}. */
public class JdbcUserSessionRepository implements UserSessionRepository {

    private final JdbcClient jdbc;

    public JdbcUserSessionRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public SessionId nextId() {
        return new SessionId(UUID.randomUUID());
    }

    @Override
    public void save(UserSession session) {
        jdbc.sql("""
                INSERT INTO identity.user_session (id, user_id, created_at, expires_at)
                VALUES (:id, :userId, :createdAt, :expiresAt)
                ON CONFLICT (id) DO UPDATE SET expires_at = EXCLUDED.expires_at
                """)
                .param("id", session.id().value())
                .param("userId", session.userId().value())
                .param("createdAt", session.createdAt().atOffset(ZoneOffset.UTC))
                .param("expiresAt", session.expiresAt().atOffset(ZoneOffset.UTC))
                .update();
    }

    @Override
    public Optional<UserSession> findById(SessionId id) {
        return jdbc.sql("SELECT id, user_id, created_at, expires_at FROM identity.user_session WHERE id = :id")
                .param("id", id.value())
                .query(JdbcUserSessionRepository::toSession)
                .optional();
    }

    @Override
    public void delete(SessionId id) {
        jdbc.sql("DELETE FROM identity.user_session WHERE id = :id").param("id", id.value()).update();
    }

    @Override
    public void deleteAllExcept(UserId userId, SessionId currentSessionId) {
        jdbc.sql("DELETE FROM identity.user_session WHERE user_id = :userId AND id <> :sessionId")
                .param("userId", userId.value())
                .param("sessionId", currentSessionId.value())
                .update();
    }

    private static UserSession toSession(ResultSet row, int rowNumber) throws SQLException {
        return UserSession.reconstitute(
                new SessionId(row.getObject("id", UUID.class)),
                new UserId(row.getObject("user_id", UUID.class)),
                row.getObject("created_at", OffsetDateTime.class).toInstant(),
                row.getObject("expires_at", OffsetDateTime.class).toInstant());
    }
}
