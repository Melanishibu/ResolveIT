package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry.IncidentAuditAction;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Aggregate root: an IT incident reported by a user (RIT-US-09). Users are referenced by UUID only
 * (common rules: no cross-module references other than ids).
 */
public final class Incident {

    private final IncidentId id;
    private final TicketNumber ticketNumber;
    private final Title title;
    private final Description description;
    private final Category category;
    private final Priority priority;
    private final IncidentStatus status;
    private final UUID createdBy;
    private final Instant createdAt;

    private Incident(IncidentId id, TicketNumber ticketNumber, Title title, Description description, Category category,
                     Priority priority, IncidentStatus status, UUID createdBy, Instant createdAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.ticketNumber = Objects.requireNonNull(ticketNumber, "ticketNumber");
        this.title = Objects.requireNonNull(title, "title");
        this.description = Objects.requireNonNull(description, "description");
        this.category = Objects.requireNonNull(category, "category");
        this.priority = Objects.requireNonNull(priority, "priority");
        this.status = Objects.requireNonNull(status, "status");
        this.createdBy = Objects.requireNonNull(createdBy, "createdBy");
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
    }

    /** A user reports a new incident: it starts OPEN, created by {@code reporter}. */
    public static Incident report(IncidentId id, TicketNumber ticketNumber, Title title, Description description,
                                  Category category, Priority priority, UUID reporter, Instant now) {
        return new Incident(id, ticketNumber, title, description, category, priority, IncidentStatus.OPEN, reporter,
                now);
    }

    public static Incident reconstitute(IncidentId id, TicketNumber ticketNumber, Title title, Description description,
                                        Category category, Priority priority, IncidentStatus status, UUID createdBy,
                                        Instant createdAt) {
        return new Incident(id, ticketNumber, title, description, category, priority, status, createdBy, createdAt);
    }

    /** The CREATED audit entry: new value = ticket number, priority and category (RIT-US-09 spec). */
    public IncidentAuditEntry creationEntry() {
        return new IncidentAuditEntry(id, createdBy, IncidentAuditAction.CREATED, null,
                ticketNumber.value() + ", priority " + priority.name() + ", category " + category.name(), createdAt);
    }

    public IncidentId id() {
        return id;
    }

    public TicketNumber ticketNumber() {
        return ticketNumber;
    }

    public Title title() {
        return title;
    }

    public Description description() {
        return description;
    }

    public Category category() {
        return category;
    }

    public Priority priority() {
        return priority;
    }

    public IncidentStatus status() {
        return status;
    }

    public UUID createdBy() {
        return createdBy;
    }

    public Instant createdAt() {
        return createdAt;
    }
}
