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

    Rows page(Scope scope, int page, int size, SortField sort, boolean ascending);

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
