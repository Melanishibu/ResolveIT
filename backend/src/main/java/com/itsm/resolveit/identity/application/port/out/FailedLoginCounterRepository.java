package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.FailedLoginCounter;

/** Repository of the {@link FailedLoginCounter} of email addresses that have no account (bug AB#180). */
public interface FailedLoginCounterRepository {

    /**
     * Loads the counter of this email, or a fresh one if there is none, and locks it until the current
     * transaction ends, so that concurrent attempts cannot lose a failure count.
     */
    FailedLoginCounter lockOrStart(EmailAddress email);

    /** Stores the counter's current state. */
    void save(FailedLoginCounter counter);
}
