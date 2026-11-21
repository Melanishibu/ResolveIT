package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.application.port.in.CreatedUserView;
import io.swagger.v3.oas.annotations.media.Schema;

/** The created user: {@code {id, name, email, role, department, active, invitationStatus}}. */
@Schema(description = "The created user")
record CreatedUserResponse(
        String id,
        String name,
        String email,
        @Schema(allowableValues = {"SUPPORT_AGENT", "EMPLOYEE"}) String role,
        String department,
        boolean active,
        @Schema(allowableValues = {"PENDING", "SENT", "SEND_FAILED", "USED"},
                description = "PENDING until the email has been attempted after the commit") String invitationStatus) {

    static CreatedUserResponse of(CreatedUserView view) {
        return new CreatedUserResponse(view.id().toString(), view.name().value(), view.email().value(),
                view.role().name(), view.department().value(), view.active(), view.invitationStatus().name());
    }
}
