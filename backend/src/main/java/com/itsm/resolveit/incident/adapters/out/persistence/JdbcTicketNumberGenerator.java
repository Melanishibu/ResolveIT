package com.itsm.resolveit.incident.adapters.out.persistence;

import com.itsm.resolveit.incident.application.port.out.TicketNumberGenerator;
import com.itsm.resolveit.incident.domain.model.TicketNumber;
import java.time.Year;
import org.springframework.jdbc.core.simple.JdbcClient;

/**
 * {@link TicketNumberGenerator} on table {@code incident.ticket_counter}: one atomic upsert per number.
 * Concurrent callers queue on the year's row lock until the taking transaction commits, so numbers
 * stay unique (BR-002); a new year starts its own row at 1.
 */
public class JdbcTicketNumberGenerator implements TicketNumberGenerator {

    private final JdbcClient jdbc;

    public JdbcTicketNumberGenerator(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public TicketNumber next(Year year) {
        Integer number = jdbc.sql("""
                INSERT INTO incident.ticket_counter (year, last_number) VALUES (:year, 1)
                ON CONFLICT (year) DO UPDATE SET last_number = incident.ticket_counter.last_number + 1
                RETURNING last_number
                """)
                .param("year", year.getValue())
                .query(Integer.class)
                .single();
        return TicketNumber.of(year, number);
    }
}
