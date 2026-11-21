package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.util.Optional;

/** Repository of the {@link User} aggregate. */
public interface UserRepository {

    /**
     * Loads the user with this email and locks it until the current transaction ends, so that
     * concurrent login attempts cannot lose a failure count.
     */
    Optional<User> lockByEmail(EmailAddress email);

    Optional<User> findById(UserId id);

    /** Loads the user and locks it until the current transaction ends (status and password changes). */
    Optional<User> lockById(UserId id);

    /** Whether a user with this email exists (emails are stored in lower case, so this is case-insensitive). */
    boolean existsByEmail(EmailAddress email);

    UserId nextId();

    /** Stores the user's current state (inserts or updates). */
    void save(User user);
}
