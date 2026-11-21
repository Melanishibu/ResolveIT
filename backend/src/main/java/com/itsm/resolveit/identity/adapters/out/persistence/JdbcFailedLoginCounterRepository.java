package com.itsm.resolveit.identity.adapters.out.persistence;

import com.itsm.resolveit.identity.application.port.out.FailedLoginCounterRepository;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.FailedLoginCounter;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import org.springframework.jdbc.core.simple.JdbcClient;

/** {@link FailedLoginCounterRepository} on PostgreSQL table {@code identity.unknown_email_login_attempt}. */
public class JdbcFailedLoginCounterRepository implements FailedLoginCounterRepository {

    private final JdbcClient jdbc;

    public JdbcFailedLoginCounterRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public FailedLoginCounter lockOrStart(EmailAddress email) {
        // Create the row if it is missing, so that SELECT ... FOR UPDATE always has a row to lock, also when
        // two first attempts for the same email arrive at the same time.
        jdbc.sql("""
                INSERT INTO identity.unknown_email_login_attempt (email, failed_login_attempts, locked_until)
                VALUES (:email, 0, NULL)
                ON CONFLICT (email) DO NOTHING
                """)
                .param("email", email.value())
                .update();
        return jdbc.sql("""
                SELECT failed_login_attempts, locked_until
                FROM identity.unknown_email_login_attempt
                WHERE email = :email
                FOR UPDATE
                """)
                .param("email", email.value())
                .query((row, rowNumber) -> {
                    OffsetDateTime lockedUntil = row.getObject("locked_until", OffsetDateTime.class);
                    return FailedLoginCounter.reconstitute(email, row.getInt("failed_login_attempts"),
                            lockedUntil == null ? null : lockedUntil.toInstant());
                })
                .single();
    }

    @Override
    public void save(FailedLoginCounter counter) {
        jdbc.sql("""
                UPDATE identity.unknown_email_login_attempt
                SET failed_login_attempts = :failedAttempts, locked_until = :lockedUntil, updated_at = now()
                WHERE email = :email
                """)
                .param("email", counter.email().value())
                .param("failedAttempts", counter.failedAttempts())
                .param("lockedUntil", toOffsetDateTime(counter.lockedUntil()))
                .update();
    }

    private static OffsetDateTime toOffsetDateTime(Instant instant) {
        return instant == null ? null : instant.atOffset(ZoneOffset.UTC);
    }
}
