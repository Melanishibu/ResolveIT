package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.Invitation;
import com.itsm.resolveit.identity.domain.model.InvitationId;
import java.util.Optional;

/** Repository of the {@link Invitation} aggregate. */
public interface InvitationRepository {

    InvitationId nextId();

    void save(Invitation invitation);

    Optional<Invitation> findById(InvitationId id);

    /**
     * The invitation whose token has this SHA-256 hash. Inside a transaction, a second caller with the
     * same hash waits until the first one commits (single use, RIT-US-07).
     */
    Optional<Invitation> findByTokenHash(String tokenHash);

    /**
     * Invalidates all earlier unexpired invitations of this user (RIT-US-22: resend invitation).
     */
    void invalidatePending(com.itsm.resolveit.identity.domain.model.UserId userId, java.time.Instant now);
}
