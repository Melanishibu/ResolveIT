package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.in.SendPasswordResetUseCase;
import com.itsm.resolveit.identity.application.port.out.EmailSender;
import com.itsm.resolveit.identity.application.port.out.EmailSender.EmailNotSentException;
import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.domain.event.PasswordResetRequested;
import com.itsm.resolveit.identity.domain.model.Invitation;
import java.util.Objects;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Sends the password reset email after the transaction committed (RIT-US-23). */
public class SendPasswordResetService implements SendPasswordResetUseCase {

    private static final Logger log = LoggerFactory.getLogger(SendPasswordResetService.class);

    private final InvitationRepository invitations;
    private final EmailSender emailSender;
    private final PasswordResetEmail email;

    public SendPasswordResetService(InvitationRepository invitations, EmailSender emailSender,
                                   PasswordResetEmail email) {
        this.invitations = Objects.requireNonNull(invitations, "invitations");
        this.emailSender = Objects.requireNonNull(emailSender, "emailSender");
        this.email = Objects.requireNonNull(email, "email");
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    @Override
    public void send(PasswordResetRequested event) {
        Invitation invitation = invitations.findById(event.invitationId())
                .orElseThrow(() -> new IllegalStateException("Invitation " + event.invitationId() + " not found"));
        try {
            emailSender.send(email.compose(event));
            invitation.markSent();
        } catch (EmailNotSentException failed) {
            log.warn("Password reset email for user {} could not be sent: {}", event.userId(), failed.getMessage());
            invitation.markSendFailed();
        }
        invitations.save(invitation);
    }
}
