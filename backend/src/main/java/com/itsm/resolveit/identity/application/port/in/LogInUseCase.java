package com.itsm.resolveit.identity.application.port.in;

/**
 * Use case: log in with email and password.
 *
 * <p>Refusals are {@code InvalidCredentialsException} (wrong password, unknown email, inactive
 * account: one generic message) and {@code LoginTemporarilyBlockedException} (account locked).
 */
public interface LogInUseCase {

    LoginResult logIn(LogInCommand command);
}
