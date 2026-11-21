package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.application.port.in.CurrentUserView;
import io.swagger.v3.oas.annotations.media.Schema;

/** The logged-in user: {@code {id, name, email, role}} (spec of RIT-US-04). */
@Schema(description = "The logged-in user")
record CurrentUserResponse(
        @Schema(description = "User id (UUID)") String id,
        @Schema(description = "Display name", example = "Employee One") String name,
        @Schema(example = "employee1@resolveit.local") String email,
        @Schema(allowableValues = {"ADMIN", "SUPPORT_AGENT", "EMPLOYEE"}) String role) {

    static CurrentUserResponse of(CurrentUserView view) {
        return new CurrentUserResponse(
                view.id().toString(), view.name().value(), view.email().value(), view.role().name());
    }
}
