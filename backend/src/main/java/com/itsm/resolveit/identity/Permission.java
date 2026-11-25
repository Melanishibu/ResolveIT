package com.itsm.resolveit.identity;

import java.util.EnumSet;
import java.util.Set;

/**
 * The unconditional rows of the permission table (common rules, 11/19/2026). The backend enforces
 * them; the UI only hides actions.
 *
 * <p>Rows that depend on the incident ("if assigned", "own incident") are rules of the incident
 * domain and are checked there, on top of these.
 */
public enum Permission {

    /** Create incident: Admin, Employee. */
    CREATE_INCIDENT(EnumSet.of(ActorRole.ADMIN, ActorRole.EMPLOYEE)),
    /** See all incidents (others see only their assigned or own incidents): Admin. */
    VIEW_ALL_INCIDENTS(EnumSet.of(ActorRole.ADMIN)),
    /** Assign / reassign: Admin. */
    ASSIGN_INCIDENT(EnumSet.of(ActorRole.ADMIN)),
    /** Change priority: Admin. */
    CHANGE_PRIORITY(EnumSet.of(ActorRole.ADMIN)),
    /** Manage users (create Agent/Employee, activate/deactivate, resend invite): Admin. */
    MANAGE_USERS(EnumSet.of(ActorRole.ADMIN));

    private final Set<ActorRole> allowedRoles;

    Permission(Set<ActorRole> allowedRoles) {
        this.allowedRoles = Set.copyOf(allowedRoles);
    }

    /** Whether {@code role} has this permission. */
    public boolean isGrantedTo(ActorRole role) {
        return allowedRoles.contains(role);
    }
}
