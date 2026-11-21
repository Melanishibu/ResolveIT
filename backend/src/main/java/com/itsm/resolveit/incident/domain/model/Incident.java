package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry.IncidentAuditAction;
import java.time.Instant;
import java.util.EnumSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
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
    private Priority priority;
    private IncidentStatus status;
    private final UUID createdBy;
    private final Instant createdAt;
    private Instant updatedAt;
    /** The Support Agent working on it; null until assigned (RIT-US-12). */
    private UUID assignedTo;

    private Incident(IncidentId id, TicketNumber ticketNumber, Title title, Description description, Category category,
                     Priority priority, IncidentStatus status, UUID createdBy, Instant createdAt, Instant updatedAt,
                     UUID assignedTo) {
        this.assignedTo = assignedTo;
        this.id = Objects.requireNonNull(id, "id");
        this.ticketNumber = Objects.requireNonNull(ticketNumber, "ticketNumber");
        this.title = Objects.requireNonNull(title, "title");
        this.description = Objects.requireNonNull(description, "description");
        this.category = Objects.requireNonNull(category, "category");
        this.priority = Objects.requireNonNull(priority, "priority");
        this.status = Objects.requireNonNull(status, "status");
        this.createdBy = Objects.requireNonNull(createdBy, "createdBy");
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.updatedAt = Objects.requireNonNull(updatedAt, "updatedAt");
    }

    /** A user reports a new incident: it starts OPEN, created by {@code reporter}. */
    public static Incident report(IncidentId id, TicketNumber ticketNumber, Title title, Description description,
                                  Category category, Priority priority, UUID reporter, Instant now) {
        return new Incident(id, ticketNumber, title, description, category, priority, IncidentStatus.OPEN, reporter,
                now, now, null);
    }

    /** Rebuilds a stored incident that was never changed after it was reported (updated = created). */
    public static Incident reconstitute(IncidentId id, TicketNumber ticketNumber, Title title, Description description,
                                        Category category, Priority priority, IncidentStatus status, UUID createdBy,
                                        Instant createdAt) {
        return reconstitute(id, ticketNumber, title, description, category, priority, status, createdBy, createdAt,
                createdAt);
    }

    /** Rebuilds a stored incident. */
    public static Incident reconstitute(IncidentId id, TicketNumber ticketNumber, Title title, Description description,
                                        Category category, Priority priority, IncidentStatus status, UUID createdBy,
                                        Instant createdAt, Instant updatedAt) {
        return reconstitute(id, ticketNumber, title, description, category, priority, status, createdBy, createdAt,
                updatedAt, null);
    }

    /** Rebuilds a stored incident with its assignee (null if unassigned). */
    public static Incident reconstitute(IncidentId id, TicketNumber ticketNumber, Title title, Description description,
                                        Category category, Priority priority, IncidentStatus status, UUID createdBy,
                                        Instant createdAt, Instant updatedAt, UUID assignedTo) {
        return new Incident(id, ticketNumber, title, description, category, priority, status, createdBy, createdAt,
                updatedAt, assignedTo);
    }

    /** The assigned Support Agent, if any. */
    public java.util.Optional<UUID> assignedTo() {
        return java.util.Optional.ofNullable(assignedTo);
    }

    /**
     * Whether {@code viewer} may see this incident (permission table, "See incidents"): Admins see all, Employees
     * the ones they created, Support Agents the ones assigned to them (RIT-US-10).
     */
    public boolean isVisibleTo(Viewer viewer) {
        Objects.requireNonNull(viewer, "viewer");
        return switch (viewer.role()) {
            case ADMIN -> true;
            case EMPLOYEE -> isCreatedBy(viewer);
            case SUPPORT_AGENT -> isAssignedTo(viewer);
        };
    }

    /**
     * The actions {@code viewer} may take now, from the permission table and the allowed transitions of the common
     * rules. CLOSED is final, so it allows nothing (BR-013). Empty for a viewer who may not see the incident.
     */
    public Set<IncidentAction> allowedActionsFor(Viewer viewer) {
        if (!isVisibleTo(viewer) || status == IncidentStatus.CLOSED) {
            return Set.of();
        }
        Set<IncidentAction> actions = EnumSet.noneOf(IncidentAction.class);
        switch (viewer.role()) {
            case ADMIN -> {
                actions.add(IncidentAction.CHANGE_PRIORITY);
                switch (status) {
                    case OPEN -> actions.add(IncidentAction.ASSIGN);
                    case ASSIGNED -> actions.addAll(List.of(IncidentAction.REASSIGN, IncidentAction.START));
                    case IN_PROGRESS -> actions.add(IncidentAction.RESOLVE);
                    case RESOLVED -> actions.addAll(List.of(IncidentAction.REOPEN, IncidentAction.CLOSE));
                    default -> { }
                }
            }
            case SUPPORT_AGENT -> {
                switch (status) {
                    case ASSIGNED -> actions.add(IncidentAction.START);
                    case IN_PROGRESS -> actions.add(IncidentAction.RESOLVE);
                    case RESOLVED -> actions.add(IncidentAction.REOPEN);
                    default -> { }
                }
            }
            case EMPLOYEE -> {
                if (status == IncidentStatus.RESOLVED) {
                    actions.addAll(List.of(IncidentAction.REOPEN, IncidentAction.CLOSE));
                }
            }
        }
        return Set.copyOf(actions);
    }

    private boolean isCreatedBy(Viewer viewer) {
        return createdBy.equals(viewer.userId());
    }

    private boolean isAssignedTo(Viewer viewer) {
        return viewer.userId().equals(assignedTo);
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

    public Instant updatedAt() {
        return updatedAt;
    }
}
