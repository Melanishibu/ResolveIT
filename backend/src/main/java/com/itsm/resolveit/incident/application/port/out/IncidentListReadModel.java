package com.itsm.resolveit.incident.application.port.out;

import com.itsm.resolveit.incident.application.port.in.ListIncidentsQuery.SortField;
import com.itsm.resolveit.incident.domain.model.Category;
import com.itsm.resolveit.incident.domain.model.IncidentStatus;
import com.itsm.resolveit.incident.domain.model.Priority;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Read model for the incident list (CQRS-lite, RIT-US-11): paged rows within a visibility scope. */
public interface IncidentListReadModel {

    Rows page(Scope scope, Filter filter, int page, int size, SortField sort, boolean ascending);

    /** Optional narrowing inside the scope (RIT-US-12 search/filters, RIT-US-21 dashboard cards). */
    record Filter(
            String q,
            java.util.Set<IncidentStatus> statuses,
            java.util.Set<Priority> priorities,
            java.util.Set<Category> categories,
            Instant createdFrom,
            Instant createdTo) {

        public Filter {
            statuses = java.util.Set.copyOf(statuses);
            priorities = java.util.Set.copyOf(priorities);
            categories = java.util.Set.copyOf(categories);
        }

        public Filter(java.util.Set<IncidentStatus> statuses, java.util.Set<Priority> priorities) {
            this(null, statuses, priorities, java.util.Set.of(), null, null);
        }

        public static Filter none() {
            return new Filter(null, java.util.Set.of(), java.util.Set.of(), java.util.Set.of(), null, null);
        }
    }

    /** Which incidents: all, those created by a user, or those assigned to a user. */
    record Scope(UUID createdBy, UUID assignedTo) {

        public static Scope all() {
            return new Scope(null, null);
        }

        public static Scope createdBy(UUID userId) {
            return new Scope(userId, null);
        }

        public static Scope assignedTo(UUID userId) {
            return new Scope(null, userId);
        }
    }

    record Rows(List<Row> rows, long totalItems) {
    }

    record Row(UUID id, String ticketNumber, String title, Category category, Priority priority,
               IncidentStatus status, UUID assignedTo, Instant createdAt, Instant updatedAt) {
    }
}
