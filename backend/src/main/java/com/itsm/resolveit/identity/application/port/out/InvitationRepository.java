package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.Invitation;
import com.itsm.resolveit.identity.domain.model.InvitationId;
import java.util.Optional;

/** Repository of the {@link Invitation} aggregate. */
public interface InvitationRepository {

    InvitationId nextId();

    void save(Invitation invitation);

    Optional<Invitation> findById(InvitationId id);
}
