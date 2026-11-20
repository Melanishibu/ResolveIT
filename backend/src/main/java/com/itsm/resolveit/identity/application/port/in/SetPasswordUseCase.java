package com.itsm.resolveit.identity.application.port.in;

/**
 * Use case: a user sets their password from a one-time link (RIT-US-07; the same endpoint serves the
 * password reset of RIT-US-23). No automatic login.
 */
public interface SetPasswordUseCase {

    void setPassword(SetPasswordCommand command);
}
