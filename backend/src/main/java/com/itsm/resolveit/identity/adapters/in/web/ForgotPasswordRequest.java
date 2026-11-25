package com.itsm.resolveit.identity.adapters.in.web;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Email of the user requesting a password reset")
record ForgotPasswordRequest(
        @NotBlank @Email @Size(max = 254) @Schema(example = "employee1@resolveit.local") String email) {

    @Override
    public String toString() {
        return "ForgotPasswordRequest[email=" + email + "]";
    }
}
