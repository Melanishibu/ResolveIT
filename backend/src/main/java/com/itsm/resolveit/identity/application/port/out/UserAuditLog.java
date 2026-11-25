package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.time.Instant;

/** The append-only user audit log: entries can only be added, never changed or removed. */
public interface UserAuditLog {

    void append(UserAuditEntry entry);

    default int countByUserIdAndActionSince(UserId userId, UserAuditEntry.UserAuditAction action, Instant since) {
        return 0;
    }
}
