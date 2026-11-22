package com.itsm.resolveit.identity.application.port.in;

/** Use case: request password reset by email (RIT-US-23). */
public interface ForgotPasswordUseCase {

    void forgotPassword(ForgotPasswordCommand command);
}
