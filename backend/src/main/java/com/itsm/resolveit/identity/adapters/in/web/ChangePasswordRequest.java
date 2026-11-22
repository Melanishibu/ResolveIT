package com.itsm.resolveit.identity.adapters.in.web;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

/** Request body for changing the logged-in user's password (RIT-US-27). */
@Schema(description = "Change password request")
record ChangePasswordRequest(
        @NotBlank @Schema(description = "Current password", example = "OldSecret-1234") String currentPassword,
        @NotBlank @Schema(description = "New password following policy", example = "NewSecret-5678") String newPassword) {
}
