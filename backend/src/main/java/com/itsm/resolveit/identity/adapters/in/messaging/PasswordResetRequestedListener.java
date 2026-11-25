package com.itsm.resolveit.identity.adapters.in.messaging;

import com.itsm.resolveit.identity.application.port.in.SendPasswordResetUseCase;
import com.itsm.resolveit.identity.domain.event.PasswordResetRequested;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Sends the password reset email only after the transaction has been committed (RIT-US-23).
 */
class PasswordResetRequestedListener {

    private final SendPasswordResetUseCase sendPasswordReset;

    PasswordResetRequestedListener(SendPasswordResetUseCase sendPasswordReset) {
        this.sendPasswordReset = sendPasswordReset;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    void on(PasswordResetRequested event) {
        sendPasswordReset.send(event);
    }
}
