package com.itsm.resolveit.identity.adapters.out.persistence;

import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.domain.model.Invitation;
import com.itsm.resolveit.identity.domain.model.InvitationId;
import com.itsm.resolveit.identity.domain.model.InvitationStatus;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;

/** {@link InvitationRepository} on PostgreSQL table {@code identity.invitation} (token hash only). */
public class JdbcInvitationRepository implements InvitationRepository {

    private static final String COLUMNS = "id, user_id, token_hash, created_at, expires_at, status";

    private final JdbcClient jdbc;

    public JdbcInvitationRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public InvitationId nextId() {
        return new InvitationId(UUID.randomUUID());
    }

    @Override
    public void save(Invitation invitation) {
        jdbc.sql("""
                INSERT INTO identity.invitation (id, user_id, token_hash, created_at, expires_at, status)
                VALUES (:id, :userId, :tokenHash, :createdAt, :expiresAt, :status)
                ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status
                """)
                .param("id", invitation.id().value())
                .param("userId", invitation.userId().value())
                .param("tokenHash", invitation.tokenHash())
                .param("createdAt", invitation.createdAt().atOffset(ZoneOffset.UTC))
                .param("expiresAt", invitation.expiresAt().atOffset(ZoneOffset.UTC))
                .param("status", invitation.status().name())
                .update();
    }

    @Override
    public Optional<Invitation> findById(InvitationId id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM identity.invitation WHERE id = :id")
                .param("id", id.value())
                .query(JdbcInvitationRepository::toInvitation)
                .optional();
    }

    @Override
    public Optional<Invitation> findByTokenHash(String tokenHash) {
        // FOR UPDATE: two submits of the same link wait for each other, so the link is used once (RIT-US-07).
        return jdbc.sql("SELECT " + COLUMNS + " FROM identity.invitation WHERE token_hash = :tokenHash FOR UPDATE")
                .param("tokenHash", tokenHash)
                .query(JdbcInvitationRepository::toInvitation)
                .optional();
    }

    @Override
    public void invalidatePending(UserId userId, Instant now) {
        jdbc.sql("""
                UPDATE identity.invitation
                SET status = 'USED', expires_at = :now
                WHERE user_id = :userId AND status IN ('PENDING', 'SENT', 'SEND_FAILED')
                """)
                .param("userId", userId.value())
                .param("now", now.atOffset(ZoneOffset.UTC))
                .update();
    }

    static Invitation toInvitation(ResultSet row, int rowNumber) throws SQLException {
        return Invitation.reconstitute(
                new InvitationId(row.getObject("id", UUID.class)),
                new UserId(row.getObject("user_id", UUID.class)),
                row.getString("token_hash"),
                row.getObject("created_at", OffsetDateTime.class).toInstant(),
                row.getObject("expires_at", OffsetDateTime.class).toInstant(),
                InvitationStatus.valueOf(row.getString("status")));
    }
}
