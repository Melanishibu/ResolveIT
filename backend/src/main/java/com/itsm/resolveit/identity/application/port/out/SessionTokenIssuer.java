package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.SessionToken;
import com.itsm.resolveit.identity.domain.model.UserSession;

/** Issues the signed session token that refers to a session. */
public interface SessionTokenIssuer {

    SessionToken issue(UserSession session);
}
