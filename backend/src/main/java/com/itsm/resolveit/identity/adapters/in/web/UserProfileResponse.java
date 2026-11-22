package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.application.port.in.UserProfileView;
import io.swagger.v3.oas.annotations.media.Schema;

/**
 * Response for {@code GET /api/v1/users/me}: name, email, role, roleLabel, department, memberSince (RIT-US-27).
 */
@Schema(description = "Current user profile")
record UserProfileResponse(
        @Schema(description = "Display name", example = "Employee One") String name,
        @Schema(description = "Email address", example = "employee1@resolveit.local") String email,
        @Schema(allowableValues = {"ADMIN", "SUPPORT_AGENT", "EMPLOYEE"}, description = "Role code") String role,
        @Schema(description = "Role label for UI", example = "Employee") String roleLabel,
        @Schema(description = "Department name", example = "Finance") String department,
        @Schema(description = "Member since (ISO-8601 UTC)") String memberSince) {

    static UserProfileResponse of(UserProfileView view) {
        String roleLabel = switch (view.role()) {
            case ADMIN -> "Admin";
            case SUPPORT_AGENT -> "Technician";
            case EMPLOYEE -> "Employee";
        };
        return new UserProfileResponse(
                view.name().value(),
                view.email().value(),
                view.role().name(),
                roleLabel,
                view.department().value(),
                view.memberSince().toString());
    }
}
