package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.incident.application.port.out.UserDirectory.UserSummary;
import com.itsm.resolveit.incident.domain.model.Category;
import com.itsm.resolveit.incident.domain.model.IncidentStatus;
import com.itsm.resolveit.incident.domain.model.Priority;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** One page of incidents (RIT-US-11). */
public record IncidentListPage(List<Item> items, int page, int size, long totalItems) {

    public IncidentListPage {
        items = List.copyOf(items);
    }

    public int totalPages() {
        return (int) ((totalItems + size - 1) / size);
    }

    /** One row; the assignee is empty when unassigned (or the user no longer exists). */
    public record Item(UUID id, String ticketNumber, String title, Category category, Priority priority,
                       IncidentStatus status, Optional<UserSummary> assignee, Instant createdAt, Instant updatedAt) {
    }
}
