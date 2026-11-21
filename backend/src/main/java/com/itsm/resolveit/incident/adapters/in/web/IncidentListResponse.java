package com.itsm.resolveit.incident.adapters.in.web;

import com.itsm.resolveit.incident.application.port.in.IncidentListPage;
import java.util.List;

/** One page of incidents: {@code {items, page, size, totalItems, totalPages}} (API conventions, RIT-US-11). */
record IncidentListResponse(List<Item> items, int page, int size, long totalItems, int totalPages) {

    record Assignee(String id, String name, boolean active) {
    }

    record Item(String id, String ticketNumber, String title, String category, String priority, String status,
                Assignee assignee, String createdAt, String updatedAt) {
    }

    static IncidentListResponse of(IncidentListPage page) {
        List<Item> items = page.items().stream()
                .map(item -> new Item(item.id().toString(), item.ticketNumber(), item.title(), item.category().name(),
                        item.priority().name(), item.status().name(),
                        item.assignee().map(user -> new Assignee(user.id().toString(), user.name(), user.active()))
                                .orElse(null),
                        item.createdAt().toString(), item.updatedAt().toString()))
                .toList();
        return new IncidentListResponse(items, page.page(), page.size(), page.totalItems(), page.totalPages());
    }
}
