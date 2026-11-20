package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.UserPage;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.UserRow;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

/** A page of the user list: {@code {items, page, size, totalItems, totalPages}} (RIT-US-08). */
@Schema(description = "A page of users")
record UserListResponse(List<Item> items, int page, int size, long totalItems, int totalPages) {

    static UserListResponse of(UserPage page) {
        return new UserListResponse(page.items().stream().map(Item::of).toList(), page.page(), page.size(),
                page.totalItems(), page.totalPages());
    }

    /** One user row. */
    @Schema(name = "UserListItem")
    record Item(
            String id,
            String name,
            String email,
            @Schema(allowableValues = {"ADMIN", "SUPPORT_AGENT", "EMPLOYEE"},
                    description = "SUPPORT_AGENT is shown as Technician") String role,
            String department,
            boolean active,
            @Schema(allowableValues = {"PENDING", "ACCEPTED", "EXPIRED", "SEND_FAILED"}, nullable = true,
                    description = "From the latest invitation; null when the user has neither invitation nor password")
            String invitationStatus) {

        static Item of(UserRow row) {
            return new Item(row.id().toString(), row.name(), row.email(), row.role().name(), row.department(),
                    row.active(), row.invitationStatus().map(Enum::name).orElse(null));
        }
    }
}
