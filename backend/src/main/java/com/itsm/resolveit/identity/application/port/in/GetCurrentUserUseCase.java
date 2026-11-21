package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.model.SessionToken;
import java.util.Optional;

/**
 * Use case: who is logged in on this session.
 *
 * <p>Throws {@code NotAuthenticatedException} when the token is missing, invalid or expired, the
 * session was ended by logout, or the user has been deactivated since (common rules: a deactivated
 * user's session is rejected on the next request).
 */
public interface GetCurrentUserUseCase {

    CurrentUserView currentUser(Optional<SessionToken> token);
}
