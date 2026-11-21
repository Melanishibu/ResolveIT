package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.identity.Actor;
import java.util.Objects;

/** One page of the incidents {@code actor} may see (RIT-US-11). Bounds are checked by the web adapter. */
public record ListIncidentsQuery(Actor actor, int page, int size, SortField sort, boolean ascending) {

    /** The sortable columns. */
    public enum SortField {
        CREATED_AT, UPDATED_AT, PRIORITY, STATUS, TICKET_NUMBER
    }

    public ListIncidentsQuery {
        Objects.requireNonNull(actor, "actor");
        Objects.requireNonNull(sort, "sort");
        if (page < 0 || size < 1 || size > 100) {
            throw new IllegalArgumentException("page must be >= 0 and size 1..100");
        }
    }
}
