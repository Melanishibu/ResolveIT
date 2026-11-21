package com.itsm.resolveit.identity.adapters.in.web;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Body of {@code POST /api/v1/users}. Transport checks (required, length, known role); an invalid
 * request gets {@code VALIDATION_FAILED} with the field names. ADMIN is a known role but refused by
 * the domain ({@code USER_ROLE_NOT_ALLOWED}).
 */
@Schema(description = "The user to create; they receive an invitation email")
record CreateUserRequest(
        @NotBlank @Size(max = 100) @Schema(example = "Asha Rao") String name,
        @NotBlank @Size(max = 254) @Schema(example = "asha@resolveit.local") String email,
        @NotBlank @Pattern(regexp = "ADMIN|SUPPORT_AGENT|EMPLOYEE")
        @Schema(allowableValues = {"SUPPORT_AGENT", "EMPLOYEE"}, description = "SUPPORT_AGENT is shown as Technician")
        String role,
        @NotBlank @Size(max = 80) @Schema(example = "IT Support") String department) {
}
