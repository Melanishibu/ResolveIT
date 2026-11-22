package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.model.EmailAddress;
import java.util.Objects;

/** Command to request a password reset for an email address (RIT-US-23). */
public record ForgotPasswordCommand(EmailAddress email) {

    public ForgotPasswordCommand {
        Objects.requireNonNull(email, "email");
    }
}
