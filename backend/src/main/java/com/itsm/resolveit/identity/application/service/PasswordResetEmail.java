package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.out.EmailSender.EmailMessage;
import com.itsm.resolveit.identity.domain.event.PasswordResetRequested;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Objects;

/**
 * Writes the password reset email (RIT-US-23): subject "Reset your ResolveIT password",
 * the set-password link. Never a password.
 */
public final class PasswordResetEmail {

    static final String SUBJECT = "Reset your ResolveIT password";

    private final String frontendBaseUrl;

    public PasswordResetEmail(String frontendBaseUrl) {
        Objects.requireNonNull(frontendBaseUrl, "frontendBaseUrl");
        this.frontendBaseUrl = frontendBaseUrl.endsWith("/")
                ? frontendBaseUrl.substring(0, frontendBaseUrl.length() - 1)
                : frontendBaseUrl;
    }

    public EmailMessage compose(PasswordResetRequested event) {
        String link = frontendBaseUrl + "/set-password?token="
                + URLEncoder.encode(event.token().value(), StandardCharsets.UTF_8);
        String body = """
                Hello %s,

                a password reset was requested for your ResolveIT account.

                To reset your password, use this link (valid for 1 hour, usable once):
                %s

                If you did not request a password reset, you can safely ignore this email.

                ResolveIT
                """.formatted(event.name().value(), link);
        return new EmailMessage(event.email(), SUBJECT, body);
    }
}
