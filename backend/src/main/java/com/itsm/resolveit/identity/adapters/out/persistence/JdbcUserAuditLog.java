package com.itsm.resolveit.identity.adapters.out.persistence;

import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;

/**
 * {@link UserAuditLog} on PostgreSQL table {@code identity.user_audit_log}: INSERT only. The database
 * also refuses UPDATE, DELETE and TRUNCATE for the application's role (Flyway V2).
 */
public class JdbcUserAuditLog implements UserAuditLog {

    private final JdbcClient jdbc;

    public JdbcUserAuditLog(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void append(UserAuditEntry entry) {
        jdbc.sql("""
                INSERT INTO identity.user_audit_log (id, user_id, actor_id, action, old_value, new_value, occurred_at)
                VALUES (:id, :userId, :actorId, :action, :oldValue, :newValue, :occurredAt)
                """)
                .param("id", UUID.randomUUID())
                .param("userId", entry.userId().value())
                .param("actorId", entry.actorId())
                .param("action", entry.action().name())
                .param("oldValue", entry.oldValue())
                .param("newValue", entry.newValue())
                .param("occurredAt", entry.occurredAt().atOffset(ZoneOffset.UTC))
                .update();
    }

    @Override
    public int countByUserIdAndActionSince(UserId userId, UserAuditEntry.UserAuditAction action, Instant since) {
        Integer count = jdbc.sql("""
                SELECT COUNT(*) FROM identity.user_audit_log
                WHERE user_id = :userId AND action = :action AND occurred_at >= :since
                """)
                .param("userId", userId.value())
                .param("action", action.name())
                .param("since", since.atOffset(ZoneOffset.UTC))
                .query(Integer.class)
                .single();
        return count != null ? count : 0;
    }
}
