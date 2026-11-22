package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.domain.model.Category;
import com.itsm.resolveit.incident.domain.model.IncidentStatus;
import com.itsm.resolveit.incident.domain.model.Priority;
import java.time.Instant;
import java.util.Objects;
import java.util.Set;

/**
 * One page of the incidents {@code actor} may see (RIT-US-11), optionally searched and filtered (RIT-US-12, RIT-US-21).
 * Bounds are checked by the web adapter.
 */
public record ListIncidentsQuery(
        Actor actor,
        int page,
        int size,
        SortField sort,
        boolean ascending,
        String q,
        Set<IncidentStatus> statuses,
        Set<Priority> priorities,
        Set<Category> categories,
        Instant createdFrom,
        Instant createdTo) {

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
        statuses = Set.copyOf(statuses);
        priorities = Set.copyOf(priorities);
        categories = Set.copyOf(categories);
    }

    public ListIncidentsQuery(Actor actor, int page, int size, SortField sort, boolean ascending,
                              Set<IncidentStatus> statuses, Set<Priority> priorities) {
        this(actor, page, size, sort, ascending, null, statuses, priorities, Set.of(), null, null);
    }

    /** No status or priority filter. */
    public ListIncidentsQuery(Actor actor, int page, int size, SortField sort, boolean ascending) {
        this(actor, page, size, sort, ascending, null, Set.of(), Set.of(), Set.of(), null, null);
    }
}
