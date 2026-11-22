package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.in.SendInvitationUseCase;
import com.itsm.resolveit.identity.application.port.out.EmailSender;
import com.itsm.resolveit.identity.application.port.out.EmailSender.EmailNotSentException;
import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.domain.event.UserInvited;
import com.itsm.resolveit.identity.domain.model.Invitation;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry.UserAuditAction;
import java.time.Clock;
import java.util.Objects;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Sends the invitation email after the user was committed, and records the outcome. */
public class SendInvitationService implements SendInvitationUseCase {

    private static final Logger log = LoggerFactory.getLogger(SendInvitationService.class);

    private final InvitationRepository invitations;
    private final UserAuditLog auditLog;
    private final EmailSender emailSender;
    private final InvitationEmail email;
    private final Clock clock;

    public SendInvitationService(InvitationRepository invitations, UserAuditLog auditLog, EmailSender emailSender,
                                 InvitationEmail email, Clock clock) {
        this.invitations = Objects.requireNonNull(invitations, "invitations");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.emailSender = Objects.requireNonNull(emailSender, "emailSender");
        this.email = Objects.requireNonNull(email, "email");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    /** Runs after the creating transaction committed, in a transaction of its own. */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    @Override
    public void send(UserInvited event) {
        Invitation invitation = invitations.findById(event.invitationId())
                .orElseThrow(() -> new IllegalStateException("Invitation " + event.invitationId() + " not found"));
        try {
            emailSender.send(email.compose(event));
            invitation.markSent();
            if (!event.resend()) {
                auditLog.append(new UserAuditEntry(event.userId(), event.actorId(), UserAuditAction.INVITATION_SENT, null,
                        event.email().value(), clock.instant()));
            }
        } catch (EmailNotSentException failed) {
            // The user stays created; the Admin sees SEND_FAILED and can resend (RIT-US-22). No link in the log.
            log.warn("Invitation email for user {} could not be sent: {}", event.userId(), failed.getMessage());
            invitation.markSendFailed();
        }
        invitations.save(invitation);
    }
}
