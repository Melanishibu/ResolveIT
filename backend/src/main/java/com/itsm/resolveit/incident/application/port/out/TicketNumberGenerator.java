package com.itsm.resolveit.incident.application.port.out;

import com.itsm.resolveit.incident.domain.model.TicketNumber;
import java.time.Year;

/**
 * Hands out ticket numbers per year, unique under concurrent requests (BR-002). Must be called inside
 * the transaction that saves the incident, so a rolled-back creation doesn't leave a number in use.
 */
public interface TicketNumberGenerator {

    /** The next number for {@code year}: INC-YYYY-00001 for the year's first incident. */
    TicketNumber next(Year year);
}
