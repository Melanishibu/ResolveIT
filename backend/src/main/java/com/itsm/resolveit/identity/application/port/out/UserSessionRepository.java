package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.SessionId;
import com.itsm.resolveit.identity.domain.model.UserSession;
import java.util.Optional;

/** Repository of the {@link UserSession} aggregate. */
public interface UserSessionRepository {

    SessionId nextId();

    void save(UserSession session);

    Optional<UserSession> findById(SessionId id);

    /** Ends the session for good (logout). Does nothing if it no longer exists. */
    void delete(SessionId id);
}
