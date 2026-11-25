package com.itsm.resolveit.identity.adapters.in.messaging;

import com.itsm.resolveit.identity.application.port.in.SendInvitationUseCase;
import com.itsm.resolveit.identity.domain.event.UserInvited;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Sends the invitation email only after the user has been committed (RIT-US-06: "email sent after
 * commit"). If the creating transaction rolls back, no email is sent.
 */
class UserInvitedListener {

    private final SendInvitationUseCase sendInvitation;

    UserInvitedListener(SendInvitationUseCase sendInvitation) {
        this.sendInvitation = sendInvitation;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    void on(UserInvited event) {
        sendInvitation.send(event);
    }
}
