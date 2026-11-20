package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.model.SessionToken;
import java.util.Optional;

/** Use case: end the caller's session. Idempotent: without a valid session there is nothing to end. */
public interface LogOutUseCase {

    void logOut(Optional<SessionToken> token);
}
