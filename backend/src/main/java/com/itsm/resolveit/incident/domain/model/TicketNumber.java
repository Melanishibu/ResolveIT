package com.itsm.resolveit.incident.domain.model;

import java.time.Year;
import java.util.Objects;
import java.util.regex.Pattern;

/**
 * The human-readable incident number {@code INC-YYYY-NNNNN} (Update 01, M1): the UTC year of creation
 * and a 5-digit counter per year that starts at 00001 every 1 January.
 */
public record TicketNumber(String value) {

    public static final int MAX_COUNTER = 99_999;
    private static final Pattern FORMAT = Pattern.compile("INC-\\d{4}-\\d{5}");

    public TicketNumber {
        Objects.requireNonNull(value, "value");
        if (!FORMAT.matcher(value).matches()) {
            throw new IllegalArgumentException("Ticket number must look like INC-YYYY-NNNNN: " + value);
        }
    }

    /** The {@code counter}-th incident of {@code year}. */
    public static TicketNumber of(Year year, int counter) {
        if (counter < 1 || counter > MAX_COUNTER) {
            throw new IllegalArgumentException("Ticket counter must be 1–" + MAX_COUNTER + ": " + counter);
        }
        return new TicketNumber("INC-%04d-%05d".formatted(year.getValue(), counter));
    }

    @Override
    public String toString() {
        return value;
    }
}
