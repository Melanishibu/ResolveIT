package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.domain.model.Role;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/** Query: the Admin's user list with filters and paging (RIT-US-08). Admin only (MANAGE_USERS). */
public interface ListUsersQuery {

    UserPage list(Actor actor, Criteria criteria);

    /** Sortable fields of the list. */
    enum SortField { NAME, EMAIL, ROLE, DEPARTMENT }

    /** Filters and paging; {@code size} is 1–100. */
    record Criteria(Optional<Role> role, Optional<Boolean> active, Optional<String> search, int page, int size,
                    SortField sortField, boolean ascending) {

        public static final int DEFAULT_SIZE = 20;
        public static final int MAX_SIZE = 100;

        public Criteria {
            Objects.requireNonNull(role, "role");
            Objects.requireNonNull(active, "active");
            Objects.requireNonNull(search, "search");
            Objects.requireNonNull(sortField, "sortField");
            if (page < 0 || size < 1 || size > MAX_SIZE) {
                throw new IllegalArgumentException("page must be >= 0 and size 1–" + MAX_SIZE);
            }
        }
    }

    /** The invitation status shown in the list, derived from the latest invitation (Plan question 1). */
    enum InvitationState { PENDING, ACCEPTED, EXPIRED, SEND_FAILED }

    /** One row of the list. */
    record UserRow(UUID id, String name, String email, Role role, String department, boolean active,
                   Optional<InvitationState> invitationStatus) {
    }

    /** One page: {@code items, page, size, totalItems, totalPages} (common API conventions). */
    record UserPage(List<UserRow> items, int page, int size, long totalItems, int totalPages) {
    }
}
