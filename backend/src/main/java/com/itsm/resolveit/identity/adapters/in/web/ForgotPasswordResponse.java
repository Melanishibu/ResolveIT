package com.itsm.resolveit.identity.adapters.in.web;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Outcome of the forgot password request")
record ForgotPasswordResponse(
        @Schema(description = "Informational message",
                example = "If an active account exists for that email, a password reset link has been sent.")
        String message) {

    public static final String DEFAULT_MESSAGE =
            "If an active account exists for that email, a password reset link has been sent.";

    public static ForgotPasswordResponse defaultMessage() {
        return new ForgotPasswordResponse(DEFAULT_MESSAGE);
    }
}
