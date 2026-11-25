package com.itsm.resolveit.identity.application.port.in;

import java.util.Objects;

/**
 * Login request as typed by the user. Both values are untrusted input: an email that is not a valid
 * address simply never matches an account.
 *
 * @param email    the email address as entered
 * @param password the raw password; never logged or stored
 */
public record LogInCommand(String email, String password) {

    public LogInCommand {
        Objects.requireNonNull(email, "email");
        Objects.requireNonNull(password, "password");
    }

    @Override
    public String toString() {
        return "LogInCommand[email=" + email + ", password=***]";
    }
}
