package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.out.EmailSender.EmailMessage;
import com.itsm.resolveit.identity.domain.event.UserInvited;
import com.itsm.resolveit.identity.domain.model.Role;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Objects;

/**
 * Writes the invitation email (RIT-US-06): subject "Your ResolveIT account", the user's name and role,
 * the set-password link. Never a password.
 */
public final class InvitationEmail {

    static final String SUBJECT = "Your ResolveIT account";

    private final String frontendBaseUrl;

    public InvitationEmail(String frontendBaseUrl) {
        Objects.requireNonNull(frontendBaseUrl, "frontendBaseUrl");
        this.frontendBaseUrl = frontendBaseUrl.endsWith("/")
                ? frontendBaseUrl.substring(0, frontendBaseUrl.length() - 1)
                : frontendBaseUrl;
    }

    public EmailMessage compose(UserInvited invitation) {
        String link = frontendBaseUrl + "/set-password?token="
                + URLEncoder.encode(invitation.token().value(), StandardCharsets.UTF_8);
        String body = """
                Hello %s,

                an account has been created for you in ResolveIT, the IT Service Desk, with the role %s.

                To start, set your own password with this link (valid for 24 hours, usable once):
                %s

                If you did not expect this email, you can ignore it.

                ResolveIT
                """.formatted(invitation.name().value(), roleLabel(invitation.role()), link);
        return new EmailMessage(invitation.email(), SUBJECT, body);
    }

    /** The UI name of the role (Update 01, M6: SUPPORT_AGENT is "Technician" everywhere). */
    static String roleLabel(Role role) {
        return switch (role) {
            case ADMIN -> "Admin";
            case SUPPORT_AGENT -> "Technician";
            case EMPLOYEE -> "Employee";
        };
    }
}
