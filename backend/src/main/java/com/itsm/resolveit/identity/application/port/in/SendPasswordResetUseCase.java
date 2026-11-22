package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.event.PasswordResetRequested;

/** Use case: send password reset email after commit (RIT-US-23). */
public interface SendPasswordResetUseCase {

    void send(PasswordResetRequested event);
}
