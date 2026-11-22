package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry.IncidentAuditAction;
import java.time.Instant;
import java.util.EnumSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
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
    /** Set when resolved (RIT-US-16); kept after a reopen, so the history stays readable. */
    private ResolutionNotes resolutionNotes;

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

    /** Rebuilds a stored incident with its assignee and resolution notes (each null if not set). */
    public static Incident reconstitute(IncidentId id, TicketNumber ticketNumber, Title title, Description description,
                                        Category category, Priority priority, IncidentStatus status, UUID createdBy,
                                        Instant createdAt, Instant updatedAt, UUID assignedTo,
                                        ResolutionNotes resolutionNotes) {
        Incident incident = new Incident(id, ticketNumber, title, description, category, priority, status, createdBy,
                createdAt, updatedAt, assignedTo);
        incident.resolutionNotes = resolutionNotes;
        return incident;
    }

    /** The assigned Support Agent, if any. */
    public java.util.Optional<UUID> assignedTo() {
        return java.util.Optional.ofNullable(assignedTo);
    }

    /** The notes of the latest resolution, if it was ever resolved (RIT-US-16). */
    public java.util.Optional<ResolutionNotes> resolutionNotes() {
        return java.util.Optional.ofNullable(resolutionNotes);
    }

    /** Resolve (RIT-US-16): IN_PROGRESS → RESOLVED with notes. Returns the RESOLVED audit entry (notes as new value). */
    public IncidentAuditEntry resolve(ResolutionNotes notes, UUID actorId, Instant now) {
        Objects.requireNonNull(notes, "notes");
        Objects.requireNonNull(actorId, "actorId");
        if (status != IncidentStatus.IN_PROGRESS) {
            throw new IncidentInvalidTransitionException(status);
        }
        status = IncidentStatus.RESOLVED;
        resolutionNotes = notes;
        updatedAt = Objects.requireNonNull(now, "now");
        return new IncidentAuditEntry(id, actorId, IncidentAuditAction.RESOLVED, IncidentStatus.IN_PROGRESS.name(),
                notes.value(), now);
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
    /**
     * An Admin assigns the incident to a Support Agent (RIT-US-14): OPEN → ASSIGNED, or a reassignment that stays
     * ASSIGNED. Any other status is an invalid transition. Returns the audit entry (actor = the Admin).
     */
    public IncidentAuditEntry assignTo(UUID agentId, UUID adminId, Instant now) {
        Objects.requireNonNull(agentId, "agentId");
        Objects.requireNonNull(adminId, "adminId");
        IncidentAuditAction action = switch (status) {
            case OPEN -> IncidentAuditAction.ASSIGNED;
            case ASSIGNED -> IncidentAuditAction.REASSIGNED;
            default -> throw new IncidentInvalidTransitionException(status);
        };
        String previous = assignedTo == null ? null : assignedTo.toString();
        assignedTo = agentId;
        status = IncidentStatus.ASSIGNED;
        updatedAt = Objects.requireNonNull(now, "now");
        return new IncidentAuditEntry(id, adminId, action, previous, agentId.toString(), now);
    }

    /**
     * The status action that moves this incident to {@code target}, per the allowed-transitions table (RIT-US-15).
     * Anything not in the table, including every change of a CLOSED incident, is an invalid transition.
     */
    public IncidentAction statusActionFor(IncidentStatus target) {
        Objects.requireNonNull(target, "target");
        IncidentAction action = switch (status) {
            case ASSIGNED -> target == IncidentStatus.IN_PROGRESS ? IncidentAction.START : null;
            case IN_PROGRESS -> target == IncidentStatus.RESOLVED ? IncidentAction.RESOLVE : null;
            case RESOLVED -> switch (target) {
                case IN_PROGRESS -> IncidentAction.REOPEN;
                case CLOSED -> IncidentAction.CLOSE;
                default -> null;
            };
            case OPEN, CLOSED -> null;
        };
        if (action == null) {
            throw new IncidentInvalidTransitionException(status);
        }
        return action;
    }

    /** Start work (RIT-US-15): ASSIGNED → IN_PROGRESS. Returns the STARTED audit entry. */
    public IncidentAuditEntry startWork(UUID actorId, Instant now) {
        Objects.requireNonNull(actorId, "actorId");
        if (status != IncidentStatus.ASSIGNED) {
            throw new IncidentInvalidTransitionException(status);
        }
        status = IncidentStatus.IN_PROGRESS;
        updatedAt = Objects.requireNonNull(now, "now");
        return new IncidentAuditEntry(id, actorId, IncidentAuditAction.STARTED, IncidentStatus.ASSIGNED.name(),
                IncidentStatus.IN_PROGRESS.name(), now);
    }

    /** {@code author} comments on this incident (RIT-US-20). A CLOSED incident takes no comments (BR-013). */
    public IncidentComment comment(UUID commentId, UUID author, CommentText text, Instant now) {
        if (status == IncidentStatus.CLOSED) {
            throw new IncidentClosedException();
        }
        return new IncidentComment(commentId, id, author, text, now);
    }

    /**
     * Reopen (RIT-US-17): RESOLVED → IN_PROGRESS with a reason. The previous resolution notes stay in the history.
     * Returns the REOPENED audit entry (reason as new value).
     */
    public IncidentAuditEntry reopen(ReopenReason reason, UUID actorId, Instant now) {
        Objects.requireNonNull(reason, "reason");
        Objects.requireNonNull(actorId, "actorId");
        if (status != IncidentStatus.RESOLVED) {
            throw new IncidentInvalidTransitionException(status);
        }
        status = IncidentStatus.IN_PROGRESS;
        updatedAt = Objects.requireNonNull(now, "now");
        return new IncidentAuditEntry(id, actorId, IncidentAuditAction.REOPENED, IncidentStatus.RESOLVED.name(),
                reason.value(), now);
    }

    /** Close (RIT-US-18): RESOLVED → CLOSED, which is final. Returns the CLOSED audit entry. */
    public IncidentAuditEntry close(UUID actorId, Instant now) {
        Objects.requireNonNull(actorId, "actorId");
        if (status != IncidentStatus.RESOLVED) {
            throw new IncidentInvalidTransitionException(status);
        }
        status = IncidentStatus.CLOSED;
        updatedAt = Objects.requireNonNull(now, "now");
        return new IncidentAuditEntry(id, actorId, IncidentAuditAction.CLOSED, IncidentStatus.RESOLVED.name(),
                IncidentStatus.CLOSED.name(), now);
    }

    /**
     * Change priority (RIT-US-19): Admin only, not allowed on CLOSED (INCIDENT_CLOSED, 409).
     * Same priority again -> no change, returns Optional.empty() (no audit entry).
     * Different priority -> updates priority and updatedAt, returns Optional with PRIORITY_CHANGED audit entry.
     */
    public Optional<IncidentAuditEntry> changePriority(Priority newPriority, UUID actorId, Instant now) {
        Objects.requireNonNull(newPriority, "newPriority");
        Objects.requireNonNull(actorId, "actorId");
        Objects.requireNonNull(now, "now");
        if (status == IncidentStatus.CLOSED) {
            throw new IncidentClosedException();
        }
        if (this.priority == newPriority) {
            return Optional.empty();
        }
        Priority oldPriority = this.priority;
        this.priority = newPriority;
        this.updatedAt = now;
        return Optional.of(new IncidentAuditEntry(id, actorId, IncidentAuditAction.PRIORITY_CHANGED,
                oldPriority.name(), newPriority.name(), now));
    }

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
