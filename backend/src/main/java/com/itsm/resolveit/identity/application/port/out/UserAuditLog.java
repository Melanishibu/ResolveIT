package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.UserAuditEntry;

/** The append-only user audit log: entries can only be added, never changed or removed. */
public interface UserAuditLog {

    void append(UserAuditEntry entry);
}
