package com.itsm.resolveit.identity.application.port.in;

/** Inbound port to change the logged-in user's password (RIT-US-27). */
public interface ChangePasswordUseCase {

    void changePassword(ChangePasswordCommand command);
}
