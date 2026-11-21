package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.PasswordHash;

/** Checks a raw password against a stored one-way hash. */
public interface PasswordVerifier {

    boolean matches(String rawPassword, PasswordHash hash);

    /**
     * Spends the same effort as {@link #matches} without a real hash, so that the response time does
     * not reveal whether an email address belongs to an account.
     */
    void verifyAgainstDummy(String rawPassword);
}
