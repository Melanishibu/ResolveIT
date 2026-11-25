package com.itsm.resolveit.identity.adapters.in.web;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Body of {@code POST /api/v1/auth/login}. Transport checks only (required, format, length); an
 * invalid request gets {@code VALIDATION_FAILED} with the field names.
 */
@Schema(description = "Email and password of the user who logs in")
record LoginRequest(
        @NotBlank @Email @Size(max = 254) @Schema(example = "employee1@resolveit.local") String email,
        @NotBlank @Size(max = 128) @Schema(format = "password") String password) {

    @Override
    public String toString() {
        return "LoginRequest[email=" + email + ", password=***]";
    }
}
