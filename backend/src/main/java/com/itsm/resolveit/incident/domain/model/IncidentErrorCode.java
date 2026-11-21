package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.shared.error.ErrorCode;
import java.util.Set;

/** Error codes of the incident context. Each is registered in {@code ErrorCodeRegistry} (error gate). */
public enum IncidentErrorCode implements ErrorCode {

    /** No incident with this id (RIT-US-10). The id is not echoed back. */
    INCIDENT_NOT_FOUND(Set.of()),
    /** The incident exists but the user may not see it (permission table, RIT-US-10). */
    INCIDENT_ACCESS_DENIED(Set.of());

    private final Set<String> requiredParams;

    IncidentErrorCode(Set<String> requiredParams) {
        this.requiredParams = requiredParams;
    }

    @Override
    public String code() {
        return name();
    }

    @Override
    public Set<String> requiredParams() {
        return requiredParams;
    }
}
