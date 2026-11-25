package com.itsm.resolveit.identity.adapters.in.web;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Body of {@code POST /api/v1/auth/password/set} (RIT-US-07). Transport checks only; the password policy
 * is the domain's ({@code PASSWORD_POLICY_VIOLATION}), the sizes are a generous guard.
 */
@Schema(description = "The token from the email link and the new password")
record SetPasswordRequest(
        @NotBlank @Size(max = 256) @Schema(description = "The token query parameter of the link") String token,
        @NotNull @Size(max = 1024)
        @Schema(format = "password", description = "12–128 characters, at least one letter and one digit, not the email")
        String newPassword) {

    @Override
    public String toString() {
        return "SetPasswordRequest[***]";
    }
}
