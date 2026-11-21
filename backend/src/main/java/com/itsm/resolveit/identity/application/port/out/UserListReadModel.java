package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.Criteria;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.UserPage;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.UserRow;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.time.Instant;
import java.util.Optional;

/** Read model of the user list (CQRS-lite, RIT-US-08): never changes state. */
public interface UserListReadModel {

    /** The page matching {@code criteria}; invitation states are derived at {@code now}. */
    UserPage find(Criteria criteria, Instant now);

    /** One row (after a status change). */
    Optional<UserRow> findRow(UserId id, Instant now);
}
